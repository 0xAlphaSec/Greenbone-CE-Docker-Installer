#!/bin/bash

#==================================================
# Greenbone Community Edition - Installer 
# Author Jesús Fernández (@0xAlphaSec)
# Versión: 1.0
#==================================================

# # Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Log Fuction
function log_ok(){ echo -e "${greenColour}[+]${endColour}${grayColour}$1${endColour}"; }
function log_error(){ echo -e "${redColour}[X]${endColour}${grayColour}$1${endColour}"; }
function log_info(){ echo -e "${blueColour}[*]${endColour}${grayColour}$1${endColour}"; }
function log_warning(){ echo -e "${yellowColour}[!]${endColour}${grayColour}$1${endColour}"; }
function log_section(){ echo -e "${purpleColour}[#]${endColour}${grayColour}$1${endColour}"; }


# Trap ctrl_c
trap ctrl_c INT

function ctrl_c(){
  echo -e "\n\n${yellowColour}[*]${endColour}${grayColour}Exiting...${endColour}"
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
  echo -e "${grayColour} Community Edition - Docker Installer${endColour}"
  echo -e "${grayColour} ------------------------------------${endColour}"
}

# Ask admin password
function ask_password(){
  log_info "Enter the admin password for Greenbone:"
  read -s adminPassword
  echo ""
  if [ -z "$adminPassword" ]; then
    log_error "Password cannot be empty"
    tput cnorm; exit 1
  fi
  log_ok "Password set."
}

#===========================
# PHASE 1 - CLEANUP
# ==========================
function phase_cleanup(){
  log_section "PHASE 1 - Cleanup"

  log_info "Removing old Docker packages if present..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    if dpkg -l | grep -q "^ii $pkg "; then
      apt remove -y "$pkg" &>/dev/null
      log_ok "Removed: $pkg"
    fi
  done

  log_info "Removing old Greenbone containers and images if present..."
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "greenbone"; then
    docker ps -a --format '{{.Names}}' | grep "greenbone" | xargs docker rm -f &>/dev/null

    log_ok "Greenbone containers removed."
  fi

  if docker images --format '{{.Repository}}' 2>/dev/null | grep -q "greenbone"; then
    docker images --format '{{-Repository}}:{{.Tag}}' | grep greenbone | xargs docker rmi -f &>/dev/null
    log_ok "Greenbone images removed."
  fi

  log_ok "Cleanup complete"
}

#====================================
# PHASE 2 - DOCKER INSTALLATION
#====================================
function phase_docker(){
  log_section "PHASE 2 - Docker Installation"

  if command -v docker &>/dev/null; then
    log_warning "Docker is already installed. Skipping"
    return
  fi

  log_info "Installing dependencies..."
  apt install -y ca-certificates curl gnupg &>/dev/null
  log_ok "Dependencies installed."

  log_info "Adding Docker GPG key..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &>/dev/null
  chmod a+r /etc/apt/keyrings/docker.gpg
  log_ok "GPG key added"

  log_info "Adding Docker repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update &>/dev/null
  log_ok "Repository added."

  log_info "Installing Docker..."
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin &>/dev/null
  log_ok "Docker installed: $(docker --version)"

  log_info "Adding current user to docker group..."
  usermod -aG docker "$SUDO_USER" &>/dev/null
  log_ok "User $SUDO_USER added to docker group."
}

#========================================
# PHASE 3 - GREENBONE SETUP
# =======================================
function phase_greenbone(){
  log_section "PHASE 3 - Greenbone Community Edition Setup"

  DOWNLOAD_DIR="$HOME/greenbone-community-container"
  mkdir -p "$DOWNLOAD_DIR"

  log_info "Downloading compose.yaml"
  curl -f -O -L https://greenbone.github.io/docs/latest/_static/compose.yaml \
    --output-dir "$DOWNLOAD_DIR" &>/dev/null
  if [ $? -ne 0 ]; then
    log_error "Failed to download compose.yaml. Check your internet connection."
    tput cnorm; exit 1
  fi
  log_ok "compose.yaml downloaded."

  log_info "Checking for known tag issues..."
  if grep -q "gsa:stable-slim" "$DOWNLOAD_DIR/compose.yaml"; then
    sed -i 's/gsa:stable-slim/gsa:stable/g' "$DOWNLOAD_DIR/compose.yaml"
    log_warning "Fixed: gsa:stable-slim -> gsa:stable"
  else
    log_ok "No tag issues found."
  fi

  log_info "Pulling images (this may take a while)..."
  docker compose -f "$DOWNLOAD_DIR/compose.yaml" pull
  if [ $? -ne 0 ]; then
    log_error "Image pull failed."
    tput cnorm; exit 1
  fi
  log_ok "Images pulled."

  log_info "Starting containers..."
  docker compose -f "$DOWNLOAD_DIR/compose.yaml" up -d &>/dev/null
  log_ok "Containers started."

  log_info "Waiting for gvmd to be ready..."
  local retries=0
  local max=30
  while [ $retries -lt $max ]; do
    status=$(docker inspect --format='{{.State.Health.Status}}' \
      greenbone-community-edition-gvmd-1 2>/dev/null)
    if [ "$status" == "healthy" ]; then
      break
    fi
    echo -ne "${grayColour}   Waiting... (${retries}/${max})${endColour}\r"
    sleep 10
    retries=$((retries + 1))
  done

  if [ "$status" != "healthy" ]; then
    log_warning "gvmd did not reach healthy state in time. Try setting the password manually later."
  else
    log_ok "gvmd is healthy."

    log_info "Setting admin password..."
    docker compose -f "$DOWNLOAD_DIR/compose.yaml" \
      exec -u gvmd gvmd gvmd --user=admin --new-password="$adminPassword" &>/dev/null
    log_ok "Admin password set."
  fi
}

#==================================
# FINAL SUMMARY
#==================================
function summary(){
  local ip
  ip=$(hostname -I | awk '{print $1}')

  echo -e "\n${greenColour}╔══════════════════════════════════════════════╗${endColour}"
  echo -e "${greenColour}║   Greenbone Community Edition is ready!      ║${endColour}"
  echo -e "${greenColour}╚══════════════════════════════════════════════╝${endColour}\n"
  echo -e "  ${grayColour}Acces URL :${endColour} ${turquoiseColour}http://${ip}:9392${endColour}"
  echo -e "  ${grayColour}Username  :${endColour} ${turquoiseColour}admin${endColour}"
  echo -e "  ${grayColour}Password  :${endColour} ${turquoiseColour}(the one you entered)${endColour}"

  echo -e "${grayColour}Compose  :${endColour} ${turquoiseColour}$HOME/greenbone-community-container/compose.yaml${endColour}"
  echo -e "${yellowColour}[!]${endColour}${grayColour} Feed sync may take 15-20 min. Wait before scanning${endColour}"
}

#===============================
# MAIN
#===============================
tput civis # hide cursor

check_root
banner
ask_password
phase_cleanup
phase_docker
phase_greenbone
summary

tput cnorm # restore cursor
