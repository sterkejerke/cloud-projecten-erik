# SDI2 Proxmox Cluster Assignment

## Overview
This repository contains automation scripts for deploying a Proxmox cluster
with Ceph storage, WordPress LXC containers, and HA for a WordPress VM.

## Infrastructure
- **3 Proxmox nodes**: PVE01, PVE02, PVE03
- **Cluster name**: SDI2cluster
- **Internal network**: 192.168.100.0/24
- **Ceph storage**: 900GB across 3 OSDs
- **Monitoring**: Prometheus Node Exporter on all nodes (port 9100)

## Scripts

### Bash Script: create-wordpress-lxc.sh
Creates a WordPress LXC container with all requirements.

**Usage:**
```bash
./create-wordpress-lxc.sh   
./create-wordpress-lxc.sh 101 wordpress-client1b 192.168.100.11
```

**Features:**
- 30GB disk on Ceph storage
- 1 CPU, 1GB RAM
- Network speed limited to 50MB/s
- UFW firewall (ports 22, 80, 443 only)
- Unique SSH user with ed25519 key

### Ansible Playbook: create-wordpress-lxc.yml
Ansible version of the above script.

**Usage:**
```bash
ansible-playbook create-wordpress-lxc.yml -e "ctid=102 hostname=wordpress-ansible ip=192.168.100.12"
```

## Client 1 - WordPress LXC (cheap/training)
- Container 100: manual setup
- Container 101: bash script
- Container 102: Ansible playbook

## Client 2 - WordPress VM with HA
- VM 200: Debian 13 + WordPress
- Proxmox HA enabled
- Stored on shared Ceph storage

## Monitoring
Prometheus Node Exporter installed on all 3 nodes.
Access metrics at: http://<node-tailscale-ip>:9100/metrics