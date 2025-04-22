import argparse
from proxmoxer import ProxmoxAPI
import subprocess

# === Configuration ===
PROXMOX_HOST = "lab-00"
PROXMOX_USER = "root@pam"
PROXMOX_PASS = "TopsfieldPanda1@"
NODE = "lab-00"
STORAGE = "local-zfs"
#wget https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso
ISO_NAME = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
TEMPLATE_ID = 9000
TEMPLATE_NAME = "ubuntu-2404-template"

# === Connect to Proxmox ===
proxmox = ProxmoxAPI(PROXMOX_HOST, user=PROXMOX_USER, password=PROXMOX_PASS, verify_ssl=False)

# === Argument Parsing ===
parser = argparse.ArgumentParser(description="Proxmox VM Manager")
subparsers = parser.add_subparsers(dest="command", required=True)

# Create VM command
create_vm_parser = subparsers.add_parser("create-vm", help="Create a new VM")
create_vm_parser.add_argument("--vmid", type=int, default=TEMPLATE_ID, help="VM ID")
create_vm_parser.add_argument("--name", type=str, default=TEMPLATE_NAME, help="VM Name")
create_vm_parser.add_argument("--memory", type=int, default=2048, help="Memory in MB")
create_vm_parser.add_argument("--cores", type=int, default=2, help="Number of CPU cores")
create_vm_parser.add_argument("--disk-size", type=int, default=20, help="Disk size in GB")

# Convert to template command
convert_template_parser = subparsers.add_parser("convert-template", help="Convert a VM to a template")
convert_template_parser.add_argument("--vmid", type=int, required=True, help="VM ID to convert")

# Remove VM command
remove_vm_parser = subparsers.add_parser("remove-vm", help="Remove a VM")
remove_vm_parser.add_argument("--vmid", type=int, required=True, help="VM ID to remove")
remove_vm_parser.add_argument("--force", action="store_true", help="Force remove even if VM is running")

args = parser.parse_args()

# === Command Execution ===
if args.command == "create-vm":
    try:
        # === Step 1: Create new VM ===
        print(f"Creating base VM {args.name} with ID {args.vmid}...")
        proxmox.nodes(NODE).qemu().create(
            vmid=args.vmid,
            name=args.name,
            memory=args.memory,
            cores=args.cores,
            sockets=1,
            net0="virtio,bridge=vmbr0",
            ide2=f"{ISO_NAME},media=cdrom",
            sata0=f"{STORAGE}:{args.disk_size}",  # Disk size
            ostype="l26",
            scsihw="virtio-scsi-pci",
            boot="cdn",
            bootdisk="sata0"
        )
    except Exception as e:
        print(f"❌ Failed to create VM: {e}")
        exit(1)
    print("✅ VM created!")
    print("🛠️ Install the OS manually from the ISO. Then shut down the VM.")

elif args.command == "convert-template":
    try:
        # === Step 2: Convert VM to template ===
        print(f"Converting VM with ID {args.vmid} to a template...")

        # Check if the VM is stopped
        vm_status = proxmox.nodes(NODE).qemu(args.vmid).status.current.get()
        if vm_status.get("status") != "stopped":
            print(f"❌ VM with ID {args.vmid} is not stopped. Please shut it down before converting.")
            exit(1)

        # Log VM configuration for debugging
        print("🔍 Fetching VM configuration...")
        vm_config = proxmox.nodes(NODE).qemu(args.vmid).config.get()
        print(f"VM Configuration: {vm_config}")

        # Ensure the VM has a valid disk and other required settings
        if "sata0" not in vm_config and "scsi0" not in vm_config:
            print("❌ VM does not have a valid disk attached. Ensure the VM has a disk before converting.")
            exit(1)

        # Detach ISO if attached
        if "ide2" in vm_config and vm_config["ide2"] != "none":
            print("🔧 Detaching ISO from VM...")
            try:
                proxmox.nodes(NODE).qemu(args.vmid).config.post(ide2="none")
                print("✅ ISO detached successfully.")
            except Exception as detach_error:
                print(f"❌ Failed to detach ISO: {detach_error}")
                exit(1)

        # Use SSH to execute qm template
        ssh_command = [
            "ssh",
            f"root@{NODE}",
            f"qm template {args.vmid}"
        ]
        try:
            print(f"🔧 Executing 'qm template' via SSH for VM ID {args.vmid}...")
            subprocess.run(ssh_command, check=True)
            print("✅ VM successfully converted to template!")
        except subprocess.CalledProcessError as ssh_error:
            print(f"❌ Failed to execute 'qm template' via SSH: {ssh_error}")
            exit(1)

    except Exception as e:
        print(f"❌ Failed to convert VM to template: {e}")
        exit(1)

elif args.command == "remove-vm":
    try:
        # === Remove VM ===
        print(f"Removing VM with ID {args.vmid}...")
        
        # Check if the VM exists
        try:
            vm_status = proxmox.nodes(NODE).qemu(args.vmid).status.current.get()
        except Exception:
            print(f"❌ VM with ID {args.vmid} does not exist.")
            exit(1)
            
        # Check if VM is running and not forced
        if vm_status.get("status") == "running" and not args.force:
            print(f"❌ VM with ID {args.vmid} is running. Use --force to remove it anyway.")
            exit(1)
            
        # Stop VM if running and force is specified
        if vm_status.get("status") == "running" and args.force:
            print(f"🛑 Stopping VM with ID {args.vmid} forcefully...")
            try:
                proxmox.nodes(NODE).qemu(args.vmid).status.stop.post()
                print("⏳ Waiting for VM to stop...")
                
                # Wait for VM to stop (simple polling)
                import time
                max_wait = 30  # seconds
                for _ in range(max_wait):
                    current_status = proxmox.nodes(NODE).qemu(args.vmid).status.current.get()
                    if current_status.get("status") == "stopped":
                        print("✅ VM stopped successfully.")
                        break
                    time.sleep(1)
                else:
                    print("⚠️ Timed out waiting for VM to stop, but proceeding with removal...")
            except Exception as stop_error:
                print(f"⚠️ Error stopping VM: {stop_error}, but proceeding with removal...")
        
        # Remove the VM
        try:
            proxmox.nodes(NODE).qemu(args.vmid).delete()
            print(f"✅ VM with ID {args.vmid} successfully removed!")
        except Exception as delete_error:
            print(f"❌ Failed to remove VM: {delete_error}")
            exit(1)
            
    except Exception as e:
        print(f"❌ Failed to remove VM: {e}")
        exit(1)