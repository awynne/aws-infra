#!/bin/bash
#
# Creates AWS resources needed for Terraform state management.
# This script creates an S3 bucket and DynamoDB table with unique names
# and updates the backend template with the generated names.

set -e

# Configuration
# Add a unique suffix to avoid name collisions with existing buckets
RANDOM_SUFFIX=$(date +%Y%m%d%H%M%S)
STATE_BUCKET="core-terraform-state-${RANDOM_SUFFIX}"
LOCKS_TABLE="core-terraform-locks-${RANDOM_SUFFIX}"
REGION="us-east-1"

# Function to update backend template with generated names
update_backend_template() {
    local template_file="$PROJECT_ROOT/terraform/backend.tf.tmpl"
    if [ -f "$template_file" ]; then
        echo "Updating backend template with generated resource names..."
        # macOS and Linux handle the sed -i parameter differently, this should work on both
        sed -i.bak "s/bucket[[:space:]]*=[[:space:]]*\"[^\"]*\"/bucket = \"${STATE_BUCKET}\"/" "$template_file"
        sed -i.bak "s/dynamodb_table[[:space:]]*=[[:space:]]*\"[^\"]*\"/dynamodb_table = \"${LOCKS_TABLE}\"/" "$template_file"
        rm -f "${template_file}.bak"
    fi
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if S3 bucket exists
echo "Checking if S3 bucket '$STATE_BUCKET' exists..."
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    echo "S3 bucket '$STATE_BUCKET' already exists."
else
    echo "Creating S3 bucket '$STATE_BUCKET'..."
    # Special handling for us-east-1 which doesn't use LocationConstraint
    if [ "$REGION" == "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$STATE_BUCKET" \
            --region "$REGION"
    else
        aws s3api create-bucket \
            --bucket "$STATE_BUCKET" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    
    # Enable versioning
    echo "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket "$STATE_BUCKET" \
        --versioning-configuration Status=Enabled
    
    # Enable server-side encryption
    echo "Enabling server-side encryption on S3 bucket..."
    aws s3api put-bucket-encryption \
        --bucket "$STATE_BUCKET" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Block public access
    echo "Blocking public access to S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$STATE_BUCKET" \
        --public-access-block-configuration '{
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }'
    
    # Add tags
    echo "Adding tags to S3 bucket..."
    aws s3api put-bucket-tagging \
        --bucket "$STATE_BUCKET" \
        --tagging '{
            "TagSet": [
                {
                    "Key": "Name",
                    "Value": "Terraform State"
                },
                {
                    "Key": "Description",
                    "Value": "Stores terraform state files"
                }
            ]
        }'
    
    echo "S3 bucket '$STATE_BUCKET' created successfully."
fi

# Check if DynamoDB table exists
echo "Checking if DynamoDB table '$LOCKS_TABLE' exists..."
if aws dynamodb describe-table --table-name "$LOCKS_TABLE" 2>/dev/null; then
    echo "DynamoDB table '$LOCKS_TABLE' already exists."
else
    echo "Creating DynamoDB table '$LOCKS_TABLE'..."
    aws dynamodb create-table \
        --table-name "$LOCKS_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --tags '[
            {
                "Key": "Name",
                "Value": "Terraform Locks"
            },
            {
                "Key": "Description",
                "Value": "DynamoDB table for Terraform state locking"
            }
        ]'
    
    echo "DynamoDB table '$LOCKS_TABLE' created successfully."
fi

# Update backend template with the generated names
# Determine the project root directory if not already set
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
update_backend_template

# Record the resource names to a state file for delete operations
echo "STATE_BUCKET=$STATE_BUCKET" > "$PROJECT_ROOT/.tfstate_resources"
echo "LOCKS_TABLE=$LOCKS_TABLE" >> "$PROJECT_ROOT/.tfstate_resources"
echo "REGION=$REGION" >> "$PROJECT_ROOT/.tfstate_resources"

echo "Remote state resources have been set up successfully."
echo "S3 Bucket: $STATE_BUCKET"
echo "DynamoDB Table: $LOCKS_TABLE"
echo ""
echo "The backend.tf.tmpl has been updated with these names."
echo "Resource information saved to .tfstate_resources for deletion reference."
echo "Run 'make setup-backend' to configure Terraform to use these resources."