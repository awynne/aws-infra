#!/bin/bash
#
# Deletes the AWS resources used for Terraform state management.
# This script finds and removes the S3 bucket and DynamoDB table
# used for Terraform remote state storage.

set -e

# Determine project root directory and state file location
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.tfstate_resources"

# Function to load configuration from .tfstate_resources file
load_from_state_file() {
    if [ -f "$STATE_FILE" ]; then
        echo "Loading resource information from .tfstate_resources file..."
        source "$STATE_FILE"
        return 0
    fi
    return 1
}

# Function to extract configuration from backend.tf.tmpl
extract_from_template() {
    TEMPLATE_FILE="$PROJECT_ROOT/terraform/backend.tf.tmpl"
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "Error: Backend template file not found at $TEMPLATE_FILE"
        return 1
    fi

    STATE_BUCKET=$(grep -o 'bucket[[:space:]]*=[[:space:]]*"[^"]*"' "$TEMPLATE_FILE" | cut -d'"' -f2)
    LOCKS_TABLE=$(grep -o 'dynamodb_table[[:space:]]*=[[:space:]]*"[^"]*"' "$TEMPLATE_FILE" | cut -d'"' -f2)
    REGION=$(grep -o 'region[[:space:]]*=[[:space:]]*"[^"]*"' "$TEMPLATE_FILE" | cut -d'"' -f2)
    
    return 0
}

# Function to list all state resources to destroy
list_known_resources() {
    echo "Listing all known terraform state resources in AWS..."
    echo "S3 buckets matching 'core-terraform-state':"
    aws s3api list-buckets --query "Buckets[?contains(Name, 'core-terraform-state')].Name" --output table
    
    echo "DynamoDB tables matching 'core-terraform-locks':"
    aws dynamodb list-tables | grep -o '"core-terraform-locks[^"]*"' | tr -d '"' | sort
}

# Try to load configuration from state file or template
if ! load_from_state_file && ! extract_from_template; then
    echo "Warning: Could not determine resource names from either .tfstate_resources or backend.tf.tmpl"
    echo "Listing all known resources..."
    list_known_resources
    echo "Please specify the resource names to delete or use AWS Console to clean up resources."
    exit 1
fi

echo "Found configuration:"
echo "S3 Bucket: $STATE_BUCKET"
echo "DynamoDB Table: $LOCKS_TABLE"
echo "Region: $REGION"

# Function to confirm deletion
confirm_deletion() {
    echo -e "\nWARNING: You are about to delete Terraform state resources."
    echo "This action is IRREVERSIBLE and may cause loss of state if you have existing Terraform deployments."
    echo -e "S3 Bucket: $STATE_BUCKET\nDynamoDB Table: $LOCKS_TABLE\n"
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        exit 0
    fi
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Skip confirmation for automated testing
# confirm_deletion

# Set confirmation to "yes" automatically
confirm="yes"

# Empty S3 bucket first (required before deletion)
echo "Checking if S3 bucket '$STATE_BUCKET' exists..."
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    echo "Emptying S3 bucket '$STATE_BUCKET'..."
    aws s3 rm "s3://$STATE_BUCKET" --recursive
    
    # Delete all object versions for buckets with versioning enabled
    echo "Removing all object versions from bucket..."
    # List all versions and delete them
    VERSIONS=$(aws s3api list-object-versions --bucket "$STATE_BUCKET" \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)
    if [[ $VERSIONS != *"null"* && $VERSIONS != "{}" ]]; then
        echo "$VERSIONS" | jq '.Objects' > /tmp/versions.json
        if [[ -s /tmp/versions.json && $(cat /tmp/versions.json) != "null" ]]; then
            aws s3api delete-objects --bucket "$STATE_BUCKET" \
                --delete "$(echo "$VERSIONS" | jq '{Objects: .Objects}')"
            echo "  Deleted object versions"
        fi
    fi
    
    # Delete all delete markers
    DELETE_MARKERS=$(aws s3api list-object-versions --bucket "$STATE_BUCKET" \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)
    if [[ $DELETE_MARKERS != *"null"* && $DELETE_MARKERS != "{}" ]]; then
        echo "$DELETE_MARKERS" | jq '.Objects' > /tmp/delete-markers.json
        if [[ -s /tmp/delete-markers.json && $(cat /tmp/delete-markers.json) != "null" ]]; then
            aws s3api delete-objects --bucket "$STATE_BUCKET" \
                --delete "$(echo "$DELETE_MARKERS" | jq '{Objects: .Objects}')"
            echo "  Deleted delete markers"
        fi
    fi
    
    echo "Deleting S3 bucket '$STATE_BUCKET'..."
    aws s3api delete-bucket --bucket "$STATE_BUCKET" --region "$REGION"
    echo "S3 bucket deleted successfully."
else
    echo "S3 bucket '$STATE_BUCKET' does not exist or you don't have access to it."
fi

# Delete DynamoDB table
echo "Checking if DynamoDB table '$LOCKS_TABLE' exists..."
if aws dynamodb describe-table --table-name "$LOCKS_TABLE" --region "$REGION" 2>/dev/null; then
    echo "Deleting DynamoDB table '$LOCKS_TABLE'..."
    aws dynamodb delete-table --table-name "$LOCKS_TABLE" --region "$REGION"
    echo "DynamoDB table deleted successfully."
else
    echo "DynamoDB table '$LOCKS_TABLE' does not exist or you don't have access to it."
fi

echo "Remote state resources have been deleted."

# Remove state tracking file if it exists
if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    echo "Removed state tracking file."
fi

echo ""
echo "Remaining resources in AWS:"
list_known_resources