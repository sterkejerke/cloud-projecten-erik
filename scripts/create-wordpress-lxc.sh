#!/bin/bash
# create-wordpress-lxc.sh
# Automatische uitrol van een WordPress LXC container op Proxmox
# Gebruik: ./create-wordpress-lxc.sh [vmid] [hostname] [ip]
# Voorbeeld: ./create-wordpress-lxc.sh 100 wordpress-client1 10.24.52.100

set -e

# --- Configuratie ---
CTID=${1:-100}
HOSTNAME=${2:-wordpress-client1}
IP=${3:-10.24.52.100}
GATEWAY=10.24.52.1
NETMASK=24
STORAGE=cephpool
BRIDGE=vmbr1
DISK_SIZE=30
MEMORY=1024
CORES=1
NET_LIMIT=51200  # 50MB/s in KB/s
TEMPLATE="local:vztmpl/debian-12-turnkey-wordpress_18.2-1_amd64.tar.gz"
SSH_USER="wpuser-${CTID}"

echo "=== Wordpress LXC Container aanmaken ==="
echo "CTID:     $CTID"
echo "Hostname: $HOSTNAME"
echo "IP:       $IP/$NETMASK"
echo "Gateway:  $GATEWAY"

# --- Container aanmaken ---
echo "Container aanmaken..."
pct create $CTID $TEMPLATE \
  --hostname $HOSTNAME \
  --storage $STORAGE \
  --rootfs $STORAGE:$DISK_SIZE \
  --memory $MEMORY \
  --cores $CORES \
  --net0 name=eth0,bridge=$BRIDGE,ip=$IP/$NETMASK,gw=$GATEWAY,rate=$NET_LIMIT,firewall=1 \
  --unprivileged 0 \
  --features nesting=1 \
  --start 0

echo "Container aangemaakt."

# --- Firewall configuratie ---
echo "Firewall instellen..."
mkdir -p /etc/pve/firewall
cat > /etc/pve/firewall/$CTID.fw << EOF
[OPTIONS]
enable: 1
dhcp: 1
ipfilter: 0
log_level_in: nolog
log_level_out: nolog
policy_in: DROP
policy_out: ACCEPT

[RULES]
IN ACCEPT -p tcp --dport 22 -log nolog
IN ACCEPT -p tcp --dport 80 -log nolog
IN ACCEPT -p tcp --dport 443 -log nolog
EOF

echo "Firewall geconfigureerd: DROP policy, poorten 22/80/443 open."

# --- Container starten ---
echo "Container starten..."
pct start $CTID
sleep 10

# --- Unieke SSH gebruiker aanmaken ---
echo "Unieke SSH gebruiker aanmaken: $SSH_USER..."
pct exec $CTID -- useradd -m -s /bin/bash $SSH_USER
pct exec $CTID -- bash -c "echo '$SSH_USER:Hanze2026' | chpasswd"
pct exec $CTID -- mkdir -p /home/$SSH_USER/.ssh
pct exec $CTID -- chmod 700 /home/$SSH_USER/.ssh

# --- SSH key genereren ---
echo "SSH key genereren voor $SSH_USER..."
SSH_KEY_DIR="/root/.ssh/lxc-keys"
mkdir -p $SSH_KEY_DIR
ssh-keygen -t ed25519 -f "$SSH_KEY_DIR/id_ed25519_$CTID" -N "" -C "$SSH_USER@$HOSTNAME" -q

# Public key in container plaatsen
pct push $CTID "$SSH_KEY_DIR/id_ed25519_$CTID.pub" /home/$SSH_USER/.ssh/authorized_keys
pct exec $CTID -- chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh
pct exec $CTID -- chmod 600 /home/$SSH_USER/.ssh/authorized_keys

# --- Monitoring (Node Exporter) ---
echo "Node Exporter installeren voor monitoring..."
pct push $CTID /usr/local/bin/node_exporter /usr/local/bin/node_exporter 2>/dev/null || true
pct exec $CTID -- bash -c 'chmod +x /usr/local/bin/node_exporter 2>/dev/null; nohup /usr/local/bin/node_exporter --web.listen-address=0.0.0.0:9100 > /var/log/node_exporter.log 2>&1 &' 2>/dev/null || true

echo ""
echo "=== Container $CTID succesvol aangemaakt! ==="
echo ""
echo "Verbindingsgegevens:"
echo "  SSH:        ssh -i $SSH_KEY_DIR/id_ed25519_$CTID $SSH_USER@$IP"
echo "  Wordpress:  http://$IP/wp-admin"
echo "  Monitoring: http://$IP:9100/metrics"
echo ""
echo "Private key: $SSH_KEY_DIR/id_ed25519_$CTID"
