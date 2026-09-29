output "trust_domain" {
  description = "Echoed back so peers can wire it without re-reading their own vars."
  value       = var.trust_domain
}

output "bundle_endpoint_url" {
  description = "https URL the bundle endpoint is reachable at. For 'spiffe' mode, an IP:8443. For 'web' mode, a port-443 FQDN whose format depends on dns_mode (nip-io: 'dir-<cluster>.<ip>.nip.io'; managed: 'dir.<cluster>.<base_domain>')."
  value       = local.bundle_endpoint_url
}

output "endpoint_spiffe_id" {
  description = "Federation endpoint's SPIFFE ID. Only meaningful in 'spiffe' mode, but always populated for symmetry."
  value       = local.endpoint_spiffe_id
}

output "reserved_ip" {
  description = "The federation endpoint's reserved static IP. Useful for debugging."
  value       = local.reserved_ip
}

output "federation_fqdn" {
  description = "Bare FQDN of the federation bundle endpoint in 'web' mode. Format depends on dns_mode: nip-io produces 'dir-<cluster>.<ip>.<base_domain>'; managed produces 'dir.<cluster>.<base_domain>'. Empty string in 'spiffe' mode. Consumed by dir-node to derive its own per-service subdomains (api.*, zot.*)."
  value       = var.federation_tls_mode == "web" ? local.fqdn : ""
}

output "oidc_discovery_url" {
  description = "OIDC discovery provider URL for JWT-SVID federation. Only available in 'web' mode with OIDC discovery enabled."
  value       = var.federation_tls_mode == "web" ? "https://oidc-discovery.${local.fqdn}" : ""
}
