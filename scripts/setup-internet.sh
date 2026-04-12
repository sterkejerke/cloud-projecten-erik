#!/bin/bash
# Script to restore internet access on Proxmox nodes after reboot
# Run this on each node with the correct IP for that node
# PVE01: 145.37.234.135, PVE02: 145.37.234.136, PVE03: 145.37.234.137

NODE_IP=${1:-"145.37.234.135"}

ip link set ens19 up
ip addr add 145.37.234.135/24 dev ens19 2>/dev/null || true
ip route del default 2>/dev/null || true
ip route add default via 145.37.234.1 dev ens19
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Restore NAT for containers (run on PVE01 only)
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens19 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Internet restored on $NODE_IP"
ping -c 2 1.1.1.1


# node 1

ip link set ens19 up
ip addr add 145.37.234.135/24 dev ens19 2>/dev/null || true
ip route del default 2>/dev/null || true
ip route add default via 145.37.234.1 dev ens19
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Restore NAT for containers (run on PVE01 only)
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens19 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Internet restored on $NODE_IP"
ping -c 2 1.1.1.1


# node 2

ip link set ens19 up
ip addr add 145.37.234.136/24 dev ens19 2>/dev/null || true
ip route del default 2>/dev/null || true
ip route add default via 145.37.234.1 dev ens19
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Restore NAT for containers (run on PVE01 only)
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens19 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Internet restored on $NODE_IP"
ping -c 2 1.1.1.1


# node 3

ip link set ens19 up
ip addr add 145.37.234.137/24 dev ens19 2>/dev/null || true
ip route del default 2>/dev/null || true
ip route add default via 145.37.234.1 dev ens19
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Restore NAT for containers (run on PVE01 only)
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens19 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Internet restored on $NODE_IP"
ping -c 2 1.1.1.1
