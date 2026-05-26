# terraform/modules/network/variables.tf

variable "project_name" {
  type = string
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
