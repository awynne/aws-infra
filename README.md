# Infrastructure & Applications

This repository contains infrastructure-as-code and application deployment manifests for both local (Proxmox) and cloud (AWS) environments.

## Architecture

The repository follows a layered architecture reflecting the directory structure:

### Core Layer (`/core`)
Base infrastructure components:
- VM creation and management in Proxmox (local)
- Infrastructure provisioning in AWS (cloud)
- State management for Terraform
- Ansible playbooks for configuration

### Cluster Layer (Planned)
Kubernetes cluster provisioning and management:
- Local clusters in Proxmox
- Cloud clusters in AWS
- Cluster management tools

### Application Layer (Planned)
Application deployment artifacts:
- Kubernetes manifests
- Helm charts
- Application configuration

## Getting Started

### Prerequisites
- Terraform
- Ansible
- Python 3.x with pipenv
- AWS CLI (for cloud resources)
- Access to Proxmox (for local resources)

### Initial Setup
```bash
# Set up state management for Terraform
cd core
make create-state-resources
make setup-backend
```

## VM Management (Proxmox)

```bash
# Create a VM with default settings
make create-vm

# Create a VM with custom settings
make create-vm-custom

# Convert a VM to a template
make convert-template

# Remove a VM
make remove-vm
```

## Infrastructure Management (AWS)

```bash
# Plan infrastructure changes
make plan

# Apply infrastructure changes
make apply

# Destroy infrastructure
make destroy-infra
```

## Help

For a complete list of available commands:
```bash
make help
```