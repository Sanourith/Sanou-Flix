terraform {
  required_version = ">= 1.5"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    null = {
      source  = "hashicorp/null"
      version = "~>3.2"
    }
  }
}

# ========================================
# CLUSTER
# ========================================

resource "kind_cluster" "sanouflix" {
  name = var.cluster_name

  kind_config {
    api_version = "kind.x-k8s.io/v1alpha4"
    kind        = "Cluster"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
  wait_for_ready = true
}


# ========================================
# PROVIDERS
# ========================================

provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.default.endpoint
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
  }
}

# ========================================
# STORAGE
# ========================================

resource "null_resource" "rancher_local_path" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
      sleep 10
      kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    EOT
  }
  depends_on = [kind_cluster.sanouflix]
}

# ========================================
# NAMESPACES
# ========================================

resource "kubernetes_namespace" "sanouflix" {
  metadata {
    name = var.namespace_name
    labels = {
      name = "Sanou-Flix"
      env = "local"
      managed = "terraform"
    }
  }
  depends_on = [kind_cluster.sanouflix]
}

# ========================================
# NETWORKING
# ========================================

# Load Balancer
resource "helm_release" "metallb" {
  chart      = "metallb"
  name       = "metallb"
  namespace  = "metallb-system"
  repository = "https://metallb.github.io/metallb"
  version    = "0.14.3"

  create_namespace = true
  wait             = true
  timeout          = 300

  depends_on = [kind_cluster.netflix]
}

# Waiting for metallb to be ready
resource "null_resource" "wait_for_metallb" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [helm_release.metallb]
}

resource "null_resource" "metallb_ippool" {
  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: metallb.io/v1beta1
      kind: IPAddressPool
      metadata:
        name: sanouflix-pool
        namespace: metallb-system
      spec:
        addresses:
        - 172.18.100.100-172.18.100.150
      EOF
    EOT
  }

  depends_on = [null_resource.wait_for_metallb]
}

resource "null_resource" "metallb_l2" {
  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: metallb.io/v1beta1
      kind: L2Advertisement
      metadata:
        name: default
        namespace: metallb-system
      spec:
        ipAddressPools:
        - default-pool
      EOF
    EOT
  }

  depends_on = [null_resource.metallb_ippool]
}

# Ingress Controller
resource "helm_release" "nginx_ingress" {
  chart      = "ingress-nginx"
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.9.0"

  create_namespace = true
  wait = true
  timeout = 300

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  depends_on = [null_resource.metallb_l2]
}

# ========================================
# DATABASE
# ========================================
resource "kubernetes_config_map" "postgres_init" {
  metadata {
    name      = "postgres-init-script"
    namespace = kubernetes_namespace.netflix.metadata[0].name
  }

  data = {
    "init.sql" = <<-EOT
      -- Création de la base si elle n'existe pas
      CREATE DATABASE IF NOT EXISTS ${var.postgres_db};

      -- Tables de base pour les médias
      CREATE TABLE IF NOT EXISTS media (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        duration INTEGER,
        size_bytes BIGINT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS metadata (
        id SERIAL PRIMARY KEY,
        media_id INTEGER REFERENCES media(id) ON DELETE CASCADE,
        genre VARCHAR(100),
        year INTEGER,
        description TEXT,
        rating DECIMAL(3,1)
      );

      CREATE INDEX idx_media_type ON media(type);
      CREATE INDEX idx_media_title ON media(title);
    EOT
  }

  depends_on = [kubernetes_namespace.netflix]
}

resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.sanouflix.metadata[0].name
  version    = "13.2.24"

  values = [
    file("${path.module}/../../helm/postgres/dev/values.yaml")
  ]

  timeout = 600  # ← 10 minutes au lieu de 5
  wait    = true
  wait_for_jobs = true

  depends_on = [
    kubernetes_namespace.sanouflix,
    null_resource.rancher_local_path
  ]

}

# ========================================
# QUOTAS
# ========================================

resource "kubernetes_resource_quota" "app_quota" {
  metadata {
    name      = "app-quota"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "6"
      "requests.memory" = "12Gi"
      "limits.cpu"      = "12"
      "limits.memory"   = "24Gi"
    }
  }

  depends_on = [kubernetes_namespace.app]
}