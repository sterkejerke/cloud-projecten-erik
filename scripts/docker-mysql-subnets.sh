#!/bin/bash
# Opdracht 2 - Docker MySQL Subnetten
# This script sets up two MySQL containers in separate subnets
# and demonstrates network isolation and connectivity

echo "=== Step 1: Create two separate subnets ==="
docker network create --driver bridge --subnet 172.30.0.0/24 mysql-subnet-1
docker network create --driver bridge --subnet 172.31.0.0/24 mysql-subnet-2

echo ""
echo "=== Step 2: Start MySQL container 1 in subnet 1 ==="
docker run -d --name mysql1 \
  --network mysql-subnet-1 \
  --ip 172.30.0.10 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=db1 \
  mysql:5.7

echo ""
echo "=== Step 3: Start MySQL container 2 in subnet 2 ==="
docker run -d --name mysql2 \
  --network mysql-subnet-2 \
  --ip 172.31.0.10 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=db2 \
  mysql:5.7

echo ""
echo "=== Step 4: Wait for MySQL to start ==="
sleep 20

echo ""
echo "=== Step 5: Test isolation - mysql1 cannot reach mysql2 ==="
docker exec mysql1 bash -c "ping -c 2 172.31.0.10 2>/dev/null || echo 'ISOLATED - Cannot reach mysql2'"

echo ""
echo "=== Step 6: Test host can reach both containers ==="
ping -c 2 172.30.0.10 && echo "Host can reach mysql1"
ping -c 2 172.31.0.10 && echo "Host can reach mysql2"

echo ""
echo "=== Step 7: Connect mysql1 to subnet 2 ==="
docker network connect mysql-subnet-2 mysql1

echo ""
echo "=== Step 8: Test connectivity after connecting ==="
docker exec mysql1 bash -c "mysql -h 172.31.0.10 -u root -prootpass -e 'SHOW DATABASES;' 2>/dev/null && echo 'SUCCESS - mysql1 can now reach mysql2'"

echo ""
echo "=== Step 9: Show all networks ==="
docker network ls

echo ""
echo "=== Done! MySQL subnet demonstration complete ==="
