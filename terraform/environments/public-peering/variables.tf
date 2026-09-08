variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "us-east1"
}

variable "machine_type" {
  description = "Machine type for GKE cluster nodes. Default 'e2-medium' (2 vCPU, 4 GB RAM). For production, consider 'e2-standard-4' (4 vCPU, 16 GB RAM)."
  type        = string
  default     = "e2-medium"
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "spire-public"
}

variable "acme_email" {
  description = "Email registered with Let's Encrypt."
  type        = string
}

variable "public_trust_domain" {
  description = "SPIRE trust domain. Federation peers identify us by this trust domain name."
  type        = string
  default     = "example.agntcy.testbed"
}

variable "base_domain" {
  description = "Public DNS suffix owned by Dell, with its Cloud DNS managed zone in var.dns_project_id. Example: 'agntcy-research-dell.com'."
  type        = string
}

variable "dns_project_id" {
  description = "GCP project ID hosting the Cloud DNS managed zone. Distinct from var.project_id."
  type        = string
}

variable "dns_zone_name" {
  description = "Cloud DNS managed zone resource name in var.dns_project_id (not the domain)."
  type        = string
}

variable "external_dns_gsa_email" {
  description = "Pre-provisioned GSA with roles/dns.admin on the zone. If empty, the GSA will be created automatically using external_dns_gsa_name."
  type        = string
  default     = ""
}

variable "external_dns_gsa_name" {
  description = "Name of the ExternalDNS Google Service Account to create when external_dns_gsa_email is empty."
  type        = string
  default     = "external-dns"
}

variable "cluster_name" {
  description = "Short logical name for the cluster. Used in resource names and the dir namespace."
  type        = string
  default     = "public"
}

variable "dir_chart_version" {
  description = "AGNTCY dir umbrella chart version. v1.6.1 is current stable as of 2026-07-27. The apiserver image tag (ghcr.io/agntcy/dir-apiserver) tracks this value 1:1."
  type        = string
  default     = "v1.6.1"
}

variable "zot_pvc_size" {
  description = "Zot OCI registry storage volume size."
  type        = string
  default     = "50Gi"
}

variable "http_gateway_enabled" {
  description = "Enable the HTTP gateway and embedded AI Catalog UI."
  type        = bool
  default     = false
}

variable "http_gateway_catalog_title" {
  description = "Display title for the embedded AI Catalog UI."
  type        = string
  default     = "AI Catalog"
}

variable "federates_with" {
  description = "List of trust domains to federate with via SPIRE. These are configured in SPIRE's controllerManager.identities.clusterSPIFFEIDs.default.federatesWith field."
  type        = list(string)
  default     = []
}

variable "dir_federation_peers" {
  description = "List of DIR-level federation peers to configure in the DIR apiserver. Each peer should have className, trustDomain, bundleEndpointURL, and bundleEndpointProfile with type. Example: [{ className = \"dir-spire\", trustDomain = \"spire.ads.outshift.io\", bundleEndpointURL = \"https://spire.ads.outshift.io\", bundleEndpointProfile = { type = \"https_web\" } }]"
  type = list(object({
    className         = string
    trustDomain       = string
    bundleEndpointURL = string
    bundleEndpointProfile = object({
      type = string
    })
  }))
  default = []
}

variable "dir_routing_bootstrap_peers" {
  description = "Routing bootstrap peers for the DIR node. If empty, uses the Outshift testbed bootstrap."
  type        = list(string)
  default     = []
}

variable "routing_autosync_enabled" {
  description = "Enable DHT-based record + referrer autosync. When enabled, only records announced by a peer in peerlist are pulled and ingested locally."
  type        = bool
  default     = false
}

variable "routing_autosync_peerlist" {
  description = "List of trusted source peers (by libp2p peer ID) for autosync. Only used when routing_autosync_enabled is true."
  type        = list(string)
  default     = []
}

variable "authz_policies_csv" {
  description = "Authorization policies in CSV format for the DIR apiserver. These policies control which trust domains can access which services. If not specified, sensible defaults will be used that allow federation (local trust domain gets full access, federated peers get limited access to Pull, PullReferrer, Lookup, and RequestRegistryCredentials services)."
  type        = string
  default     = ""
}

variable "reconciler_enabled" {
  description = "Enable the DIR reconciler for synchronization with federated peers. The reconciler pulls records from trusted directories and syncs OCI registry content. Defaults to true for federation support."
  type        = bool
  default     = true
}

variable "reconciler_image_tag" {
  description = "DIR reconciler image tag. Should match the DIR chart version for compatibility. Defaults to match dir_chart_version."
  type        = string
  default     = ""
}

variable "reconciler_regsync_enabled" {
  description = "Enable OCI registry synchronization via regsync. Defaults to true for federation support."
  type        = bool
  default     = true
}

variable "reconciler_regsync_interval" {
  description = "Interval for regsync to check for registry updates (e.g., '1m', '5m'). Defaults to '1m' based on AGNTCY recommendations."
  type        = string
  default     = "1m"
}

variable "reconciler_regsync_timeout" {
  description = "Timeout for regsync operations (e.g., '30m'). Defaults to '30m' based on AGNTCY recommendations."
  type        = string
  default     = "30m"
}

variable "reconciler_indexer_enabled" {
  description = "Enable the reconciler indexer for building search indexes. Defaults to true for federation support."
  type        = bool
  default     = true
}

variable "reconciler_indexer_interval" {
  description = "Interval for the indexer to rebuild search indexes (e.g., '30m', '1h'). Defaults to '30m' based on AGNTCY recommendations."
  type        = string
  default     = "30m"
}

variable "reconciler_regsync_authn_mode" {
  description = "Authentication mode for regsync remote directory connections: x509, jwt, or jwt-tls."
  type        = string
  default     = "x509"
}

variable "reconciler_regsync_authn_socket_path" {
  description = "SPIFFE Workload API socket path used by regsync for x509, jwt, or jwt-tls auth."
  type        = string
  default     = "unix:///run/spire/agent-sockets/api.sock"
}

variable "reconciler_regsync_authn_audiences" {
  description = "Expected JWT audiences for regsync (required for jwt and jwt-tls modes)."
  type        = list(string)
  default     = []
}

# OIDC Gateway configuration
variable "oidc_gateway_enabled" {
  description = "Enable OIDC gateway deployment for user authentication."
  type        = bool
  default     = false
}

variable "oidc_gateway_chart_version" {
  description = "OIDC gateway Helm chart version."
  type        = string
  default     = "v1.1.2"
}

variable "oidc_github_enabled" {
  description = "Enable GitHub OIDC provider for GitHub Actions authentication."
  type        = bool
  default     = true
}

variable "oidc_google_enabled" {
  description = "Enable Google OIDC provider for Google OAuth authentication."
  type        = bool
  default     = true
}

variable "oidc_google_audiences" {
  description = "Google OIDC token audiences to accept."
  type        = list(string)
  default     = ["32555940559.apps.googleusercontent.com"]
}

variable "oidc_admin_principals" {
  description = "List of principals with admin access (full permissions). Principals should be in format 'oidc:github:user' or 'spiffe:...'."
  type        = list(string)
  default     = []
}

variable "oidc_viewer_principals" {
  description = "List of principals with viewer access (read-only permissions). Defaults to all authenticated users."
  type        = list(string)
  default     = ["*"]
}

variable "oidc_ci_writer_principals" {
  description = "List of principals with CI writer access (push/pull/search permissions)."
  type        = list(string)
  default     = []
}

variable "oidc_ingress_enabled" {
  description = "Enable ingress for external access to the OIDC gateway."
  type        = bool
  default     = true
}

variable "oidc_jwt_svid_allow_missing_or_failed" {
  description = "Allow Envoy to pass JWTs that don't match an OIDC provider to ext_authz for SPIFFE JWT-SVID validation."
  type        = bool
  default     = false
}

variable "oidc_spiffe_jwt_enabled" {
  description = "Enable SPIFFE JWT-SVID validation in the OIDC gateway authz server."
  type        = bool
  default     = false
}

variable "oidc_spiffe_jwt_socket_path" {
  description = "SPIFFE Workload API socket path for the OIDC gateway authz server."
  type        = string
  default     = "unix:///run/spire/agent-sockets/api.sock"
}

variable "oidc_spiffe_jwt_audiences" {
  description = "Expected audiences for SPIFFE JWT-SVID validation in the OIDC gateway authz server."
  type        = list(string)
  default     = []
}

variable "oidc_spiffe_jwt_federates_with" {
  description = "Federated trust domains for the OIDC gateway authz-server ClusterSPIFFEID."
  type        = list(string)
  default     = []
}