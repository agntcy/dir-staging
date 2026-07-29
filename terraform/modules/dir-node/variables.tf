variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "cluster_name" {
  description = "Short logical name for the cluster. Used in resource names and the dir namespace."
  type        = string
}

variable "trust_domain" {
  description = "SPIRE trust domain this dir node operates under (e.g. 'dell.agntcy.testbed')."
  type        = string
}

variable "base_fqdn" {
  description = "Base FQDN inherited from spire-node's federation_fqdn. Format depends on spire-node's dns_mode: nip-io produces e.g. 'dir-testbed.<ip>.nip.io'; managed produces e.g. 'dir.public.agntcy-research-dell.com'. Per-service hostnames are derived as '<service>.<base_fqdn>'."
  type        = string

  validation {
    condition     = length(var.base_fqdn) > 0
    error_message = "base_fqdn must be non-empty. dir-node only supports web-mode federation (spire-node must be in federation_tls_mode='web')."
  }
}

variable "acme_email" {
  description = "Email registered with Let's Encrypt. The ClusterIssuer 'letsencrypt-prod' is provisioned by spire-node and reused here."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the dir release."
  type        = string
  default     = "dir"
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

variable "federation_peers" {
  description = "List of federation peers to configure in the DIR apiserver. Each peer should have className, trustDomain, bundleEndpointURL, and bundleEndpointProfile with type. Example: [{ className = \"dir-spire\", trustDomain = \"spire.ads.outshift.io\", bundleEndpointURL = \"https://spire.ads.outshift.io\", bundleEndpointProfile = { type = \"https_web\" } }]"
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
  description = "Authorization policies in CSV format for the DIR apiserver. These policies control which trust domains can access which services. For federation, include policies that allow federated peers to access Pull, PullReferrer, Lookup, and RequestRegistryCredentials services."
  type        = string
  default     = ""
}

variable "routing_bootstrap_peers" {
  description = "List of libp2p multiaddrs for routing bootstrap peers. If empty, the Outshift testbed bootstrap peer is used."
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

variable "reconciler_enabled" {
  description = "Enable the DIR reconciler for synchronization with federated peers. The reconciler pulls records from trusted directories and syncs OCI registry content."
  type        = bool
  default     = true
}

variable "reconciler_image_tag" {
  description = "DIR reconciler image tag. Should match the DIR chart version for compatibility."
  type        = string
  default     = "v1.5.0"
}

variable "reconciler_regsync_enabled" {
  description = "Enable OCI registry synchronization via regsync."
  type        = bool
  default     = true
}

variable "reconciler_regsync_interval" {
  description = "Interval for regsync to check for registry updates (e.g., '1m', '5m')."
  type        = string
  default     = "1m"
}

variable "reconciler_regsync_timeout" {
  description = "Timeout for regsync operations (e.g., '30m')."
  type        = string
  default     = "30m"
}

variable "reconciler_indexer_enabled" {
  description = "Enable the reconciler indexer for building search indexes."
  type        = bool
  default     = true
}

variable "reconciler_indexer_interval" {
  description = "Interval for the indexer to rebuild search indexes (e.g., '30m', '1h')."
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
