# Opdracht 3 - Load Balancing en Reverse Proxy

## Wat is een Reverse Proxy?

Een reverse proxy staat tussen de client en de backend servers. De client stuurt een verzoek naar de proxy, die het doorstelt naar de juiste backend server. De client weet niet welke backend server het verzoek afhandelt.

Voordelen:
- **Load balancing**: verzoeken worden verdeeld over meerdere servers
- **SSL termination**: de proxy regelt HTTPS, de backends draaien HTTP
- **Beveiliging**: backend servers zijn niet direct bereikbaar
- **Caching**: de proxy kan responses cachen

## Deel 1 - Traefik (2pt)

Tutorial gevolgd: https://doc.traefik.io/traefik/getting-started/quick-start/

### Opzet

```yaml
# docker-compose.yml
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

### Starten

```bash
docker-compose up -d
```

### Verificatie

```bash
# Traefik dashboard
curl http://localhost:8090/api/overview

# Whoami service via Traefik
curl http://whoami.localhost
```

Traefik detecteert automatisch nieuwe Docker containers via labels en voegt ze toe als routes.

## Deel 2 - Nginx Load Balancer (4pt)

### Opzet

Twee Nginx webservers achter een Nginx load balancer:

```yaml
# docker-compose.yml (nginx-lb)
version: '3'
services:
  loadbalancer:
    image: nginx
    ports:
      - "8888:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf

  web1:
    image: nginx
    volumes:
      - ./web1:/usr/share/nginx/html

  web2:
    image: nginx
    volumes:
      - ./web2:/usr/share/nginx/html
```

### Nginx load balancer configuratie

```nginx
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
```

### Verificatie - Round Robin load balancing

```bash
curl http://localhost:8888  # Returns: <h1>Server 1</h1>
curl http://localhost:8888  # Returns: <h1>Server 2</h1>
curl http://localhost:8888  # Returns: <h1>Server 1</h1>
```

Requests worden afgewisseld tussen Server 1 en Server 2 - dit bewijst dat de load balancer werkt.
