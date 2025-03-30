output "jump_host_public_ip" {
  value = aws_instance.jump_host.public_ip
  description = "The public IP of the jump host"
}

output "jump_host_key_secret_name" {
  value = aws_secretsmanager_secret.jump_host_key.id
  description = "The id of the AWS Secrets Manager secret containing the jump host private key"
}

output "secrets_manager_retrieve_command" {
  value = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.jump_host_key.id} --query SecretString --output text > temp-key.pem && chmod 400 temp-key.pem"
  description = "Command to retrieve the private key from AWS Secrets Manager (key will be saved as temp-key.pem)"
}

output "ssh_command_direct" {
  value = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.jump_host_key.id} --query SecretString --output text > /tmp/temp_key && chmod 600 /tmp/temp_key && ssh -i /tmp/temp_key ubuntu@${aws_instance.jump_host.public_ip} && rm -f /tmp/temp_key"
  description = "Secure one-liner to SSH with proper key permissions and automatic cleanup"
}
