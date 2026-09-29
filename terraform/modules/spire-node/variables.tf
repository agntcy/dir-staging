variable "project_id" {
  description = "GCP project ID. Required for reserving the static IP."
  type        = string
}

variable "region" {
  description = "GCP region for the static IP reservation."
  type        = string
}

variable "cluster_name" {
  description = "Short logical name for the cluster. Used as Helm release suffix, SPIRE clusterName, and the FQDN's leftmost label (web mode)."
  type        = string
}

variable "trust_domain" {
  description = "SPIRE trust domain (e.g., 'example.agntcy.testbed')."
  type        = string
}

variable "federation_tls_mode" {
  description = "TLS profile served by this node's federation bundle endpoint. 'spiffe' = mutual SPIFFE-mTLS. 'web' = web PKI via Let's Encrypt."
  type        = string
  validation {
    condition     = contains(["spiffe", "web"], var.federation_tls_mode)
    error_message = "federation_tls_mode must be either 'spiffe' or 'web'."
  }
}

variable "acme_email" {
  description = "Email registered with Let's Encrypt. Required iff federation_tls_mode = 'web'."
  type        = string
  default     = ""
}

variable "base_domain" {
  description = "Base domain for the federation FQDN in web mode. Default 'nip.io' uses the reserved static IP as the leftmost-but-one label, e.g. 'dir-<cluster>.<ip>.nip.io'. Swap for a real Dell-owned zone when one is available."
  type        = string
  default     = "nip.io"
}

variable "dns_mode" {
  description = "DNS provisioning mode. 'nip-io' = IP-embedded hostname via nip.io (current default; no DNS provider needed). 'managed' = Cloud DNS records via ExternalDNS for a real domain."
  type        = string
  default     = "nip-io"
  validation {
    condition     = contains(["nip-io", "managed"], var.dns_mode)
    error_message = "dns_mode must be either 'nip-io' or 'managed'."
  }
}

variable "dns_project_id" {
  description = "GCP project ID hosting the Cloud DNS managed zone. Distinct from var.project_id (the dir-deploy project) — DNS is a shared resource in another project. Required iff dns_mode = 'managed'."
  type        = string
  default     = ""
}

variable "dns_zone_name" {
  description = "Cloud DNS managed zone *resource name* (not the domain). Required iff dns_mode = 'managed'."
  type        = string
  default     = ""
}

variable "external_dns_gsa_email" {
  description = "Email of the pre-provisioned GSA with roles/dns.admin on the zone in var.dns_project_id. Created out-of-band along with the cross-project IAM grant (see env README pre-flight). Required iff dns_mode = 'managed'."
  type        = string
  default     = ""
}

variable "federates_with" {
  description = "List of trust domains to federate with. Each entry is a trust domain string (e.g., 'spire.ads.outshift.io'). These are configured in SPIRE's controllerManager.identities.clusterSPIFFEIDs.default.federatesWith field."
  type        = list(string)
  default     = []
}
