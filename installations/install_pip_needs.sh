#!/bin/bash

set -e

# Colors :
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
source venv-data/bin/activate

# OPENMETEO needs
log_info "Installing pip dependencies..."
pip install openmeteo-requests
pip install requests-cache retry-requests numpy pandas
