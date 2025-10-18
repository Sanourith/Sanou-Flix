#!/bin/bash
set -e
cd "$(dirname "$0")/../infra"

terraform init
terraform apply -auto-approve
