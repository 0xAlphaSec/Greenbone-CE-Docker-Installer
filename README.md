# Greenbone Community Edition — Docker Installer

Automated installer script for deploying **Greenbone Community Edition (GCE)** via Docker on Ubuntu-based systems.

## What it does

- Removes conflicting legacy Docker packages
- Installs Docker CE and Docker Compose Plugin from the official repository
- Offers partial or deep Docker cleanup if Docker is already installed
- Checks available disk space before pulling images
- Uses `compose.yaml` included in the repository (no external download needed)
- Configures web interface access (localhost or local network)
- Pulls and starts all required containers
- Waits for `gvmd` to be healthy
- Sets the admin password interactively

## Requirements

- Ubuntu 22.04 or 24.04 (other Debian derivatives likely work)
- Internet access
- Run as root / sudo
- ~8 GB of free disk space

## Usage

```bash
git clone https://github.com/0xAlphaSec/Greenbone-CE-Docker-Installer.git
cd Greenbone-CE-Docker-Installer
sudo bash greenbone-deploy.sh
```

The script is fully interactive — it asks everything it needs before making any changes.

## Web interface

| Option | URL | Notes |
|---|---|---|
| Localhost only | `https://localhost` | Default, more secure |
| Local network | `https://<host-ip>` | Accessible from other machines on the network |

> ⚠️ Feed sync can take 15–20 minutes after first start. Wait before launching scans.

## After installation

The `compose.yaml` stays in the cloned repository directory.

```bash
# Check status
docker compose -f ~/Greenbone-CE-Docker-Installer/compose.yaml ps

# Stop
docker compose -f ~/Greenbone-CE-Docker-Installer/compose.yaml down

# Start
docker compose -f ~/Greenbone-CE-Docker-Installer/compose.yaml up -d

# Update images
docker compose -f ~/Greenbone-CE-Docker-Installer/compose.yaml pull
docker compose -f ~/Greenbone-CE-Docker-Installer/compose.yaml up -d
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Author

**Jesús Fernández** — [jfg.sec](https://www.instagram.com/jfg.sec) — [LinkedIn](https://www.linkedin.com/in/jesus-fernandez-gervasi)
