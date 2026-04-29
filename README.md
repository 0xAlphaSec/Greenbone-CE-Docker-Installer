# Greenbone Community Edition — Docker Installer
 
Automated installer script for deploying **Greenbone Community Edition (GCE)** via Docker on Debian/Ubuntu and RHEL-based systems (AlmaLinux, Rocky Linux, CentOS Stream).
 
## What it does
 
- Detects the OS and package manager automatically (apt / dnf)
- Asks all configuration questions upfront before making any changes
- Removes conflicting legacy Docker packages for the detected distro
- Installs Docker CE and Docker Compose Plugin from the official repository
- Offers partial or deep Docker cleanup if Docker is already installed
- Checks available disk space before pulling images (recommends 8 GB minimum)
- Uses `compose.yaml` included in the repository — no external download needed
- Configures web interface access (localhost only or local network / LAN)
- Pulls and starts all required Greenbone containers
- Waits for `gvmd` to reach healthy state before proceeding
- Sets the admin password interactively
## Requirements
 
| | Debian / Ubuntu | AlmaLinux / Rocky / RHEL |
|---|---|---|
| Tested on | Ubuntu 22.04, 24.04 | AlmaLinux 9 |
| Package manager | apt | dnf |
| Run as | root / sudo | root / sudo |
| Disk space | ~8 GB free | ~8 GB free |
| Internet | Required | Required |
 
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
| Local network | `https://<host-ip>` | Accessible from other machines on the same network |
 
> ⚠️ Feed sync can take 15–20 minutes after first start. Wait before launching scans.
 
## Cleanup options
 
If Docker is already installed, the script offers three options:
 
| Option | What it removes |
|---|---|
| Partial cleanup | Only Greenbone containers, images and volumes |
| Deep cleanup | All Docker data on the machine (irreversible — requires explicit confirmation) |
| Skip | No cleanup, proceed directly to installation |
 
## After installation
 
The `compose.yaml` stays in the cloned repository directory.
 
```bash
# Check container status
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
