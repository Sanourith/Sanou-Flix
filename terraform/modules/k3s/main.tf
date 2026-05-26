# terraform/modules/k3s/main.tf

# === K3s Server (Master) ===
resource "docker_container" "k3s_server" {
  count = var.server_count

  name  = "${var.project_name}-server-${count.index}"
  image = "rancher/k3s:${var.k3s_version}"

  command = [
    "server",
    "--node-name=server-${count.index}",
    "--token=${var.k3s_token}",
    "--disable=traefik",
    "--tls-san=localhost",          # ← ajoute localhost au certificat TLS
    "--tls-san=127.0.0.1",         # ← idem pour l'IP
    "--bind-address=0.0.0.0",
    "--advertise-address=127.0.0.1"
  ]

  networks_advanced {
    name = var.network_name
  }

  # Ports dynamiques pour éviter les conflits
  ports {
    internal = 6443
    external = 6443 + count.index   # 6443, 6444, 6445...
  }

  ports {
    internal = 80
    external = 8080 + count.index
  }

  restart    = "unless-stopped"
  privileged = true
}

# === K3s Workers ===
resource "docker_container" "k3s_worker" {
  count = var.worker_count

  name  = "${var.project_name}-worker-${count.index}"
  image = "rancher/k3s:${var.k3s_version}"

  command = [
    "agent",
    "--server=https://${var.project_name}-server-0:6443",
    "--token=${var.k3s_token}",
    "--node-name=worker-${count.index}"
  ]

  networks_advanced {
    name = var.network_name
  }

  restart    = "unless-stopped"
  privileged = true
}
