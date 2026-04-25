# SDI2 Cloud Computing — Portfolio Opdracht

**Student:** Erik Witteveen | **Studentnummer:** 413560  
**Hanze Hogeschool Groningen | 2025-2026**

---

## Overzicht

Deze repository bevat alle scripts, configuraties, screenshots en video's voor de SDI2 Cloud Computing portfolio opdracht. Het project omvat het opzetten van een Proxmox cluster met Ceph storage, automatische uitrol van Wordpress applicaties, Docker Swarm, en load balancing.

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
| 102 | wordpress-ansible | LXC | 10.24.52.102 | Klant 1 — Ansible |
| 200 | wordpress-vm-client2 | QEMU VM | 10.24.52.200 | Klant 2 — HA VM |
| 103 | ubuntu-docker | QEMU VM | 10.24.52.50 | Docker |
| 202 | ubuntu-docker-2 | LXC | — | Docker |
| 203 | ubuntu-docker-3 | LXC | — | Docker |

### Script: create-wordpress-lxc.sh

Automatische uitrol van Wordpress LXC containers.

```bash
# Gebruik
./create-wordpress-lxc.sh [vmid] [hostname] [ip]
./create-wordpress-lxc.sh 100 wordpress-client1 10.24.52.100
```

**Functies:**
- 30GB disk op Ceph storage
- 1 CPU, 1GB RAM
- Netwerk limiet: 50MB/s
- Firewall: DROP policy, alleen poort 22, 80, 443
- Unieke SSH user met ed25519 key per container

### Script: create-wordpress-vm.sh

Automatische uitrol van Wordpress VM met Proxmox HA.

```bash
# Gebruik
./create-wordpress-vm.sh [vmid] [hostname] [ip]
./create-wordpress-vm.sh 200 wordpress-vm-client2 10.24.52.200
```

**Functies:**
- QEMU VM met Cloud-init
- 30GB disk op Ceph storage
- 1 CPU, 1GB RAM, 50MB/s netwerk
- Proxmox HA ingeschakeld
- Firewall: DROP policy, poort 22, 80, 443

### Ansible Playbook: create-wordpress-lxc.yaml

```bash
ansible-playbook create-wordpress-lxc.yaml -e "ctid=102 hostname=wordpress-ansible ip=10.24.52.102"
```

### Monitoring

Prometheus Node Exporter geinstalleerd op alle nodes:

```bash
curl http://10.24.52.10:9100/metrics
curl http://10.24.52.11:9100/metrics
curl http://10.24.52.12:9100/metrics
```

---

## Opdracht 2 — Docker

### Docker Installaties

Docker Engine 28.2.2 geinstalleerd op 3 Proxmox instanties:

- **VM 103** (ubuntu-docker): QEMU VM — 10.24.52.50
- **CT 202** (ubuntu-docker-2): LXC Container
- **CT 203** (ubuntu-docker-3): LXC Container

### Docker Swarm

3-node swarm met 1 manager per Proxmox node:

```bash
# Swarm initialiseren op VM 103
docker swarm init --advertise-addr 10.24.52.50

# Nodes toevoegen
docker swarm join --token SWMTKN-1-... 10.24.52.50:2377

# Swarm status
docker node ls
```

Output:
```
ID                            HOSTNAME          STATUS    AVAILABILITY   MANAGER STATUS
ljjfws1bg1vsebehzbgbv9git *   ubuntu-docker     Ready     Active         Leader
tfdgicozno8g3nq5v1pm3dn6c     ubuntu-docker-2   Ready     Active         Reachable
fs5dl1ax2ph6a5zlupcufwmga     ubuntu-docker-3   Ready     Active         Reachable
```

### Docker Compose Files

| File | Omschrijving |
|------|-------------|
| docker-compose-lesson8.yml | Nginx + MySQL stack (lesson 8) |
| docker-compose-nginx-lb.yml | Nginx load balancer (opdracht 3) |
| docker-compose-traefik.yml | Traefik reverse proxy (opdracht 3) |

### Networking Script: docker-networking.sh

```bash
bash docker-networking.sh
```

Demonstreert: `docker network ls`, `network create`, `network inspect`, container op custom network.

### MySQL Subnetten (Opdracht 2.2)

```bash
docker network create --subnet=172.30.0.0/24 mysql-subnet-1
docker network create --subnet=172.31.0.0/24 mysql-subnet-2
docker run -d --name mysql1 --network mysql-subnet-1 --ip 172.30.0.10 -e MYSQL_ROOT_PASSWORD=root mysql:5.7
docker run -d --name mysql2 --network mysql-subnet-2 --ip 172.31.0.10 -e MYSQL_ROOT_PASSWORD=root mysql:5.7
```

Zie [docker-subnets.md](scripts/docker-subnets.md) voor volledige documentatie.

---

## Opdracht 3 — Load Balancing & Reverse Proxy

### Traefik Reverse Proxy

```bash
cd traefik && docker-compose up -d
curl http://localhost:8090/api/overview
```

### Nginx Load Balancer

```bash
cd nginx-lb && docker-compose up -d
curl http://localhost:8888  # => Server 1
curl http://localhost:8888  # => Server 2
curl http://localhost:8888  # => Server 1
```

Zie [traefik-reverse-proxy.md](scripts/traefik-reverse-proxy.md) voor volledige documentatie.

---

## Repository Structuur

```
cloud-projecten-erik/
├── scripts/
│   ├── create-wordpress-lxc.sh      # Bash script LXC uitrol
│   ├── create-wordpress-lxc.yaml    # Ansible playbook LXC
│   ├── create-wordpress-vm.sh       # Bash script VM uitrol
│   ├── Dockerfile                   # Custom Nginx image
│   ├── docker-compose-lesson8.yml   # Lesson 8 stack
│   ├── docker-compose-nginx-lb.yml  # Load balancer
│   ├── docker-compose-traefik.yml   # Reverse proxy
│   ├── docker-subnets.md            # MySQL subnetten docs
│   └── traefik-reverse-proxy.md     # Load balancer docs
├── screenshots/
│   ├── opdr 1 - setup/              # SSH logins, monitoring
│   └── opdr 2 - docker/             # Docker bewijs
├── videos/                          # Demo videos
├── Leeswijzer.docx                  # Portfolio leeswijzer
└── SDI2-Documentatie.docx           # Technische documentatie
```
