output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

output "server_containers" {
  value = module.k3s.server_names
}

output "worker_containers" {
  value = module.k3s.worker_names
}
