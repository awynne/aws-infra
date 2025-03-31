#!/bin/bash

set -e

# Determine the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/terraform"

# Move backend.tf to backend.tf.bak if it exists
if [ -f backend.tf ]; then
  mv backend.tf backend.tf.bak
fi

# Create a local backend file
cat > backend.tf << EOF
terraform {
  backend "local" {}
}
EOF

# Reconfigure Terraform to use local backend
echo "Reconfiguring Terraform to use local backend..."
terraform init -reconfigure -force-copy

# Run destroy command
echo "Running terraform destroy..."
terraform destroy -auto-approve

# Optional: Restore the original backend file if it was backed up
if [ -f backend.tf.bak ]; then
  mv backend.tf.bak backend.tf
  echo "Original backend configuration restored."
fi

echo "Destroy operation completed."