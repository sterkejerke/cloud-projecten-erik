#!/bin/bash
# Lesson 10 - Docker Basic Networking Commands
# This script runs Docker networking commands one by one

echo "=== Step 1: List all Docker networks ==="
docker network ls

echo ""
echo "=== Step 2: Create a custom bridge network ==="
docker network create --driver bridge my-custom-network

echo ""
echo "=== Step 3: List networks again to see the new one ==="
docker network ls

echo ""
echo "=== Step 4: Inspect the new network ==="
docker network inspect my-custom-network

echo ""
echo "=== Step 5: Run a container on the custom network ==="
docker run -d --name net-test --network my-custom-network nginx

echo ""
echo "=== Step 6: Show container network details ==="
docker inspect net-test | grep -A 20 Networks

echo ""
echo "=== Step 7: Connect container to another network ==="
docker network connect bridge net-test

echo ""
echo "=== Step 8: Show updated network details ==="
docker inspect net-test | grep -A 20 Networks

echo ""
echo "=== Step 9: Disconnect from custom network ==="
docker network disconnect my-custom-network net-test

echo ""
echo "=== Step 10: Cleanup ==="
docker stop net-test
docker rm net-test
docker network rm my-custom-network

echo ""
echo "=== Done! All Docker networking commands executed ==="
