# Terraform EC2 Project

This project manages AWS EC2 instances (jump hosts) using Terraform and Ansible.

## Directory Structure

```
terraform-ec2/
├── terraform/           # Terraform configuration files
│   ├── main.tf          # Main Terraform configuration
│   ├── variables.tf     # Variable definitions
│   ├── outputs.tf       # Output definitions
│   ├── terraform.tfvars # Variable values
│   └── modules/         # Terraform modules
│       └── jump_host/   # Jump host module (future use)
├── ansible/             # Ansible configuration
│   ├── inventory        # Inventory file (auto-generated)
│   ├── inventory.tpl    # Template for inventory file
│   └── playbooks/       # Ansible playbooks
│       └── playbook.yml # Main configuration playbook
├── scripts/             # Utility scripts
│   ├── ssh-to-jump-host.sh # Script to SSH to the jump host
│   └── run-ansible.sh   # Script to run Ansible playbooks
└── config/              # Configuration files (future use)
```

## Usage

### Terraform

The project uses Terraform with remote state management in AWS S3 and state locking with DynamoDB.

#### Setting up Remote State (first time only)

```bash
# Set up remote state in S3 with DynamoDB locking (single command)
make setup-remote-state
```

#### Normal Terraform Operations

```bash
# Initialize Terraform
make init

# Plan changes
make plan

# Apply changes
make apply
```

### SSH Access

To SSH to the jump host:

```bash
./scripts/ssh-to-jump-host.sh
```

### Ansible Configuration

To configure the jump host with Ansible:

```bash
./scripts/run-ansible.sh
```

## Security

- SSH keys are stored in AWS Secrets Manager
- Temporary keys are stored in /tmp and automatically removed
- All jump host configuration is managed through code
- Terraform state is stored in an encrypted S3 bucket with versioning enabled
- State locking is implemented using DynamoDB to prevent concurrent modifications
- S3 bucket has public access blocked and server-side encryption enabled