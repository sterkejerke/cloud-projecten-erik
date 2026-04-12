#!/bin/bash
# WordPress LXC Container Creation Script
# Usage: ./create-wordpress-lxc.sh <CTID> <HOSTNAME> <IP>
# Example: ./create-wordpress-lxc.sh 101 wordpress-client1b 192.168.100.11

CTID=${1:-101}
HOSTNAME=${2:-wordpress-lxc}
IP=${3:-192.168.100.11}
TEMPLATE="local:vztmpl/debian-12-turnkey-wordpress_18.2-1_amd64.tar.gz"
USERNAME="wpuser${CTID}"

echo "=== Creating WordPress LXC Container ==="
echo "CTID: $CTID | Hostname: $HOSTNAME | IP: $IP"

pct create $CTID $TEMPLATE \
  --hostname $HOSTNAME \
  --cores 1 \
  --memory 1024 \
  --swap 512 \
  --rootfs cephpool:30 \
  --net0 name=eth0,bridge=vmbr0,ip=${IP}/24,gw=192.168.100.1,rate=50 \
  --unprivileged 1 \
  --features nesting=1

pct start $CTID
sleep 10

pct exec $CTID -- bash -c "echo 'nameserver 1.1.1.1' > /etc/resolv.conf"
pct exec $CTID -- bash -c "ip route add default via 192.168.100.1 2>/dev/null || true"
pct exec $CTID -- bash -c "apt-get update -y"
pct exec $CTID -- bash -c "apt-get install -y ufw"
pct exec $CTID -- bash -c "ufw default deny incoming"
pct exec $CTID -- bash -c "ufw default allow outgoing"
pct exec $CTID -- bash -c "ufw allow 22/tcp"
pct exec $CTID -- bash -c "ufw allow 80/tcp"
pct exec $CTID -- bash -c "ufw allow 443/tcp"
pct exec $CTID -- bash -c "ufw --force enable"
pct exec $CTID -- bash -c "useradd -m -s /bin/bash $USERNAME"
pct exec $CTID -- bash -c "mkdir -p /home/$USERNAME/.ssh"
pct exec $CTID -- bash -c "ssh-keygen -t ed25519 -f /home/$USERNAME/.ssh/id_ed25519 -N '' -C '$USERNAME@$HOSTNAME'"
pct exec $CTID -- bash -c "cp /home/$USERNAME/.ssh/id_ed25519.pub /home/$USERNAME/.ssh/authorized_keys"
pct exec $CTID -- bash -c "chmod 700 /home/$USERNAME/.ssh && chmod 600 /home/$USERNAME/.ssh/authorized_keys"
pct exec $CTID -- bash -c "chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh"

echo "=== Done! WordPress at http://$IP | User: $USERNAME ==="
pct exec $CTID -- bash -c "cat /home/$USERNAME/.ssh/id_ed25519"