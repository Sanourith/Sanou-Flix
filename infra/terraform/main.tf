terraform {
  required_version = ">= 1.5"

  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Installation of k3s via local script
resource "null_resource" "install_k3s" {
  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v k3s &> /dev/null; then
        echo "Installing k3s..."
        curl -sfL https://get.k3s.io | sh -s - \
          --write-kubeconfig-mode 644 \
          --disable traefik \
          --disable servicelb

        echo "Waiting for k3s..."
        sleep 15
      else
        echo "k3s is already installed"
      fi

      mkdir -p ~/.kube
      sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
      sudo chown $USER:$USER ~/.kube/config
      chmod 600 ~/.kube/config
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}