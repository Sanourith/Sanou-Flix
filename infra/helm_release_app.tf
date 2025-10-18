resource "helm_release" "app" {
  name       = "sanouflix-app"
  namespace  = kubernetes_namespace.sanouflix.metadata[0].name
  chart      = "${path.root}/../helm/app"
  values     = [file("${path.root}/../helm/app/dev/values.yaml")]

  depends_on = [helm_release.postgres]
}
