#!/bin/bash
# Script to set up Ceph monitor on a node
# Usage: ./setup-ceph-monitor.sh <NODE_NAME> <NODE_IP>
# Example: ./setup-ceph-monitor.sh PVE01 192.168.100.1

NODE_NAME=${1:-"PVE01"}
NODE_IP=${2:-"192.168.100.1"}
FSID=$(grep fsid /etc/ceph/ceph.conf | awk '{print $3}')

echo "=== Setting up Ceph monitor on $NODE_NAME ==="

mkdir -p /var/lib/ceph/mon/ceph-${NODE_NAME}
chown ceph:ceph /var/lib/ceph/mon/ceph-${NODE_NAME}

monmaptool --create \
  --add PVE01 192.168.100.1 \
  --add PVE02 192.168.100.2 \
  --add PVE03 192.168.100.3 \
  --fsid $FSID --clobber /tmp/monmap

ceph-authtool --create-keyring /var/lib/ceph/mon/ceph-${NODE_NAME}/keyring \
  --gen-key -n mon. --cap mon 'allow *'

ceph-authtool /var/lib/ceph/mon/ceph-${NODE_NAME}/keyring \
  --import-keyring /etc/pve/priv/ceph.client.admin.keyring

chown -R ceph:ceph /var/lib/ceph/mon/ceph-${NODE_NAME}
systemctl reset-failed ceph-mon@${NODE_NAME}
systemctl start ceph-mon@${NODE_NAME}
systemctl status ceph-mon@${NODE_NAME}

echo "=== Ceph monitor $NODE_NAME setup complete ==="