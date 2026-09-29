output "namespace" {
  description = "Namespace where the OIDC gateway is deployed."
  value       = "oidc-gateway"
}

output "gateway_fqdn" {
  description = "Fully qualified domain name of the OIDC gateway."
  value       = "gateway.${var.base_fqdn}"
}

output "gateway_url" {
  description = "URL of the OIDC gateway."
  value       = "https://gateway.${var.base_fqdn}"
}

output "dir_backend_address" {
  description = "Address of the Directory API server backend."
  value       = var.dir_backend_address
}

output "enabled_oidc_providers" {
  description = "List of enabled OIDC providers."
  value = compact([
    var.github_enabled ? "github" : "",
    var.google_enabled ? "google" : "",
  ])
}