resource "helm_release" "postgres" {
  name       = "postgres"
  namespace  = kubernetes_namespace.sanouflix.metadata[0].name
  chart      = "${path.root}/../helm/postgres"
  values     = [file("${path.root}/../helm/postgres/dev/values.yaml")]

  timeout    = 300
  cleanup_on_fail = true
  dependency_update = true
}
