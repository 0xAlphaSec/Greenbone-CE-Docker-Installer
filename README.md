# Greenbone Community Edition - Docker Installer

Automated installer script for deploying **Greenbone Community Edition (GCE)** via Docker on Ubuntu-based systems.

## What it does

- Removes conflicting old Docker packages
- Installs Docker CE and Docker Compose Plugin
- Downloads the official Greenbone compose file
- Applies known tag fixes automatically
- Pulls and starts all required containers
- Waits for `gvmd` to be healthy
- Sets the admin password interactively

## Requirements

- Ubuntu-based system (tested with Ubuntu)
- Internet access
- Run as root / sudo

## Usage

```bash
git clone https://github.com/0xAlphaSec/Greenbone-CE-Docker-Installer.git
cd Greenbone-CE-Docker-Installer
sudo bash greenbone-deploy.sh
```

## Access

Once the script finishes:

| Field    | Value                        |
|----------|------------------------------|
| URL      | `http://<your-ip>:9392`      |
| Username | `admin`                      |
| Password | *(the one you set during install)* |

> ⚠️ Feed sync can take 15–20 minutes after first start. Wait before launching scans.

## Author

**Jesús Fernández** — [@0xAlphaSec](https://github.com/0xAlphaSec)
