.PHONY: plan apply destroy-infra create-state-resources delete-state-resources setup-backend ssh configure clean clean-state create-vm convert-template remove-vm

# Terraform operations

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply -auto-approve

destroy-infra:
	cd terraform && terraform destroy -auto-approve || \
	(echo "Trying to destroy without state lock..." && \
	cd terraform && terraform destroy -auto-approve -lock=false || \
	(echo "Falling back to local state destroy method..." && \
	./scripts/local-state-destroy.sh))

# State management
create-state-resources:
	@echo "Creating S3 bucket and DynamoDB table for remote state..."
	./scripts/create-state-resources.sh

delete-state-resources:
	@echo "Deleting S3 bucket and DynamoDB table for remote state..."
	./scripts/delete-state-resources.sh

setup-backend:
	@echo "Setting up Terraform backend to use existing remote state..."
	./scripts/setup-backend.sh

clean-state-local:
	rm -f terraform/terraform.tfstate terraform/terraform.tfstate.backup
	rm -f terraform/.terraform/terraform.tfstate

# Proxmox VM management
create-vm:
	@echo "Creating a new VM in Proxmox..."
	cd python && python3 create-proxmox-template.py create-vm

create-vm-custom:
	@echo "Creating a new VM in Proxmox with custom parameters..."
	@read -p "VM ID [9000]: " vmid; \
	read -p "VM Name [ubuntu-2404-template]: " name; \
	read -p "Memory (MB) [2048]: " memory; \
	read -p "CPU Cores [2]: " cores; \
	read -p "Disk Size (GB) [20]: " disk; \
	cd python && python3 create-proxmox-template.py create-vm \
		$${vmid:+--vmid $${vmid}} \
		$${name:+--name $${name}} \
		$${memory:+--memory $${memory}} \
		$${cores:+--cores $${cores}} \
		$${disk:+--disk-size $${disk}}

convert-template:
	@echo "Converting VM to template..."
	@read -p "VM ID to convert: " vmid; \
	cd python && python3 create-proxmox-template.py convert-template --vmid $$vmid

remove-vm:
	@echo "Removing VM..."
	@read -p "VM ID to remove: " vmid; \
	read -p "Force removal (y/n) [n]: " force; \
	force_flag=""; \
	if [ "$$force" = "y" ]; then force_flag="--force"; fi; \
	cd python && python3 create-proxmox-template.py remove-vm --vmid $$vmid $$force_flag
	
help:
	@echo "Available commands:"
	@echo ""
	@echo "Initial Setup:"
	@echo "  make create-state-resources - Create S3 bucket and DynamoDB table for remote state"
	@echo "  make setup-backend    - Configure Terraform to use existing remote state resources"
	@echo ""
	@echo "Proxmox VM Management:"
	@echo "  make create-vm        - Create a new VM from template with default parameters"
	@echo "  make create-vm-custom - Create a new VM from template with custom parameters"
	@echo "  make convert-template - Convert a VM to a template (prompts for VM ID)"
	@echo "  make remove-vm        - Remove a VM (prompts for VM ID and force option)"
	@echo ""
	@echo "Infrastructure Management:"
	@echo "  make plan             - Plan Terraform changes"
	@echo "  make apply            - Apply Terraform changes"
	@echo "  make destroy-infra    - Destroy all infrastructure resources managed by Terraform"
	@echo ""
	@echo "Cleanup:"
	@echo "  make delete-state-resources - Delete S3 bucket and DynamoDB table for remote state"
	@echo "  make clean            - Clean up temporary files"
	@echo "  make clean-state-local      - Remove local Terraform state files"
