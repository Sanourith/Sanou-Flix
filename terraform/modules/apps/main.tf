# === PostgreSQL ===
resource "helm_release" "postgresql" {
  name             = "postgresql"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  namespace        = "database"
  create_namespace = true

  values = [file("${path.root}/../helm/postgresql/values.yaml")]

  # set = {
  #   name  = "auth.postgresPassword"
  #   value = var.postgres_password
  # }
}

# === Prometheus Stack (inclut Grafana) ===
resource "helm_release" "kube_prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [file("${path.root}/../helm/prometheus/values.yaml")]

  # Timeout élevé car le chart est lourd
  timeout = 600
}
