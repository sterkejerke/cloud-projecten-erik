#!/bin/bash
# create-wordpress-vm.sh
# Creates a WordPress VM on Proxmox with HA, Ceph storage, and firewall
# Usage: ./create-wordpress-vm.sh [vmid] [hostname] [ip]
# Example: ./create-wordpress-vm.sh 200 wordpress-vm-client2 10.24.52.200

set -e

# --- Configuration ---
VMID=${1:-200}
HOSTNAME=${2:-wordpress-vm-client2}
IP=${3:-10.24.52.200}
GATEWAY=10.24.52.1
NETMASK=24
STORAGE=cephpool
BRIDGE=vmbr1
VLAN=2452
DISK_SIZE=30
MEMORY=1024
CORES=1
NET_LIMIT=51200  # 50MB/s in KB/s
OS_TEMPLATE="local:iso/debian-12-generic-amd64.qcow2"
SSH_USER="wpuser"

echo "=== Creating WordPress VM ==="
echo "VMID:     $VMID"
echo "Hostname: $HOSTNAME"
echo "IP:       $IP/$NETMASK"

# --- Create VM ---
qm create $VMID \
  --name $HOSTNAME \
  --memory $MEMORY \
  --cores $CORES \
  --net0 virtio,bridge=$BRIDGE,tag=$VLAN,firewall=1,rate=$NET_LIMIT \
  --scsihw virtio-scsi-single \
  --ostype l26 \
  --agent enabled=1

# --- Add disk from Ceph ---
echo "Adding ${DISK_SIZE}GB disk on $STORAGE..."
qm set $VMID --scsi0 $STORAGE:$DISK_SIZE,iothread=1

# --- Set boot order ---
qm set $VMID --boot order=scsi0

# --- Import cloud-init ---
qm set $VMID \
  --ide2 $STORAGE:cloudinit \
  --ipconfig0 ip=$IP/$NETMASK,gw=$GATEWAY \
  --ciuser $SSH_USER \
  --nameserver 1.1.1.1 \
  --searchdomain local

# --- Generate unique SSH key for this VM ---
echo "Generating unique SSH key for $SSH_USER..."
SSH_KEY_DIR="/root/.ssh/vm-keys"
mkdir -p $SSH_KEY_DIR
ssh-keygen -t ed25519 -f "$SSH_KEY_DIR/id_ed25519_$VMID" -N "" -C "$SSH_USER@$HOSTNAME" -q

# Set the public key on the VM
qm set $VMID --sshkeys "$SSH_KEY_DIR/id_ed25519_$VMID.pub"

echo "SSH private key saved to: $SSH_KEY_DIR/id_ed25519_$VMID"
echo "SSH public key: $(cat $SSH_KEY_DIR/id_ed25519_$VMID.pub)"

# --- Firewall rules ---
echo "Configuring firewall..."
mkdir -p /etc/pve/firewall
cat > /etc/pve/firewall/$VMID.fw << EOF
[OPTIONS]
enable: 1
dhcp: 1
ipfilter: 1
log_level_in: nolog
log_level_out: nolog
macfilter: 1
ndp: 1
policy_in: DROP
policy_out: ACCEPT
smurfs: 1

[RULES]
IN ACCEPT -p tcp --dport 22 -log nolog  # SSH
IN ACCEPT -p tcp --dport 80 -log nolog  # HTTP
IN ACCEPT -p tcp --dport 443 -log nolog # HTTPS
EOF

# --- Enable HA ---
echo "Enabling HA for VM $VMID..."
ha-manager add vm:$VMID --state started --group default 2>/dev/null || \
  pvesh create /cluster/ha/resources --sid vm:$VMID --state started 2>/dev/null || \
  echo "Note: Configure HA manually in Proxmox UI if needed"

# --- Start VM ---
echo "Starting VM $VMID..."
qm start $VMID

echo ""
echo "=== VM $VMID created successfully ==="
echo ""
echo "Next steps (run inside the VM via console):"
echo "1. apt update && apt upgrade -y"
echo "2. apt install -y apache2 php php-mysql mariadb-server wordpress"
echo "3. Configure WordPress at http://$IP/wordpress"
echo ""
echo "SSH access:"
echo "  ssh -i $SSH_KEY_DIR/id_ed25519_$VMID $SSH_USER@$IP"
echo ""
echo "Monitoring (Node Exporter):"
echo "  curl http://$IP:9100/metrics"