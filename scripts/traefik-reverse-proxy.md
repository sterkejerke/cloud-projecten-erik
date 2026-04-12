# Traefik Reverse Proxy & Nginx Load Balancer — Opdracht 3

## Wat is een Reverse Proxy?

Een **reverse proxy** staat tussen de gebruiker en de backend servers. Inkomend verkeer gaat eerst naar de reverse proxy, die het doorstuur naar de juiste backend server. De gebruiker ziet alleen het IP van de proxy, niet van de backend servers.

**Voordelen:**
- Één enkel ingangspunt voor alle services
- SSL-terminatie op één plek
- Load balancing over meerdere servers
- Backend servers zijn niet direct bereikbaar (veiliger)
- Automatische service discovery met Docker labels

---

## Deel 1: Traefik Reverse Proxy

**Gevolgde tutorial:** https://doc.traefik.io/traefik/getting-started/quick-start/

### docker-compose.yml

```yaml
version: '3'
services:
  reverse-proxy:
    image: traefik:v2.11
    command: --api.insecure=true --providers.docker
    ports:
      - "80:80"
      - "8090:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  whoami:
    image: traefik/whoami
    labels:
      - "traefik.http.routers.whoami.rule=Host(`whoami.localhost`)"
```

### Opstarten

```bash
cd ~/traefik
docker-compose up -d
```

### Testen

```bash
# Traefik dashboard
curl http://localhost:8090/api/rawdata

# whoami service via Traefik hostname routing
curl -H "Host: whoami.localhost" http://localhost
```

### Uitkomst

Traefik ontdekt automatisch alle Docker containers via de Docker socket en maakt ze bereikbaar via hostname-routing. De whoami container toont request headers inclusief `X-Forwarded-For` van Traefik.

---

## Deel 2: Nginx Load Balancer

**Gevolgde tutorial:** https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/

### Projectstructuur

```
nginx-lb/
├── docker-compose.yml
├── nginx.conf
├── web1/
│   └── index.html   # <h1>Server 1</h1>
└── web2/
    └── index.html   # <h1>Server 2</h1>
```

### nginx.conf

```nginx
events {}
http {
  upstream backend {
    server web1:80;
    server web2:80;
  }
  server {
    listen 80;
    location / {
      proxy_pass http://backend;
    }
  }
}
```

### docker-compose.yml

```yaml
version: '3'
services:
  web1:
    image: nginx
    volumes:
      - ./web1:/usr/share/nginx/html

  web2:
    image: nginx
    volumes:
      - ./web2:/usr/share/nginx/html

  loadbalancer:
    image: nginx
    ports:
      - "8888:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
```

### Opstarten

```bash
cd ~/nginx-lb
docker-compose up -d
```

### Testen — Round Robin Load Balancing

```bash
curl http://localhost:8888   # <h1>Server 1</h1>
curl http://localhost:8888   # <h1>Server 2</h1>
curl http://localhost:8888   # <h1>Server 1</h1>
curl http://localhost:8888   # <h1>Server 2</h1>
```

Nginx verdeelt het verkeer automatisch beurtelings over web1 en web2.

---

## Verschil Traefik vs Nginx

| | Traefik | Nginx |
|---|---|---|
| Service discovery | Automatisch via Docker labels | Handmatig configureren |
| Configuratie | Docker labels | nginx.conf bestand |
| Dashboard | Ingebouwd op poort 8080 | Niet standaard |
| Load balancing | Ondersteund | Ondersteund |
| SSL | Automatisch via Let's Encrypt | Handmatig configureren |
