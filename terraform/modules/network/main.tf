# terraform/modules/network/main.tf

resource "docker_network" "k3s" {
  name   = "${var.project_name}-network"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/16"
    gateway = "172.20.0.1"
  }
}

output "network_name" {
  value = docker_network.k3s.name
}
