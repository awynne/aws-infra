#!/bin/bash

set -e

# Determine the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Step 1: Initializing Terraform without backend..."
cd "$PROJECT_ROOT/terraform"
rm -f backend.tf
terraform init

echo "Step 2: Creating S3 bucket and DynamoDB table for state management..."
terraform apply -target=aws_s3_bucket.terraform_state \
               -target=aws_s3_bucket_versioning.terraform_state_versioning \
               -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state_encryption \
               -target=aws_s3_bucket_public_access_block.terraform_state_public_access \
               -target=aws_dynamodb_table.terraform_locks \
               -auto-approve

echo "Step 3: Enabling S3 backend configuration..."
cp backend.tf.tmpl backend.tf

echo "Step 4: Migrating state to S3 backend..."
terraform init -force-copy

echo "Remote state setup complete. Your state is now stored in S3 with DynamoDB locking."