#!/bin/bash
#
# Configures Terraform to use S3 backend for state management.
# This script reads the bucket and DynamoDB table information from
# the backend template and initializes Terraform with this configuration.

set -e

# Configuration will be read from the backend.tf.tmpl file
# Extract bucket and dynamodb table from backend.tf.tmpl
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$PROJECT_ROOT/terraform/backend.tf.tmpl"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Backend template file not found at $TEMPLATE_FILE"
    exit 1
fi

STATE_BUCKET=$(grep -o 'bucket[[:space:]]*=[[:space:]]*"[^"]*"' "$TEMPLATE_FILE" | cut -d'"' -f2)
LOCKS_TABLE=$(grep -o 'dynamodb_table[[:space:]]*=[[:space:]]*"[^"]*"' "$TEMPLATE_FILE" | cut -d'"' -f2)
REGION=$(grep -o 'region[[:space:]]*=[[:space:]]*"[^"]*"' "$TEMPLATE_FILE" | cut -d'"' -f2)

echo "Found configuration in backend template:"
echo "S3 Bucket: $STATE_BUCKET"
echo "DynamoDB Table: $LOCKS_TABLE"
echo "Region: $REGION"

# Determine the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if the S3 bucket and DynamoDB table exist
echo "Verifying required resources exist..."

# Check S3 bucket
if ! aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    echo "Error: S3 bucket '$STATE_BUCKET' does not exist or you don't have access to it."
    echo "Run 'make create-state-resources' first to create the required resources."
    exit 1
fi

# Check DynamoDB table
if ! aws dynamodb describe-table --table-name "$LOCKS_TABLE" --region "$REGION" 2>/dev/null; then
    echo "Error: DynamoDB table '$LOCKS_TABLE' does not exist or you don't have access to it."
    echo "Run 'make create-state-resources' first to create the required resources."
    exit 1
fi

# Step 1: Copy the backend template to backend.tf
echo "Setting up Terraform backend configuration..."
cd "$PROJECT_ROOT/terraform"
cp backend.tf.tmpl backend.tf

# Step 2: Initialize Terraform with the new backend
echo "Initializing Terraform with the S3 backend..."
terraform init -reconfigure

echo "Backend setup complete. Terraform is now configured to use:"
echo "S3 Bucket: $STATE_BUCKET"
echo "DynamoDB Table: $LOCKS_TABLE"