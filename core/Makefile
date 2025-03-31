.PHONY: plan apply destroy-infra create-state-resources delete-state-resources setup-backend ssh configure clean clean-state

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

# Operations
ssh:
	./scripts/ssh-to-jump-host.sh

configure:
	./scripts/run-ansible.sh

# Clean temporary files
clean:
	rm -f /tmp/ansible-key-*.pem /tmp/temp_key

clean-state:
	rm -f terraform/terraform.tfstate terraform/terraform.tfstate.backup
	rm -f terraform/.terraform/terraform.tfstate
	
help:
	@echo "Available commands:"
	@echo ""
	@echo "Initial Setup:"
	@echo "  make create-state-resources - Create S3 bucket and DynamoDB table for remote state"
	@echo "  make setup-backend    - Configure Terraform to use existing remote state resources"
	@echo ""
	@echo "Infrastructure Management:"
	@echo "  make plan             - Plan Terraform changes"
	@echo "  make apply            - Apply Terraform changes"
	@echo "  make destroy-infra    - Destroy all infrastructure resources managed by Terraform"
	@echo ""
	@echo "Jump Host Operations:"
	@echo "  make ssh              - SSH to the jump host"
	@echo "  make configure        - Configure the jump host with Ansible"
	@echo ""
	@echo "Cleanup:"
	@echo "  make delete-state-resources - Delete S3 bucket and DynamoDB table for remote state"
	@echo "  make clean            - Clean up temporary files"
	@echo "  make clean-state      - Remove local Terraform state files"