
#!/usr/bin/env bash

set -euo pipefail

export AWS_DEFAULT_REGION="ap-southeast-2"

INSTANCE_COUNT=3
INSTANCE_TYPE="t3.micro"
INSTANCE_NAME="sample-app"
SG_NAME="sample-app"
VPC_ID="vpc-0006dbe397f0951b5"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/deployment.json"
USER_DATA_FILE="$SCRIPT_DIR/user-data.sh"

# Check dependencies
for cmd in aws jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd is required"
    exit 1
  fi
done

if [[ ! -f "$USER_DATA_FILE" ]]; then
  echo "ERROR: user-data.sh not found"
  exit 1
fi

# Prevent overwriting tracked resources
if [[ -e "$OUTPUT_FILE" ]]; then
  echo "ERROR: deployment.json already exists."
  echo "Run cleanup before deploying again."
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account --output text)

security_group_id=""
security_group_created=false
image_id=""
instance_ids_json='[]'

# Save deployment state
save_state() {
  local tmp_file
  tmp_file=$(mktemp "$SCRIPT_DIR/.deployment.XXXXXX")

  jq -n \
    --arg account "$ACCOUNT_ID" \
    --arg region "$AWS_DEFAULT_REGION" \
    --arg vpc "$VPC_ID" \
    --arg sg "$security_group_id" \
    --argjson sgCreated "$security_group_created" \
    --arg ami "$image_id" \
    --arg type "$INSTANCE_TYPE" \
    --argjson count "$INSTANCE_COUNT" \
    --argjson ids "$instance_ids_json" \
    '{
      accountId: $account,
      region: $region,
      vpcId: $vpc,
      securityGroupId: $sg,
      securityGroupCreated: $sgCreated,
      amiId: $ami,
      instanceType: $type,
      requestedCount: $count,
      instanceIds: $ids
    }' > "$tmp_file"

  mv "$tmp_file" "$OUTPUT_FILE"
}

echo "AWS Account: $ACCOUNT_ID"
echo "Region: $AWS_DEFAULT_REGION"
echo "VPC: $VPC_ID"

# -------------------------------------
# 1. Find or create Security Group
# -------------------------------------

echo "Checking Security Group..."

security_group_id=$(aws ec2 describe-security-groups \
  --filters \
    "Name=group-name,Values=$SG_NAME" \
    "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

if [[ -z "$security_group_id" || "$security_group_id" == "None" ]]; then
  echo "Creating Security Group..."

  security_group_id=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Allow HTTP traffic into sample app" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

  security_group_created=true
else
  echo "Reusing Security Group: $security_group_id"
fi

save_state

# -------------------------------------
# 2. Configure Security Group rules
# -------------------------------------

# Check whether HTTP 80 is already allowed
http_exists=$(aws ec2 describe-security-groups \
  --group-ids "$security_group_id" \
  --output json | jq -r '
    [.SecurityGroups[0].IpPermissions[]?
     | select(
         .IpProtocol == "tcp"
         and .FromPort <= 80
         and .ToPort >= 80
       )
     | .IpRanges[]?
     | select(.CidrIp == "0.0.0.0/0")
    ] | length > 0
  ')

if [[ "$http_exists" == "false" ]]; then
  echo "Allowing HTTP port 80..."

  aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0" > /dev/null
fi

# Allow internal TCP 8080 between instances
internal_exists=$(aws ec2 describe-security-groups \
  --group-ids "$security_group_id" \
  --output json | jq -r --arg sg "$security_group_id" '
    [.SecurityGroups[0].IpPermissions[]?
     | select(
         .IpProtocol == "tcp"
         and .FromPort <= 8080
         and .ToPort >= 8080
       )
     | .UserIdGroupPairs[]?
     | select(.GroupId == $sg)
    ] | length > 0
  ')

if [[ "$internal_exists" == "false" ]]; then
  echo "Allowing internal TCP port 8080..."

  aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol tcp \
    --port 8080 \
    --source-group "$security_group_id" > /dev/null
fi

# -------------------------------------
# 3. Find Amazon Linux 2023 AMI
# -------------------------------------

echo "Finding latest Amazon Linux 2023 AMI..."

image_id=$(aws ec2 describe-images \
  --owners amazon \
  --filters \
    'Name=name,Values=al2023-ami-2023.*-x86_64' \
    'Name=state,Values=available' \
  --query 'reverse(sort_by(Images, &CreationDate))[0].ImageId' \
  --output text)

if [[ -z "$image_id" || "$image_id" == "None" ]]; then
  echo "ERROR: No AMI found"
  exit 1
fi

save_state

echo "AMI: $image_id"

# -------------------------------------
# 4. Launch EC2 instances
# -------------------------------------

echo "Launching $INSTANCE_COUNT EC2 instances..."

run_response=$(aws ec2 run-instances \
  --image-id "$image_id" \
  --instance-type "$INSTANCE_TYPE" \
  --count "$INSTANCE_COUNT" \
  --security-group-ids "$security_group_id" \
  --user-data "file://$USER_DATA_FILE" \
  --tag-specifications \
    "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --output json)

instance_ids_json=$(jq -c \
  '[.Instances[].InstanceId]' <<< "$run_response")

save_state

instance_ids=()
while IFS= read -r id; do
  instance_ids+=("$id")
done < <(jq -r '.[]' <<< "$instance_ids_json")

echo "Waiting for EC2 instances..."

aws ec2 wait instance-running \
  --instance-ids "${instance_ids[@]}"

# -------------------------------------
# 5. Retrieve instance information
# -------------------------------------

instances_json=$(aws ec2 describe-instances \
  --instance-ids "${instance_ids[@]}" \
  --query 'Reservations[].Instances[].{
    InstanceId:InstanceId,
    PrivateIP:PrivateIpAddress,
    PublicIP:PublicIpAddress,
    State:State.Name
  }' \
  --output json)

tmp_file=$(mktemp "$SCRIPT_DIR/.deployment.XXXXXX")

jq --argjson instances "$instances_json" \
  '. + {instances: $instances}' \
  "$OUTPUT_FILE" > "$tmp_file"

mv "$tmp_file" "$OUTPUT_FILE"

echo ""
echo "Deployment completed."
echo "Saved to: $OUTPUT_FILE"

jq . "$OUTPUT_FILE"
