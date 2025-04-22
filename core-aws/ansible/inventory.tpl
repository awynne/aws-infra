[jump_host]
${jump_host_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# SSH KEY INSTRUCTIONS:
# The SSH key is stored in AWS Secrets Manager
# To retrieve and use the key:
# 1. Run: aws secretsmanager get-secret-value --secret-id ${secret_name} --query SecretString --output text > temp-key.pem && chmod 400 temp-key.pem
# 2. Use the key with: ssh -i temp-key.pem ubuntu@${jump_host_ip}
# 3. For Ansible: ansible-playbook -i inventory playbook.yml --private-key=temp-key.pem
# 4. Delete the key after use: rm temp-key.pem