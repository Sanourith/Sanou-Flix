variable "postgres_password" {
  description = "Mot de passe du superuser PostgreSQL"
  type        = string
  sensitive   = true
  default = "superMDP"
}

variable "postgres_db" {
  description = "Nom de la base de données par défaut"
  type        = string
  default     = "appdb"
}

variable "postgres_user" {
  description = "Nom de l'utilisateur applicatif"
  type        = string
  default     = "appuser"
}

variable "postgres_storage_size" {
  description = "Taille du volume persistant PostgreSQL"
  type        = string
  default     = "5Gi"
}

variable "postgres_namespace" {
  description = "Namespace Kubernetes pour PostgreSQL"
  type        = string
  default     = "database"
}
