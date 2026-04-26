# Opdracht 3 - Load Balancing en Reverse Proxy

## Deel 1 - Traefik Reverse Proxy (2pt)

Tutorial gevolgd: https://doc.traefik.io/traefik/getting-started/quick-start/

### Wat is een Reverse Proxy?

Een reverse proxy staat tussen de client en de backend servers. De client stuurt een verzoek naar de proxy, die het doorstuurt naar de juiste backend server. De client weet niet welke backend server het verzoek afhandelt.

**Voordelen:**
- **Load balancing**: verzoeken worden verdeeld over meerdere servers
- **SSL terminatie**: de proxy regelt HTTPS, de backends draaien HTTP
- **Beveiliging**: backend servers zijn niet direct bereikbaar vanuit het internet
- **Caching**: de proxy kan responses cachen voor betere performance
- **Centraal beheer**: configuratiewijzigingen op 1 plek voor alle backends

### Traefik opzetten

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
cd /home/erik/traefik
docker-compose up -d
```

### Verificatie

```bash
# Traefik dashboard API
curl http://localhost:8090/api/overview
# Output:
# {"http":{"routers":{"total":7},"services":{"total":8},"middlewares":{"total":2}}}

# Draaiende containers
docker ps | grep traefik
# traefik:v2.11    Up  0.0.0.0:80->80/tcp, 0.0.0.0:8090->8080/tcp
# traefik/whoami   Up  80/tcp
```

Traefik detecteert automatisch nieuwe Docker containers via labels en voegt ze toe als routes zonder herstart.

---

## Deel 2 - Nginx Load Balancer (4pt)

Tutorial gevolgd: https://www.nginx.com/resources/wiki/start/topics/examples/loadbalanceexample/

Twee Nginx webservers achter een Nginx load balancer via Docker Compose.

### nginx.conf (load balancer configuratie)

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

### docker-compose-nginx-lb.yml

```yaml
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

### Starten

```bash
cd /home/erik/nginx-lb
docker-compose up -d
```

### Bewijs - Round Robin Load Balancing

```bash
curl http://localhost:8888
# <h1>Server 1</h1>

curl http://localhost:8888
# <h1>Server 2</h1>

curl http://localhost:8888
# <h1>Server 1</h1>
```

Requests worden afgewisseld tussen Server 1 en Server 2 - dit bewijst dat de load balancer correct werkt via round-robin algoritme.

### Ook als Docker Swarm service

```bash
docker service create \
  --name nginx-lb \
  --replicas 3 \
  --publish 8080:80 \
  nginx

docker service ls
docker service ps nginx-lb
```
