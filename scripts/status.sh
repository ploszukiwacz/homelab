#!/bin/bash

echo "=== DOCKER SERVICES STATUS ==="
echo "$(date)"
echo "---------------------------------"

# Get all running containers
echo "RUNNING CONTAINERS:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES"
echo

# Get all stopped containers
echo "STOPPED CONTAINERS:"
docker ps -f "status=exited" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES"
echo

# Check system resources
echo "SYSTEM RESOURCES:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo "Memory: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
echo "Disk: $(df -h / | awk '$NF=="/"{printf "%s", $5}')"