variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "base_fqdn" {
  description = "Base FQDN for the gateway (e.g., dir.dev.example.com -> gateway.dir.dev.example.com)."
  type        = string
}

variable "dir_backend_address" {
  description = "Address of the Directory API server backend."
  type        = string
  default     = "dir-apiserver.dir.svc.cluster.local"
}

variable "dir_backend_port" {
  description = "Port of the Directory API server backend."
  type        = number
  default     = 8888
}

variable "trust_domain" {
  description = "SPIRE trust domain for SPIFFE authentication."
  type        = string
}

variable "className" {
  description = "SPIRE class name for SPIFFE authentication."
  type        = string
  default     = "dir-spire"
}

variable "chart_version" {
  description = "OIDC gateway Helm chart version."
  type        = string
  default     = "v1.0.0"
}

# GitHub OIDC provider configuration
variable "github_enabled" {
  description = "Enable GitHub OIDC provider for GitHub Actions authentication."
  type        = bool
  default     = true
}

variable "github_issuer" {
  description = "GitHub OIDC issuer URL."
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_jwks_uri" {
  description = "GitHub JWKS endpoint for token validation."
  type        = string
  default     = "https://token.actions.githubusercontent.com/.well-known/jwks"
}

variable "github_jwks_host" {
  description = "GitHub JWKS host for token validation."
  type        = string
  default     = "token.actions.githubusercontent.com"
}

variable "github_audiences" {
  description = "GitHub OIDC token audiences to accept."
  type        = list(string)
  default     = ["dir"]
}

# Google OIDC provider configuration
variable "google_enabled" {
  description = "Enable Google OIDC provider for Google OAuth authentication."
  type        = bool
  default     = true
}

variable "google_issuer" {
  description = "Google OIDC issuer URL."
  type        = string
  default     = "https://accounts.google.com"
}

variable "google_jwks_uri" {
  description = "Google JWKS endpoint for token validation."
  type        = string
  default     = "https://www.googleapis.com/oauth2/v3/certs"
}

variable "google_jwks_host" {
  description = "Google JWKS host for token validation."
  type        = string
  default     = "www.googleapis.com"
}

variable "google_audiences" {
  description = "Google OIDC token audiences to accept."
  type        = list(string)
  default     = ["32555940559.apps.googleusercontent.com"]
}

# Custom OIDC providers
variable "custom_issuers" {
  description = "List of custom OIDC providers with issuer, jwks_uri, and jwks_host."
  type = list(object({
    name      = string
    enabled   = bool
    issuer    = string
    jwks_uri  = string
    jwks_host = string
  }))
  default = []
}

# RBAC configuration
variable "admin_principals" {
  description = "List of principals with admin access (full permissions). Principals should be in format 'oidc:provider:user' or 'spiffe:...'."
  type        = list(string)
  default     = []
}

variable "viewer_principals" {
  description = "List of principals with viewer access (read-only permissions)."
  type        = list(string)
  default     = []
}

variable "ci_writer_principals" {
  description = "List of principals with CI writer access (push/pull/search permissions)."
  type        = list(string)
  default     = []
}

# Ingress configuration
variable "ingress_enabled" {
  description = "Enable ingress for external access to the OIDC gateway."
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class to use for the gateway."
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Additional annotations for the ingress resource."
  type        = map(string)
  default     = {}
}

variable "acme_email" {
  description = "Email for Let's Encrypt certificate generation."
  type        = string
}

# Resource configuration
variable "envoy_replica_count" {
  description = "Number of Envoy replicas."
  type        = number
  default     = 1
}

variable "auth_server_replica_count" {
  description = "Number of auth server replicas."
  type        = number
  default     = 1
}