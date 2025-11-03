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

script=$(readlink -f "$0")
project_root=$(dirname $(dirname "$script"))
cd "$project_root"

echo "🚀 Installing GitLab Runner..."

# Load environment variables
if [ -f "env/private.env" ]; then
    source env/private.env
    log_success "✅ Environment loaded"
else
    log_error "❌ FATAL: env/private.env not found"
    exit 1
fi

# Validate token
if [ -z "$gitlabtoken" ]; then
    log_error "❌ FATAL: GitLab token is missing from env/private.env"
    log_info "Please set: gitlabtoken=glrt-your-token"
    log_info "Go to website gitlab.com / CICD settings / Add a runner, then get gitlatoken and put it into 'private.env'"
    exit 1
fi

runner_name="gbm_dst"

log_info "Updating packages..."
sudo apt update -y
sudo apt install -y curl jq

# Install GitLab Runner
if command -v gitlab-runner &> /dev/null; then
    log_success "✅ GitLab Runner is already installed: $(gitlab-runner --version)"
else
    log_info "📦 Installing GitLab Runner..."
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
    sudo apt install gitlab-runner -y
    log_success "✅ GitLab Runner installed"
fi

# Start service
if sudo systemctl is-active --quiet gitlab-runner; then
    log_success "✅ GitLab Runner is already running"
else
    log_info "▶️ Starting GitLab Runner..."
    sudo systemctl enable gitlab-runner
    sudo gitlab-runner start
    log_success "✅ GitLab Runner started"
fi

# Register runner
if sudo gitlab-runner list 2>/dev/null | grep -q "https://gitlab.com"; then
    log_success "✅ GitLab Runner is already registered"
    sudo gitlab-runner list
else
    log_info "📝 Registering GitLab Runner..."
    sudo gitlab-runner register --non-interactive \
        --executor shell \
        --url https://gitlab.com \
        --token "$gitlabtoken"
    log_success "✅ GitLab Runner registered"
    log_warning "⚠️ Configuration (tags, etc.) must be set in GitLab UI"
fi

# Set concurrent jobs
if ! sudo grep -q 'concurrent = 3' /etc/gitlab-runner/config.toml; then
    log_warning "⚙️ Setting concurrent jobs to 3..."
    sudo sed -i 's/concurrent = 1/concurrent = 3/' /etc/gitlab-runner/config.toml
    sudo systemctl restart gitlab-runner
    log_success "✅ Concurrent jobs updated"
fi

# Setup gitlab-runner user permissions
log_info "🔧 Setting up gitlab-runner permissions..."
sudo mkdir -p /home/gitlab-runner/builds
sudo mkdir -p /home/gitlab-runner/.kube
sudo chown -R gitlab-runner:gitlab-runner /home/gitlab-runner/
sudo chmod -R 755 /home/gitlab-runner/

# Setup Kubernetes config (if available)
if [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
    log_info "🎯 Setting up Kubernetes config..."
    sudo cp /etc/rancher/k3s/k3s.yaml /home/gitlab-runner/.kube/config
    sudo chown gitlab-runner:gitlab-runner /home/gitlab-runner/.kube/config
    sudo chmod 600 /home/gitlab-runner/.kube/config
    log_success "✅ Kubernetes config setup complete"
else
    log_warning "⚠️ K3s config not found, skipping Kubernetes setup"
fi

log_info ""
log_info "🎉 GitLab Runner installation completed!"
log_info ""
log_info "📊 Status:"
sudo gitlab-runner --version
log_info ""
sudo systemctl status gitlab-runner --no-pager -l
log_info ""
log_info "📋 Registered runners:"
sudo gitlab-runner list
log_info ""
log_info "💡 Next steps:"
log_info "1. Go to your GitLab project → Settings → CI/CD → Runners"
log_info "2. Verify your runner '$runner_name' appears with 🟢 status"
log_info "3. In your .gitlab-ci.yml, use: tags: [\"$runner_name\"]"


# UNINSTALL :
# sudo apt-get remove --purge gitlab-runner -y
# sudo rm -rf /etc/gitlab-runner
# sudo rm -rf /home/gitlab-runner
# sudo userdel gitlab-runner
# sudo groupdel gitlab-runner
