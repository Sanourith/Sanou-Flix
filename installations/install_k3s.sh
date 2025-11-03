#!/bin/bash

set -e

success() { echo "✅ $1"; }
error() { echo "❌ $1" >&2; }
log() { echo "📦 $1"; }

install_kubectl_k3s() {
    log "INSTALLATION KUBECTL & K3S"

    # Vérifier kubectl
    if command -v kubectl &>/dev/null; then
        success "kubectl déjà installé ($(kubectl version --client --short 2>/dev/null || echo 'version inconnue'))"
    else
        echo "Installation de kubectl..."
        local kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
        curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        success "kubectl installé"
    fi

    # Vérifier K3s
    if command -v k3s &>/dev/null && systemctl is-active --quiet k3s; then
        success "K3s déjà installé et actif"
    else
        echo "Installation de K3s..."
        curl -sfL https://get.k3s.io | sh -
        success "K3s installé"
    fi

    # Configuration kubeconfig
    local kube_dir="$HOME/.kube"
    local kubeconfig="$kube_dir/config"

    mkdir -p "$kube_dir"

    if [ ! -f "$kubeconfig" ] || [ "/etc/rancher/k3s/k3s.yaml" -nt "$kubeconfig" ]; then
        sudo cp /etc/rancher/k3s/k3s.yaml "$kubeconfig"
        sudo chown $(id -u):$(id -g) "$kubeconfig"
        success "Configuration kubectl mise à jour"
    else
        success "Configuration kubectl déjà à jour"
    fi

    # Ajouter alias kubectl si pas déjà présent
    if ! grep -q 'alias k="kubectl"' ~/.bashrc; then
        echo 'alias k="kubectl"' >> ~/.bashrc
        success "Alias 'k' pour kubectl ajouté"
    else
        success "Alias 'k' déjà configuré"
    fi
}

install_kubectl_k3s
