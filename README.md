# PlOszukiwacz's Homelab (v4)

Welcome to my homelab repo! This setup uses Docker Compose with Traefik as a reverse proxy (no more nginx instances for each service for ssl (what v1, v2 and v3 used)).

## ⚠️ Important Note
Some values are hardcoded for my specific setup. **Please review and update the following before use:**
- Domain names (`.hl.lan` throughout)
- File paths in [`scripts/backup.sh`](scripts/backup.sh)
- Mount points in [`containers/jellyfin/docker-compose.yml`](containers/jellyfin/docker-compose.yml) and more
- SSL certificate paths

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ploszukiwacz/homelab.git
   cd homelab
   ```

2. **Set up SSL certificates:**
   - Place your certificates in the [`ssl/`](ssl/) directory
   - See [`ssl/README.md`](ssl/README.md) for details

3. **Configure environment files:**
   ```bash
   # Copy and edit environment files
   cp containers/beszel/.env.example containers/beszel/.env
   cp containers/roundcube/.env.example containers/roundcube/.env
   ```

4. **Create Docker network:**
   ```bash
   docker network create traefik_proxy
   ```

5. **Start services:**
   ```bash
   # Start proxy first
   cd containers/proxy && docker compose up -d
   
   # Then start other services
   cd ../jellyfin && docker compose up -d
   # ... repeat for other services
   ```

## 📁 Services

| Service | URL | Description |
|---------|-----|-------------|
| Homepage | `https://hl.lan` | Dashboard |
| Traefik | `https://traefik.hl.lan` | Reverse proxy admin |
| Jellyfin | `https://jellyfin.hl.lan` | Media server |
| AdGuard Home | `https://adguard.hl.lan` | DNS ad blocker |
| Portainer | `https://portainer.hl.lan` | Docker management |
| Beszel | `https://beszel.hl.lan` | System monitoring |
| Roundcube | `https://roundcube.hl.lan` | Webmail |
| SearXNG | `https://search.hl.lan` | Privacy search engine |
| Miniflux| `https://miniflux.hl.lan` | FOSS RSS Reader |
| Silverbullet | `https://silverbullet.hl.lan` | FOSS Notes App |

## 🛠️ Scripts

- [`scripts/semi-setup.sh`](scripts/semi-setup.sh) - Install Docker and dependencies
- [`scripts/backup.sh`](scripts/backup.sh) - Backup system data
- [`scripts/status.sh`](scripts/status.sh) - Check service status

## 📂 Directory Structure

```
containers/     # Docker Compose files for each service
scripts/        # Automation and setup scripts
ssl/           # SSL certificates (gitignored)
```

## 🔧 Customization

1. **Update domains:** Replace `.hl.lan` with your domain in all compose files
2. **Configure services:** Edit `.env` files in each service directory
3. **Adjust paths:** Update mount points in compose files to match your system

## 🤝 Contributing

Contributions are welcome! Please open issues or submit pull requests.

## 📄 License

This project is licensed under the PLOHL License - see [`LICENSE`](LICENSE) for details.