output "postgresql_service_name" {
  description = "Nom du service Kubernetes PostgreSQL (DNS interne au cluster)"
  value       = "${helm_release.postgresql.name}-postgresql.${helm_release.postgresql.namespace}.svc.cluster.local"
}

output "postgresql_port" {
  description = "Port PostgreSQL"
  value       = 5432
}

output "postgresql_database" {
  description = "Nom de la base de données"
  value       = var.postgres_db
}

output "postgresql_user" {
  description = "Utilisateur applicatif"
  value       = var.postgres_user
}

output "postgresql_connection_string" {
  description = "Connection string (sans mot de passe)"
  value       = "postgresql://${var.postgres_user}@${helm_release.postgresql.name}-postgresql.${helm_release.postgresql.namespace}.svc.cluster.local:5432/${var.postgres_db}"
}
