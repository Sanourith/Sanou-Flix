#!/bin/bash

set -e

# Colors :
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() {
    echo -e "$BLUE[DOCKER]${NC} $1";
}

log_success() {
    echo -e "$GREEN[DOCKER]${NC} $1";
}

log_warning() {
    echo -e "${YELLOW}[DOCKER]${NC} $1";
}

log_error() {
    echo -e "${RED}[DOCKER]${NC} $1";
}

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log_warning "Docker already installed : $DOCKER_VERSION"
    log_info "Verifying installation..."

    if docker run hello-world &> /dev/null; then
        log_success "Docker fonctionne correctement"
        exit 0
    else
        log_warning "Docker might have problems, reparing..."
    fi
fi

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    log_error "Impossible de détecter la distribution"
    exit 1
fi

install_docker_debian() {
    log_info "Installing Docker for Debian/Ubuntu..."

    # Suppression des anciennes versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Mise à jour des paquets
    sudo apt-get update

    # Installation des prérequis
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Ajout de la clé GPG officielle de Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Ajout du dépôt Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Mise à jour avec le nouveau dépôt
    sudo apt-get update

    # Installation de Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

log_info "Launching Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER

log_info "Cleaning test image..."
sudo docker rmi hello-world 2>/dev/null || true

log_success "Docker installation completed !"
