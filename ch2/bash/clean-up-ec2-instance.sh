
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/deployment.json"

# Check dependencies
for cmd in aws jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd is required"
    exit 1
  fi
done

if [[ ! -f "$OUTPUT_FILE" ]]; then
  echo "ERROR: deployment.json not found"
  exit 1
fi

# Read deployment information
REGION=$(jq -r '.region' "$OUTPUT_FILE")
ACCOUNT_ID=$(jq -r '.accountId' "$OUTPUT_FILE")
SECURITY_GROUP_ID=$(jq -r '.securityGroupId // empty' "$OUTPUT_FILE")
SECURITY_GROUP_CREATED=$(jq -r '.securityGroupCreated // false' "$OUTPUT_FILE")

export AWS_DEFAULT_REGION="$REGION"

# Verify AWS account
CURRENT_ACCOUNT=$(aws sts get-caller-identity \
  --query 'Account' \
  --output text)

if [[ "$CURRENT_ACCOUNT" != "$ACCOUNT_ID" ]]; then
  echo "ERROR: AWS account mismatch"
  echo "Expected: $ACCOUNT_ID"
  echo "Current:  $CURRENT_ACCOUNT"
  exit 1
fi

# Read instance IDs (compatible with macOS Bash 3.2)
instance_ids=()

while IFS= read -r id; do
  if [[ -n "$id" ]]; then
    instance_ids+=("$id")
  fi
done <<< "$(jq -r '.instanceIds[]' "$OUTPUT_FILE")"

echo "================================="
echo "AWS Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Security Group: $SECURITY_GROUP_ID"
echo "Security Group Created: $SECURITY_GROUP_CREATED"
echo "Instances: ${instance_ids[*]:-none}"
echo "================================="

read -r -p "Terminate these resources? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

# -------------------------------------
# 1. Terminate EC2 instances
# -------------------------------------

if [[ ${#instance_ids[@]} -gt 0 ]]; then
  echo "Checking EC2 instances..."

  active_ids=()

  for id in "${instance_ids[@]}"; do
    state=$(aws ec2 describe-instances \
      --instance-ids "$id" \
      --query 'Reservations[0].Instances[0].State.Name' \
      --output text)

    if [[ "$state" != "terminated" ]]; then
      active_ids+=("$id")
    fi
  done

  if [[ ${#active_ids[@]} -gt 0 ]]; then
    echo "Terminating EC2 instances..."

    aws ec2 terminate-instances \
      --instance-ids "${active_ids[@]}" \
      --output json > /dev/null

    echo "Waiting for termination..."

    aws ec2 wait instance-terminated \
      --instance-ids "${active_ids[@]}"
  fi

  echo "EC2 cleanup completed."
fi

# -------------------------------------
# 2. Delete Security Group if created
# -------------------------------------

if [[ "$SECURITY_GROUP_CREATED" == "true" && -n "$SECURITY_GROUP_ID" ]]; then
  echo "Deleting Security Group..."

  aws ec2 delete-security-group \
    --group-id "$SECURITY_GROUP_ID"

  echo "Security Group deleted."
else
  echo "Skipping Security Group deletion (pre-existing resource)."
fi

# -------------------------------------
# 3. Remove deployment file
# -------------------------------------

rm "$OUTPUT_FILE"

echo ""
echo "Cleanup completed successfully."
