#!/bin/bash
cd "$(dirname "$0")/../infra"
terraform destroy -auto-approve
