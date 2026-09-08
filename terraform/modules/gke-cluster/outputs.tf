output "get_credentials_command" {
  description = "Run this to populate the kubectl context for the cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gke.name} --region ${google_container_cluster.gke.location} --project ${var.project_id}"
}

output "endpoint" {
  description = "API server endpoint for the cluster."
  value       = google_container_cluster.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  sensitive   = true
}
