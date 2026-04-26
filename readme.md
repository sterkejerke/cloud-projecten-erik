# SDI2 Cloud Computing — Portfolio Opdracht

**Student:** Erik Witteveen | **Studentnummer:** 413560  
**Hanze Hogeschool Groningen | 2025-2026**

---

## Overzicht

Deze repository bevat alle scripts, configuraties, screenshots en video's voor de SDI2 Cloud Computing portfolio opdracht. Het project omvat het opzetten van een Proxmox cluster met Ceph storage, automatische uitrol van Wordpress applicaties voor 2 klanten, Docker Swarm, en load balancing.

---

## Infrastructuur

| Component | Details |
|-----------|---------|
| Cluster naam | SDI2cluster |
| PVE01 | 10.24.52.10 (Tailscale: 100.123.80.59) |
| PVE02 | 10.24.52.11 |
| PVE03 | 10.24.52.12 |
| VLAN | 2452 |
| Subnet | 10.24.52.0/24 |
| Gateway | 10.24.52.1 |
| Ceph storage | 900GB, 3 OSDs, pool: cephpool |
| Monitoring | Prometheus Node Exporter (poort 9100) |

---

## Opdracht 1 — Proxmox Cluster & Wordpress

### Draaiende Machines

| VMID | Naam | Type | IP | Omschrijving |
|------|------|------|----|--------------|
| 100 | wordpress-client1 | LXC | 10.24.52.100 | Klant 1 — handmatig |
| 101 | wordpress-client1b | LXC | 10.24.52.101 | Klant 1 — bash script |
| 102 | wordpress-ansible | LXC | 10.24.52.102 | Klant 1 — Ansible playbook |
| 104 | wordpress-client4 | LXC | 10.24.52.104 | Klant 1 — bash script |
| 105 | wordpress-client5 | LXC | 10.24.52.105 | Klant 1 — bash script |
| 200 | wordpress-vm-client2 | QEMU VM | 10.24.52.200 | Klant 2 — HA VM |
| 103 | ubuntu-docker | QEMU VM | 10.24.52.50 | Docker Leader |
| 202 | ubuntu-docker-2 | LXC | — | Docker Reachable |
| 203 | ubuntu-docker-3 | LXC | — | Docker Reachable |

### Script: create-wordpress-lxc.sh

Automatische uitrol van Wordpress LXC containers.

```bash
./create-wordpress-lxc.sh [vmid] [hostname] [ip]
./create-wordpress-lxc.sh 104 wordpress-client4 10.24.52.104
```

**Functies:**
- 30GB disk op Ceph storage
- 1 CPU, 1GB RAM, netwerklimiet 50MB/s
- Proxmox firewall: DROP policy, alleen poort 22, 80, 443
- Unieke SSH user met ed25519 key per container
- Node Exporter automatisch geinstalleerd (monitoring)

### Script: create-wordpress-vm.sh

Automatische uitrol van Wordpress VM met Proxmox HA.

```bash
./create-wordpress-vm.sh [vmid] [hostname] [ip]
./create-wordpress-vm.sh 200 wordpress-vm-client2 10.24.52.200
```

**Functies:**
- QEMU VM met Cloud-init, 30GB Ceph disk, 1 CPU, 1GB RAM, 50MB/s
- Proxmox HA ingeschakeld
- Firewall: DROP policy, poort 22, 80, 443
- Unieke SSH user met ed25519 key

### Ansible Playbook: create-wordpress-lxc.yaml

```bash
ansible-playbook create-wordpress-lxc.yaml -e "ctid=102 hostname=wordpress-ansible ip=10.24.52.102"
```

### SSH Login met Key (geen password)

```bash
ssh -i /root/.ssh/lxc-keys/id_ed25519_100 user-wp1@10.24.52.100
```

### Monitoring

Node Exporter op alle nodes + automatisch op elke nieuwe container:

```bash
curl http://10.24.52.10:9100/metrics
curl http://10.24.52.11:9100/metrics
curl http://10.24.52.12:9100/metrics
```

Ceph status:

```bash
ceph -s && ceph osd status && ceph df && rbd ls cephpool
```

---

## Opdracht 2 — Docker

### Docker Swarm (Lesson 9)

1 Swarm cluster met 3 managers — 1 per Proxmox node:

```bash
docker swarm init --advertise-addr 10.24.52.50
docker swarm join --token SWMTKN-1-... 10.24.52.50:2377
docker node ls
```

Output:
```
HOSTNAME          STATUS    MANAGER STATUS
ubuntu-docker     Ready     Leader
ubuntu-docker-2   Ready     Reachable
ubuntu-docker-3   Ready     Reachable
```

### Docker Compose Files

| File | Omschrijving |
|------|-------------|
| docker-compose-lesson8.yml | Nginx + MySQL stack (lesson 8) |
| docker-compose-nginx-lb.yml | Nginx load balancer (opdracht 3) |
| docker-compose-traefik.yml | Traefik reverse proxy (opdracht 3) |

### Networking Script (Lesson 10)

```bash
bash docker-networking.sh
```

### MySQL Subnetten (Opdracht 2.2)

```bash
bash docker-mysql-subnets.sh
```

Zie [docker-subnets.md](scripts/docker-subnets.md) voor volledige uitleg.

---

## Opdracht 3 — Load Balancing & Reverse Proxy

### Traefik

Tutorial: https://doc.traefik.io/traefik/getting-started/quick-start/

```bash
cd traefik && docker-compose up -d
curl http://localhost:8090/api/overview
```

### Nginx Load Balancer

```bash
cd nginx-lb && docker-compose up -d
curl http://localhost:8888  # => Server 1
curl http://localhost:8888  # => Server 2
```

Zie [traefik-reverse-proxy.md](scripts/traefik-reverse-proxy.md) voor volledige documentatie.

---

## Repository Structuur

```
cloud-projecten-erik/
├── Documentatie/
│   ├── Leeswijzer.docx              # Portfolio leeswijzer (met screenshots)
│   ├── Leeswijzer.pdf
│   ├── SDI2-Documentatie.docx       # Technische documentatie
│   └── SDI2-Documentatie.pdf
├── Opdracht/                        # Originele opdracht PDFs
├── scripts/
│   ├── create-wordpress-lxc.sh      # Bash script LXC uitrol
│   ├── create-wordpress-lxc.yaml    # Ansible playbook LXC
│   ├── create-wordpress-vm.sh       # Bash script VM uitrol
│   ├── Dockerfile                   # Custom Nginx image (lesson 7)
│   ├── docker-compose-lesson8.yml   # Lesson 8 stack
│   ├── docker-compose-nginx-lb.yml  # Nginx load balancer
│   ├── docker-compose-traefik.yml   # Traefik reverse proxy
│   ├── docker-mysql-subnets.sh      # MySQL subnetten script
│   ├── docker-networking.sh         # Lesson 10 networking script
│   ├── docker-subnets.md            # MySQL subnetten documentatie
│   ├── nginx.conf                   # Nginx load balancer config
│   ├── setup-ceph-monitor.sh        # Ceph monitor setup
│   ├── setup-internet.sh            # Internet configuratie
│   └── traefik-reverse-proxy.md     # Load balancer documentatie
├── screenshots/
│   ├── opdr 1 - cloud/              # SSH logins, monitoring, Ceph, keys
│   └── opdr 2 - docker/             # Docker swarm, images, netwerk, LB
├── videos/
│   ├── create-wordpress.mov         # Geautomatiseerde uitrol CT 104 + CT 105
│   ├── dashbord cepth.mov           # Ceph storage dashboard
│   ├── ha migratie.mov              # HA failover demonstratie
│   ├── main environment.mov         # Proxmox cluster overzicht
│   ├── monitoring.mov               # Node Exporter metrics
│   └── tailscale setup.mov          # Remote toegang via Tailscale
└── readme.md
```
