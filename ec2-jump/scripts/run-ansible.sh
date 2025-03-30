#!/bin/bash

# Determine the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Extract the secret name from the inventory file
SECRET_NAME=$(grep "secret-id" "$PROJECT_ROOT/ansible/inventory" | awk -F '--secret-id ' '{print $2}' | awk '{print $1}')

# Create temporary key file in /tmp with a unique name using process ID
TEMP_KEY_FILE="/tmp/ansible-key-$$.pem"

echo "Retrieving SSH key from AWS Secrets Manager (Secret: $SECRET_NAME)..."
aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text > "$TEMP_KEY_FILE"
chmod 400 "$TEMP_KEY_FILE"

echo "Running Ansible playbook..."
ansible-playbook -i "$PROJECT_ROOT/ansible/inventory" "$PROJECT_ROOT/ansible/playbooks/playbook.yml" --private-key="$TEMP_KEY_FILE"
ANSIBLE_EXIT_CODE=$?

echo "Removing temporary key file..."
rm -f "$TEMP_KEY_FILE"

echo "Playbook execution complete with exit code: $ANSIBLE_EXIT_CODE"
exit $ANSIBLE_EXIT_CODE