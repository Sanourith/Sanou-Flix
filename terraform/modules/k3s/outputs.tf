output "server_names" {
  value = [for c in docker_container.k3s_server : c.name]
}

output "worker_names" {
  value = [for c in docker_container.k3s_worker : c.name]
}

# output "kubeconfig" {
#   description = "Kubeconfig patché pour accès depuis le host"
#   value = replace(
#     docker_container.k3s_server[0].env_variable["KUBECONFIG_DATA"],
#     "https://127.0.0.1:6443",
#     "https://localhost:6443"
#   )
#   sensitive = true
# }

output "kubeconfig" {
  value = sensitive(
    <<-EOT
    apiVersion: v1
    clusters:
    - cluster:
        server: https://localhost:6443
      name: ${var.project_name}
    contexts:
    - context:
        cluster: ${var.project_name}
        user: admin
      name: ${var.project_name}
    current-context: ${var.project_name}
    users:
    - name: admin
      user:
        token: ${var.k3s_token}
    EOT
  )
}
