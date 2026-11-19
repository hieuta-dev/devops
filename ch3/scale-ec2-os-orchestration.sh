
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOFU_DIR="$ROOT_DIR/tofu/lives/asg-sample"

# Configuration
DEFAULT_CAPACITY=3
ASG_MAX_SIZE=10

# Get desired number of EC2 instances
read -r -p "Enter desired EC2 instances [$DEFAULT_CAPACITY]: " INSTANCE_COUNT

INSTANCE_COUNT="${INSTANCE_COUNT:-$DEFAULT_CAPACITY}"

# Validate input
if ! [[ "$INSTANCE_COUNT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Instance count must be a non-negative integer."
  exit 1
fi

if (( INSTANCE_COUNT > ASG_MAX_SIZE )); then
  echo "ERROR: Instance count cannot exceed ASG max size ($ASG_MAX_SIZE)."
  exit 1
fi

# Export OpenTofu variables
export TF_VAR_asg_desired_capacity="$INSTANCE_COUNT"
export TF_VAR_asg_min_size="$INSTANCE_COUNT"
export TF_VAR_asg_max_size="$ASG_MAX_SIZE"

echo "======================================"
echo "AWS Auto Scaling Group"
echo "======================================"
echo "Desired Capacity : $INSTANCE_COUNT"
echo "Minimum Capacity : $INSTANCE_COUNT"
echo "Maximum Capacity : $ASG_MAX_SIZE"
echo "======================================"

# Apply infrastructure changes
(
  cd "$TOFU_DIR"

  tofu init
  tofu validate
  tofu plan -out=tfplan
  tofu apply tfplan
)

echo "ASG scaling completed."
