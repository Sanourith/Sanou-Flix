# terraform/providers.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/kubeconfig.yaml"
    insecure = true # must be false in prod
  }
}
