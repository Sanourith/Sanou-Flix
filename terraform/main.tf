# terraform/main.tf

module "network" {
  source = "./modules/network"

  project_name = var.project_name
}

module "k3s" {
  source = "./modules/k3s"

  project_name = var.project_name
  k3s_version  = var.k3s_version
  server_count = var.server_count
  worker_count = var.worker_count
  k3s_token    = var.k3s_token
  network_name = module.network.network_name
}

# Génère le fichier kubeconfig automatiquement
resource "local_file" "kubeconfig" {
  content  = module.k3s.kubeconfig
  filename = "${path.module}/kubeconfig.yaml"
}

module "apps" {
  source = "./modules/apps"

  depends_on = [module.k3s, local_file.kubeconfig]

  # postgres_password = var.postgres_password
}
