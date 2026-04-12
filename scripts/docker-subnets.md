# Docker Subnetten — Opdracht 2

## Wat zijn Docker subnetten?

Docker maakt het mogelijk om containers in aparte virtuele netwerken (subnetten) te plaatsen. Elk subnet heeft zijn eigen IP-range en de containers in verschillende subnetten kunnen standaard **niet** met elkaar communiceren.

## Opdracht: Twee MySQL containers in aparte subnetten

### Stap 1: Subnetten aanmaken

```bash
docker network create --driver bridge --subnet 172.30.0.0/24 mysql-subnet-1
docker network create --driver bridge --subnet 172.31.0.0/24 mysql-subnet-2
```

### Stap 2: MySQL containers starten

```bash
docker run -d --name mysql1 \
  --network mysql-subnet-1 \
  --ip 172.30.0.10 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=db1 \
  mysql:5.7

docker run -d --name mysql2 \
  --network mysql-subnet-2 \
  --ip 172.31.0.10 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=db2 \
  mysql:5.7
```

### Stap 3: Isolatie testen

```bash
# Vanuit mysql1 proberen mysql2 te bereiken — dit mislukt (isolatie werkt)
docker exec mysql1 bash -c "ping -c 2 172.31.0.10 || echo ISOLATED"
# Output: ISOLATED
```

### Stap 4: Host bereikbaarheid testen

```bash
# Vanuit de Proxmox host zijn beide containers bereikbaar
ping -c 2 172.30.0.10   # 0% packet loss
ping -c 2 172.31.0.10   # 0% packet loss
```

### Stap 5: Containers verbinden (optioneel)

```bash
# mysql1 toegang geven tot subnet 2
docker network connect mysql-subnet-2 mysql1

# Nu kan mysql1 wel bij mysql2
docker exec mysql1 bash -c "mysql -h 172.31.0.10 -u root -prootpass -e 'SHOW DATABASES;'"
```

## Waarom zijn subnetten nuttig?

1. **Isolatie**: Containers in verschillende subnetten kunnen elkaar niet zomaar bereiken. Dit verhoogt de veiligheid.
2. **Segmentatie**: Je kunt frontend, backend en database containers scheiden in aparte netwerken.
3. **Beveiliging**: Een aanvaller die toegang krijgt tot een container in subnet A, heeft geen automatische toegang tot subnet B.
4. **Controle**: Je bepaalt zelf welke containers met elkaar mogen communiceren via `docker network connect`.
5. **Schaalbaarheid**: Grote applicaties kunnen netjes worden opgedeeld per functie of per klant.

## Docker netwerk commando's

```bash
docker network ls                          # Lijst alle netwerken
docker network inspect mysql-subnet-1      # Details van een netwerk
docker network connect mysql-subnet-2 mysql1  # Container toevoegen aan netwerk
docker network disconnect mysql-subnet-1 mysql1  # Container verwijderen uit netwerk
docker network rm mysql-subnet-1           # Netwerk verwijderen
```
