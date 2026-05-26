variable "project_name" {
  type = string
}

variable "k3s_version" {
  type = string
}

variable "server_count" {
  type = number
}

variable "worker_count" {
  type = number
}

variable "k3s_token" {
  type      = string
  sensitive = true
}

variable "network_name" {
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
