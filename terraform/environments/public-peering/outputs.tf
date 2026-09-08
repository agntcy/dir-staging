output "public_cluster_name" {
  value = var.gke_cluster_name
}

output "public_bundle_endpoint" {
  value = module.public_spire.bundle_endpoint_url
}

output "public_oidc_discovery_url" {
  description = "OIDC discovery provider endpoint for JWT-SVID federation."
  value       = module.public_spire.oidc_discovery_url
}

output "public_trust_domain" {
  value = module.public_spire.trust_domain
}

output "public_endpoint_spiffe_id" {
  value = module.public_spire.endpoint_spiffe_id
}

output "public_dir_api_url" {
  description = "DIR API endpoint (SPIFFE mTLS, SSL passthrough)."
  value       = module.public_dir.api_url
}

output "public_dir_zot_url" {
  description = "Zot OCI registry endpoint (LE cert, htpasswd auth)."
  value       = module.public_dir.zot_url
}

output "public_dir_catalog_url" {
  description = "AI Catalog UI endpoint (HTTP gateway)."
  value       = var.http_gateway_enabled ? module.public_dir.catalog_url : null
}

output "public_dir_routing_url" {
  description = "P2P routing endpoint (LoadBalancer TCP 5555 for federation peer discovery)."
  value       = module.public_dir.routing_url
}

output "public_dir_namespace" {
  description = "Kubernetes namespace of the dir release."
  value       = module.public_dir.namespace
}

output "get_credentials_command" {
  description = "Run this to populate the kubectl context for the cluster."
  value       = module.public_cluster.get_credentials_command
}

output "public_oidc_gateway_url" {
  description = "OIDC gateway endpoint for external user authentication."
  value       = var.oidc_gateway_enabled ? module.public_oidc_gateway[0].gateway_url : null
}

output "public_oidc_gateway_dirctl_example" {
  description = "Example dirctl command using OIDC gateway with Google authentication."
  value       = var.oidc_gateway_enabled ? "dirctl --server-addr ${module.public_oidc_gateway[0].gateway_fqdn}:443 --auth-token $(gcloud auth print-identity-token) search" : ""
}
