#!/bin/bash

#==================================================
# Greenbone Community Edition - Installer
# Author: Jesús Fernández (@0xAlphaSec)
# Version: 3.0
# Supports: Debian/Ubuntu (apt) | AlmaLinux/RHEL/Rocky (dnf)
#==================================================

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Log functions
function log_ok()      { echo -e "${greenColour}[+]${endColour}${grayColour} $1${endColour}\n"; }
function log_error()   { echo -e "${redColour}[X]${endColour}${grayColour} $1${endColour}\n"; }
function log_info()    { echo -e "${blueColour}[*]${endColour}${grayColour} $1${endColour}\n"; }
function log_warning() { echo -e "${yellowColour}[!]${endColour}${grayColour} $1${endColour}\n"; }
function log_section() { echo -e "${purpleColour}[#]${endColour}${grayColour} $1${endColour}\n"; }

# Trap Ctrl+C
trap ctrl_c INT
function ctrl_c(){
    echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Exiting...${endColour}"
    tput cnorm; exit 0
}

# Check root
function check_root(){
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root. Use sudo."
        tput cnorm; exit 1
    fi
}

# Banner
function banner(){
    echo -e "${turquoiseColour}"
    cat << 'EOF'
 ██████╗ ██████╗ ███████╗███████╗███╗   ██╗██████╗  ██████╗ ███╗   ██╗███████╗
██╔════╝ ██╔══██╗██╔════╝██╔════╝████╗  ██║██╔══██╗██╔═══██╗████╗  ██║██╔════╝
██║  ███╗██████╔╝█████╗  █████╗  ██╔██╗ ██║██████╔╝██║   ██║██╔██╗ ██║█████╗
██║   ██║██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║██║╚██╗██║██╔══╝
╚██████╔╝██║  ██║███████╗███████╗██║ ╚████║██████╔╝╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
EOF
    echo -e "${endColour}"
    echo -e "${grayColour}  Community Edition - Docker Installer v3.0${endColour}"
    echo -e "${grayColour}  -----------------------------------------${endColour}"
}

#==========================
# DISTRO DETECTION
#==========================

PKG_MANAGER=""
DISTRO_NAME=""
DOCKER_REPO_URL=""
LEGACY_PKGS=""

function detect_distro(){
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_NAME="${NAME}"
    else
        DISTRO_NAME="Unknown"
    fi

    if command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        DOCKER_REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
        LEGACY_PKGS="podman buildah docker"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        LEGACY_PKGS="docker.io docker-doc docker-compose podman-docker containerd runc"
    else
        log_error "Unsupported package manager. Only apt (Debian/Ubuntu) and dnf (RHEL/AlmaLinux/Rocky) are supported."
        tput cnorm; exit 1
    fi

    echo -e "  ${blueColour}[*]${endColour}${grayColour} Detected: ${DISTRO_NAME} (${PKG_MANAGER})${endColour}\n"
}

# Global vars
NETWORK_MODE=""   # "local" | "lan"
CLEAN_MODE="none" # "none" | "partial" | "deep"
adminPassword=""

#==========================
# INTERACTIVE SETUP
#==========================

function ask_password(){
    log_info "Enter the admin password for Greenbone:"
    read -s adminPassword
    echo ""
    if [ -z "$adminPassword" ]; then
        log_error "Password cannot be empty."
        tput cnorm; exit 1
    fi
    log_ok "Password set."
}

function ask_network_mode(){
    echo ""
    log_info "How do you want to expose the web interface?"
    echo -e "  ${turquoiseColour}[1]${endColour}${grayColour} Localhost only  (https://localhost — default, more secure)${endColour}"
    echo -e "  ${turquoiseColour}[2]${endColour}${grayColour} Local network   (https://<IP> — accessible from other machines)${endColour}"
    echo ""
    echo -ne "  ${grayColour}Choose [1/2]: ${endColour}"
    read -r net_choice
    echo ""

    case "$net_choice" in
        2)
            NETWORK_MODE="lan"
            log_ok "Network mode: LAN (all interfaces)"
            ;;
        *)
            NETWORK_MODE="local"
            log_ok "Network mode: localhost only"
            ;;
    esac
}

function ask_clean_mode(){
    if ! command -v docker &>/dev/null; then
        CLEAN_MODE="none"
        return
    fi

    echo ""
    log_info "Docker is already installed. A cleanup is recommended to avoid volume conflicts."
    echo ""
    echo -e "  ${turquoiseColour}[1]${endColour}${grayColour} Partial cleanup  — Remove only Greenbone containers, images and volumes${endColour}"
    echo -e "  ${turquoiseColour}[2]${endColour}${grayColour} Deep cleanup     — Remove ALL Docker data on this machine (irreversible)${endColour}"
    echo -e "  ${turquoiseColour}[3]${endColour}${grayColour} Skip             — Continue without any cleanup${endColour}"
    echo ""
    echo -ne "  ${grayColour}Choose [1/2/3]: ${endColour}"
    read -r clean_choice
    echo ""

    case "$clean_choice" in
        1)
            CLEAN_MODE="partial"
            log_ok "Partial cleanup selected."
            ;;
        2)
            echo -e "  ${redColour}WARNING: This will permanently delete ALL containers, images,${endColour}"
            echo -e "  ${redColour}volumes and networks — not just Greenbone ones.${endColour}"
            echo -ne "  ${grayColour}Type ${endColour}${redColour}CONFIRM${endColour}${grayColour} to proceed: ${endColour}"
            read -r deep_confirm
            echo ""
            if [ "$deep_confirm" = "CONFIRM" ]; then
                CLEAN_MODE="deep"
                log_ok "Deep cleanup confirmed."
            else
                CLEAN_MODE="partial"
                log_warning "Deep cleanup cancelled. Falling back to partial cleanup."
            fi
            ;;
        *)
            CLEAN_MODE="none"
            log_info "Skipping cleanup."
            ;;
    esac
}

#===========================
# PHASE 1 - CLEANUP
#===========================

function remove_legacy_packages(){
    log_info "Removing conflicting legacy packages if present..."
    for pkg in $LEGACY_PKGS; do
        if [ "$PKG_MANAGER" = "dnf" ]; then
            if rpm -q "$pkg" &>/dev/null; then
                dnf remove -y "$pkg" &>/dev/null
                log_ok "Removed: $pkg"
            fi
        elif [ "$PKG_MANAGER" = "apt" ]; then
            if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
                apt remove -y "$pkg" &>/dev/null
                log_ok "Removed: $pkg"
            fi
        fi
    done
}

function phase_cleanup_partial(){
    log_section "PHASE 1 - Partial Cleanup (Greenbone only)"

    log_info "Stopping and removing Greenbone containers..."
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "greenbone"; then
        docker ps -a --format '{{.Names}}' | grep "greenbone" | xargs docker rm -f &>/dev/null
        log_ok "Greenbone containers removed."
    else
        log_info "No Greenbone containers found."
    fi

    log_info "Removing Greenbone images..."
    if docker images --format '{{.Repository}}' 2>/dev/null | grep -q "greenbone"; then
        docker images --format '{{.Repository}}:{{.Tag}}' | grep "greenbone" | xargs docker rmi -f &>/dev/null
        log_ok "Greenbone images removed."
    else
        log_info "No Greenbone images found."
    fi

    log_info "Removing Greenbone volumes..."
    if docker volume ls --format '{{.Name}}' 2>/dev/null | grep -q "greenbone"; then
        docker volume ls --format '{{.Name}}' | grep "greenbone" | xargs docker volume rm -f &>/dev/null
        log_ok "Greenbone volumes removed."
    else
        log_info "No Greenbone volumes found."
    fi

    remove_legacy_packages
    log_ok "Partial cleanup complete."
}

function phase_cleanup_deep(){
    log_section "PHASE 1 - Deep Cleanup (all Docker data)"

    log_info "Running docker system prune (all containers, images, volumes, networks)..."
    docker system prune -a --volumes -f 2>&1 | while IFS= read -r line; do
        echo -e "  ${grayColour}${line}${endColour}"
    done
    log_ok "Deep cleanup complete."
}

#====================================
# DISK SPACE CHECK
#====================================

function check_disk_space(){
    local min_gb=8
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local check_dir="$script_dir"
    while [ ! -d "$check_dir" ]; do
        check_dir=$(dirname "$check_dir")
    done

    local free_kb
    free_kb=$(df --output=avail "$check_dir" 2>/dev/null | tail -1)

    if [ -z "$free_kb" ]; then
        log_warning "Could not determine available disk space. Proceeding anyway."
        return
    fi

    local free_gb=$(( free_kb / 1024 / 1024 ))
    local free_mb=$(( free_kb / 1024 ))

    echo ""
    if [ "$free_gb" -ge "$min_gb" ]; then
        log_ok "Disk space: ${free_gb} GB available — OK"
    elif [ "$free_mb" -ge 4096 ]; then
        log_warning "Disk space: only ~${free_gb} GB available (${free_mb} MB). Recommended: ${min_gb} GB."
        log_warning "The install may fail or feeds may not sync completely."
        echo -ne "  ${grayColour}Continue anyway? [y/N]: ${endColour}"
        read -r space_confirm
        echo ""
        if [[ ! "$space_confirm" =~ ^[Yy]$ ]]; then
            log_info "Aborted. Free up disk space and try again."
            tput cnorm; exit 0
        fi
    else
        log_error "Disk space: only ~${free_mb} MB available. Minimum required: ~4 GB for images alone."
        log_error "Aborting. Free up disk space and try again."
        tput cnorm; exit 1
    fi
}

#====================================
# PHASE 2 - DOCKER INSTALLATION
#====================================

function phase_docker(){
    log_section "PHASE 2 - Docker Installation"

    if command -v docker &>/dev/null; then
        log_warning "Docker is already installed. Skipping."
        return
    fi

    if [ "$PKG_MANAGER" = "dnf" ]; then
        log_info "Installing Docker (RHEL/AlmaLinux/Rocky)..."
        dnf -y install dnf-plugins-core &>/dev/null
        dnf config-manager --add-repo "$DOCKER_REPO_URL" &>/dev/null
        dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin &>/dev/null
        systemctl enable --now docker &>/dev/null
        log_ok "Docker installed: $(docker --version)"

    elif [ "$PKG_MANAGER" = "apt" ]; then
        log_info "Installing Docker (Debian/Ubuntu)..."
        apt install -y ca-certificates curl gnupg &>/dev/null
        log_ok "Dependencies installed."

        log_info "Adding Docker GPG key..."
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &>/dev/null
        chmod a+r /etc/apt/keyrings/docker.gpg
        log_ok "GPG key added."

        log_info "Adding Docker repository..."
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
            | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update &>/dev/null
        log_ok "Repository added."

        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin &>/dev/null
        log_ok "Docker installed: $(docker --version)"
    fi

    log_info "Adding current user to docker group..."
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER" &>/dev/null
        log_ok "User '$SUDO_USER' added to docker group."
    else
        log_warning "Could not detect the original user (SUDO_USER is empty). Add them to the docker group manually."
    fi
}

#========================================
# PHASE 3 - GREENBONE SETUP
#========================================

function phase_greenbone(){
    log_section "PHASE 3 - Greenbone Community Edition Setup"

    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"

    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "compose.yaml not found in $SCRIPT_DIR"
        log_error "Make sure you cloned the full repository and are running the script from it."
        tput cnorm; exit 1
    fi

    log_ok "compose.yaml found at $SCRIPT_DIR"

    # Network mode: patch nginx ports if LAN
    if [ "$NETWORK_MODE" = "lan" ]; then
        log_info "Patching compose.yaml for LAN access (0.0.0.0)..."
        sed -i \
            -e 's/127\.0\.0\.1:443:443/0.0.0.0:443:443/g' \
            -e 's/127\.0\.0\.1:9392:9392/0.0.0.0:9392:9392/g' \
            "$COMPOSE_FILE"
        log_ok "compose.yaml patched for LAN."
    fi

    log_info "Pulling images (this may take a while)..."
    docker compose -f "$COMPOSE_FILE" pull
    if [ $? -ne 0 ]; then
        log_error "Image pull failed."
        tput cnorm; exit 1
    fi
    log_ok "Images pulled."

    log_info "Starting containers..."
    docker compose -f "$COMPOSE_FILE" up -d &>/dev/null
    log_ok "Containers started."

    # Resolve gvmd container name dynamically
    local GVMD_CONTAINER
    GVMD_CONTAINER=$(docker ps --format '{{.Names}}' | grep "gvmd" | head -1)

    if [ -z "$GVMD_CONTAINER" ]; then
        log_warning "Could not find a running gvmd container."
        log_warning "Set the password manually later with:"
        echo -e "  ${turquoiseColour}docker compose -f ${COMPOSE_FILE} exec -u gvmd gvmd gvmd --user=admin --new-password='<password>'${endColour}"
        return
    fi

    log_info "Waiting for gvmd to be ready (container: ${GVMD_CONTAINER})..."
    local retries=0
    local max=30
    local status=""

    while [ $retries -lt $max ]; do
        status=$(docker inspect --format='{{.State.Health.Status}}' "$GVMD_CONTAINER" 2>/dev/null)
        if [ "$status" = "healthy" ]; then
            break
        fi
        echo -ne "${grayColour}  Waiting... (${retries}/${max})${endColour}\r"
        sleep 10
        retries=$((retries + 1))
    done
    echo ""

    if [ "$status" != "healthy" ]; then
        log_warning "gvmd did not reach healthy state in time."
        log_warning "Set the password manually later with:"
        echo -e "  ${turquoiseColour}docker compose -f ${COMPOSE_FILE} exec -u gvmd gvmd gvmd --user=admin --new-password='<password>'${endColour}"
    else
        log_ok "gvmd is healthy."
        log_info "Setting admin password..."
        docker compose -f "$COMPOSE_FILE" \
            exec -u gvmd gvmd gvmd --user=admin --new-password="$adminPassword" &>/dev/null
        log_ok "Admin password set."
    fi
}

#==================================
# FINAL SUMMARY
#==================================

function summary(){
    local access_url
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [ "$NETWORK_MODE" = "lan" ]; then
        local host_ip
        host_ip=$(hostname -I | awk '{print $1}')
        access_url="https://${host_ip}"
    else
        access_url="https://localhost"
    fi

    echo ""
    echo -e "${greenColour}╔══════════════════════════════════════════════════╗${endColour}"
    echo -e "${greenColour}║      Greenbone Community Edition is ready!       ║${endColour}"
    echo -e "${greenColour}╚══════════════════════════════════════════════════╝${endColour}"
    echo ""
    echo -e "  ${grayColour}Distro      :${endColour}  ${turquoiseColour}${DISTRO_NAME} (${PKG_MANAGER})${endColour}"
    echo -e "  ${grayColour}Access URL  :${endColour}  ${turquoiseColour}${access_url}${endColour}"
    echo -e "  ${grayColour}Username    :${endColour}  ${turquoiseColour}admin${endColour}"
    echo -e "  ${grayColour}Password    :${endColour}  ${turquoiseColour}(the one you entered)${endColour}"
    echo -e "  ${grayColour}Compose     :${endColour}  ${turquoiseColour}${SCRIPT_DIR}/compose.yaml${endColour}"
    echo ""
    echo -e "  ${yellowColour}[!]${endColour}${grayColour} Feed sync may take 15–20 min. Wait before scanning.${endColour}"
    echo ""
}

#===============================
# MAIN
#===============================

tput civis  # hide cursor

check_root
banner
detect_distro

# Interactive setup (all questions upfront)
ask_password
ask_network_mode
ask_clean_mode   # only shows if Docker is already installed

# Phase 1: cleanup
case "$CLEAN_MODE" in
    partial) phase_cleanup_partial ;;
    deep)    phase_cleanup_deep ;;
    none)
        log_section "PHASE 1 - Cleanup"
        remove_legacy_packages
        log_ok "Done."
        ;;
esac

# Phase 2: Docker install
phase_docker

# Disk space check (always before pulling images)
check_disk_space

# Phase 3: Greenbone setup
phase_greenbone
summary

tput cnorm  # restore cursor
