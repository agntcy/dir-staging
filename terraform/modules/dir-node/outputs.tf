output "namespace" {
  description = "Kubernetes namespace where the dir chart is installed."
  value       = var.namespace
}

output "api_url" {
  description = "Public HTTPS URL of the DIR API (SSL passthrough, SPIFFE mTLS at backend)."
  value       = "https://${local.api_fqdn}"
}

output "zot_url" {
  description = "Public HTTPS URL of the Zot OCI registry (LE cert, htpasswd auth)."
  value       = "https://${local.zot_fqdn}"
}

output "routing_url" {
  description = "Public P2P routing endpoint (LoadBalancer TCP 5555 for federation peer discovery)."
  value       = "${local.routing_fqdn}:5555"
}

output "credentials_secret_name" {
  description = "Name of the K8s secret holding postgres-password + zot-htpasswd."
  value       = local.credentials_secret_name
}
