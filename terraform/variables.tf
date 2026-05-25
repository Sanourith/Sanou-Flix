# terraform/variables.tf

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "k3s-cluster"
}

variable "k3s_version" {
  description = "Version de K3s"
  type        = string
  default     = "v1.31.1-k3s1"
}

variable "server_count" {
  description = "Nombre de serveurs (master)"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Nombre de workers"
  type        = number
  default     = 3
}

variable "k3s_token" {
  description = "Token secret pour joindre les nodes au cluster"
  type        = string
  sensitive   = true
  default     = "mySuperSecretToken123!"   # À changer en production
}
