# Opdracht 2.2 - Docker MySQL Subnets

## Gevolgde tutorial
YouTube: Docker networking is crazy (https://www.youtube.com/watch?v=bKFMS5C4CG0)

## Opzet

Twee MySQL containers zijn opgezet in aparte subnetten:

- **mysql1** - subnet `mysql-subnet-1` (172.30.0.0/24), IP: 172.30.0.10
- **mysql2** - subnet `mysql-subnet-2` (172.31.0.0/24), IP: 172.31.0.10

## Commando's

```bash
# Netwerken aanmaken
docker network create --subnet=172.30.0.0/24 mysql-subnet-1
docker network create --subnet=172.31.0.0/24 mysql-subnet-2

# MySQL containers starten in aparte subnetten
docker run -d --name mysql1 \
  --network mysql-subnet-1 \
  --ip 172.30.0.10 \
  -e MYSQL_ROOT_PASSWORD=root \
  mysql:5.7

docker run -d --name mysql2 \
  --network mysql-subnet-2 \
  --ip 172.31.0.10 \
  -e MYSQL_ROOT_PASSWORD=root \
  mysql:5.7
```

## Bereikbaarheid testen

```bash
# Vanuit het Proxmox subnet kun je de containers bereiken via hun IP:
curl -m 3 172.30.0.10:3306  # mysql1
curl -m 3 172.31.0.10:3306  # mysql2

# Containers kunnen elkaar NIET bereiken zonder extra netwerk
# omdat ze in aparte subnetten zitten
docker exec mysql1 ping 172.31.0.10  # Fails - different subnet

# Om ze met elkaar te laten praten, voeg je een shared network toe:
docker network create mysql-shared
docker network connect mysql-shared mysql1
docker network connect mysql-shared mysql2
docker exec mysql1 ping mysql2  # Nu werkt het wel
```

## Waarom meerdere subnetten?

- **Isolatie**: Containers in aparte subnetten kunnen standaard niet met elkaar communiceren. Dit verhoogt de beveiliging.
- **Segmentatie**: Verschillende applicaties/klanten kunnen hun eigen netwerksegment krijgen.
- **Controle**: Je bepaalt zelf welke containers met elkaar mogen praten door ze aan gedeelde netwerken toe te voegen.
- **Best practice**: In productie wil je databases isoleren van de applicatielaag via aparte netwerken.
