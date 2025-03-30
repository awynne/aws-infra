.PHONY: init init-backend plan apply destroy ssh configure clean bootstrap-state migrate-state

# Terraform
init:
	cd terraform && terraform init

init-backend:
	cd terraform && terraform init -reconfigure

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply -auto-approve

destroy:
	cd terraform && terraform destroy -auto-approve

# State management
setup-remote-state:
	@echo "Setting up remote state in S3 with DynamoDB locking..."
	./scripts/setup-remote-state.sh

# Operations
ssh:
	./scripts/ssh-to-jump-host.sh

configure:
	./scripts/run-ansible.sh

# Clean temporary files
clean:
	rm -f /tmp/ansible-key-*.pem /tmp/temp_key
	
help:
	@echo "Available commands:"
	@echo "  make init             - Initialize Terraform"
	@echo "  make init-backend     - Reinitialize Terraform with backend configuration"
	@echo "  make plan             - Plan Terraform changes"
	@echo "  make apply            - Apply Terraform changes"
	@echo "  make destroy          - Destroy Terraform resources"
	@echo "  make setup-remote-state - Set up remote state in S3 with DynamoDB locking"
	@echo "  make ssh              - SSH to the jump host"
	@echo "  make configure        - Configure the jump host with Ansible"
	@echo "  make clean            - Clean up temporary files"