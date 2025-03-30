.PHONY: init plan apply destroy ssh configure clean

# Terraform
init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply -auto-approve

destroy:
	cd terraform && terraform destroy -auto-approve

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
	@echo "  make init       - Initialize Terraform"
	@echo "  make plan       - Plan Terraform changes"
	@echo "  make apply      - Apply Terraform changes"
	@echo "  make destroy    - Destroy Terraform resources"
	@echo "  make ssh        - SSH to the jump host"
	@echo "  make configure  - Configure the jump host with Ansible"
	@echo "  make clean      - Clean up temporary files"