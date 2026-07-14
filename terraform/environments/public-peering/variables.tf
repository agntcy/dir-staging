variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "us-central1"
}

variable "machine_type" {
  description = "Machine type for GKE cluster nodes. Default 'e2-standard-4' (4 vCPU, 16 GB RAM). For development, consider 'e2-standard-2' (2 vCPU, 8 GB RAM)."
  type        = string
  default     = "e2-standard-4"
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
  description = "AGNTCY dir umbrella chart version. v1.3.0 is current stable as of 2026-05-13. The apiserver image tag (ghcr.io/agntcy/dir-apiserver) tracks this value 1:1."
  type        = string
  default     = "v1.5.0"
}

variable "zot_pvc_size" {
  description = "Zot OCI registry storage volume size."
  type        = string
  default     = "50Gi"
}

variable "federates_with" {
  description = "List of trust domains to federate with via SPIRE. These are configured in SPIRE's controllerManager.identities.clusterSPIFFEIDs.default.federatesWith field. Example: [\"spire.ads.outshift.io\"] for production public directory."
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