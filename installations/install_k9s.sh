#!/bin/bash

set -e

success() { echo "✅ $1"; }
error() { echo "❌ $1" >&2; }
log() { echo "📦 $1"; }

install_k9s() {
    log "INSTALLATION K9S"

    if command -v k9s &>/dev/null; then
        success "K9s déjà installé ($(k9s version --short 2>/dev/null || echo 'version inconnue'))"
        return 0
    fi

    log "Installation de K9s..."
    local temp_file=$(mktemp --suffix=.deb)
    local k9s_version="v0.32.5"
    local k9s_url="https://github.com/derailed/k9s/releases/download/${k9s_version}/k9s_linux_amd64.deb"

    if wget -q "$k9s_url" -O "$temp_file" && sudo apt install -y "$temp_file"; then
        rm -f "$temp_file"
        success "K9s installé"
    else
        error "Échec de l'installation de K9s"
        rm -f "$temp_file"
        return 1
    fi
}

install_k9s
