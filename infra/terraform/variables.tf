variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "local-k8s-cluster"
}

variable "app_replicas" {
  description = "Number of application pods"
  type        = number
  default     = 2
}

variable "db_password" {
  description = "PostgreSQL password"
  sensitive   = true
  type        = string
  default     = "password"
}
