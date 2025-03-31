# CLAUDE.md - Claude Code Assistant Notes

This file contains notes and reminders for Claude Code Assistant when working with this project.

## Project Structure

This is an AWS infrastructure project using Terraform and Ansible:
- `terraform/`: Contains all Terraform configurations
- `ansible/`: Contains Ansible configuration for the jump host
- `scripts/`: Contains utility scripts for operations
- `config/`: Contains configuration files (future use)

## Common Commands

When working with this project, run the following commands:

```bash
# INITIAL SETUP
# Create the state storage resources
make create-state-resources

# Configure Terraform to use the remote state
make setup-backend

# INFRASTRUCTURE MANAGEMENT
# Plan Terraform changes
make plan

# Apply Terraform changes
make apply

# Destroy infrastructure (preserves state resources)
make destroy-infra

# JUMP HOST OPERATIONS
# Configure the jump host with Ansible
make configure

# SSH to the jump host
make ssh

# CLEANUP
# Remove state resources when completely done with project
make delete-state-resources
```

## Terraform Remote State

The project uses Terraform with remote state management in S3 and state locking with DynamoDB:

- S3 bucket: `core-terraform-state`
- DynamoDB table: `core-terraform-locks`
- State path: `terraform/infra.tfstate`

If the remote state needs to be set up from scratch:
```bash
make create-state-resources
make setup-backend
```

## Security Practices

- SSH keys are stored in AWS Secrets Manager
- Terraform state is stored in an encrypted S3 bucket with versioning
- State locking is implemented using DynamoDB
- Jump host security is maintained via security groups
- IAM roles follow principle of least privilege

## Infrastructure Details

- Region: us-east-1
- VPC CIDR: 10.0.0.0/16
- Subnet CIDR: 10.0.1.0/24
- AMI: Ubuntu 22.04 LTS (ami-0655cec52acf2717b)
- Instance type: t2.micro

## Common Tasks

### Adding New Resources
When adding new AWS resources:
1. Add the resource definition to `terraform/main.tf`
2. Run `make plan` to verify changes
3. Run `make apply` to apply changes

### Updating Jump Host Configuration
When updating the jump host configuration:
1. Modify `ansible/playbooks/playbook.yml`
2. Run `make configure` to apply changes

### Accessing the Jump Host
To connect to the jump host:
```bash
make ssh
```

### Updating Remote State Configuration
If the S3 backend configuration needs updating:
1. Modify `terraform/backend.tf`
2. Run `terraform init -reconfigure`