# To enable SSH logging, run the following on the jump host:
# sudo systemctl restart sshd
# sudo journalctl -fu sshd

# Common SSH troubleshooting steps:
# 1. Verify SSH key permissions: chmod 600 ~/.ssh/id_rsa
# 2. Try verbose connection: ssh -v ubuntu@${var.jump_host_ip}
# 3. Check firewall: sudo iptables -L
# 4. Verify SSH is running: sudo systemctl status sshd
# 5. Try connecting with password (if enabled): ssh ubuntu@${var.jump_host_ip}

# Proxmox SSH status checker script
#!/bin/bash
HOST="${var.jump_host_ip}"
USER="ubuntu"
PASSWORD="tempPassword123"

echo "Testing SSH connectivity to $HOST..."
nc -z -w5 $HOST 22
if [ $? -eq 0 ]; then
  echo "Port 22 is open on $HOST"
else
  echo "Port 22 is NOT open on $HOST - check VM firewall settings"
  exit 1
fi

# Try SSH connection with verbose output
echo "Attempting SSH connection with verbose output..."
ssh -v -o ConnectTimeout=5 -o BatchMode=yes -o PasswordAuthentication=no $USER@$HOST exit 2>&1