.PHONY: create-jump-vm destroy-jump-vm

create-jump-vm:
	@echo "Creating VM jump-00 via Ansible..."
	ansible-playbook -i inventory.ini site.yml -u root -e "hostname=jump-00"

destroy-jump-vm:
	@echo "Destroying VM jump-00 via Ansible..."
	ansible-playbook -i inventory.ini site.yml -u root -e "vm_state=absent hostname=jump-00"