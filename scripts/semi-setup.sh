#!/bin/bash

set -e

echo "=== Homelab Setup Script ==="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root"
   exit 1
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p ssl

# Copy environment files
echo "Setting up environment files..."
for env_file in containers/*/.env.example; do
    if [[ -f "$env_file" ]]; then
        target="${env_file%.example}"
        if [[ ! -f "$target" ]]; then
            cp "$env_file" "$target"
            echo "Created: $target"
        fi
    fi
done

# Create Docker network
echo "Creating Docker network..."
docker network create traefik_proxy 2>/dev/null || echo "Network already exists"

echo "Setup complete!"
echo "Next steps:"
echo "1. Add SSL certificates to ssl/ directory"
echo "2. Configure .env files in containers/"
echo "3. Update domain names from .hl.lan to your domain"
echo "4. Start services with: cd containers/proxy && docker compose up -d"