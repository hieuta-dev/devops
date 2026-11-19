
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==========================================
# 1. SHARED CONFIGURATION
# ==========================================

# Project
PROJECT_NAME="test-script-app"
ENVIRONMENT="production"

# AWS
AWS_REGION="ap-southeast-2"
EC2_INSTANCE_TYPE="t3.micro"

# AMI
read -r -p "Enter AMI version [v1.2.0]: " AMI_VERSION
AMI_VERSION="${AMI_VERSION:-v1.2.0}"
AMI_NAME="${PROJECT_NAME}-${AMI_VERSION}"

# Application
APP_HTTP_PORT=8080
APP_HEALTH_CHECK_PATH="/health"

# Auto Scaling Group
ASG_MIN_SIZE=3
ASG_MAX_SIZE=10

# Instance Refresh
MIN_HEALTHY_PERCENTAGE=100
MAX_HEALTHY_PERCENTAGE=200
AUTO_ROLLBACK=true

# ==========================================
# 2. PACKER VARIABLES
# ==========================================

export PKR_VAR_project_name="$PROJECT_NAME"
export PKR_VAR_ami_version="$AMI_VERSION"
export PKR_VAR_environment="$ENVIRONMENT"
export PKR_VAR_aws_region="$AWS_REGION"
export PKR_VAR_ec2_instance_type="$EC2_INSTANCE_TYPE"

export PKR_VAR_ami_tags="$(cat <<EOF
{
  "Project": "$PROJECT_NAME",
  "Environment": "$ENVIRONMENT",
  "Version": "$AMI_VERSION"
}
EOF
)"

# ==========================================
# 3. OPENTOFU VARIABLES
# ==========================================

export TF_VAR_project_name="$PROJECT_NAME"
export TF_VAR_aws_region="$AWS_REGION"
export TF_VAR_ec2_instance_type="$EC2_INSTANCE_TYPE"

# Matches the AMI name created by Packer
export TF_VAR_ami_name="$AMI_NAME"

# Application
export TF_VAR_app_http_port="$APP_HTTP_PORT"
export TF_VAR_app_health_check_path="$APP_HEALTH_CHECK_PATH"

# ASG
export TF_VAR_asg_min_size="$ASG_MIN_SIZE"
export TF_VAR_asg_max_size="$ASG_MAX_SIZE"

# Instance Refresh
export TF_VAR_min_healthy_percentage="$MIN_HEALTHY_PERCENTAGE"
export TF_VAR_max_healthy_percentage="$MAX_HEALTHY_PERCENTAGE"
export TF_VAR_auto_rollback="$AUTO_ROLLBACK"

# ==========================================
# 4. DISPLAY CONFIGURATION
# ==========================================

echo "======================================"
echo "Deployment Configuration"
echo "======================================"
echo "Project       : $PROJECT_NAME"
echo "Environment   : $ENVIRONMENT"
echo "AWS Region    : $AWS_REGION"
echo "Instance Type : $EC2_INSTANCE_TYPE"
echo "AMI Version   : $AMI_VERSION"
echo "AMI Pattern   : ${AMI_NAME}-*"
echo "App Port      : $APP_HTTP_PORT"
echo "ASG Min/Max   : $ASG_MIN_SIZE / $ASG_MAX_SIZE"
echo "======================================"

# ==========================================
# 5. BUILD AMI WITH PACKER
# ==========================================

echo "Building AMI with Packer..."

(
  cd "$ROOT_DIR/packer"

  packer init .
  packer validate .
  packer build .
)

echo "Packer build completed."

echo "Deploying infrastructure with OpenTofu..."

(
  cd "$ROOT_DIR/tofu/lives/asg-sample"

  tofu init
  tofu validate
  tofu plan -out=tfplan
  tofu apply tfplan
)

echo "Deployment completed."
