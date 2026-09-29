locals {
  namespace    = "oidc-gateway"
  gateway_fqdn = "gateway.${var.base_fqdn}"
}

# Create the namespace for OIDC gateway
resource "kubernetes_namespace" "namespace" {
  metadata {
    name = local.namespace
  }
}

locals {
  oidc_gateway_values = templatefile("${path.module}/values/oidc-gateway.yaml.tftpl", {
    namespace           = local.namespace
    gateway_fqdn        = local.gateway_fqdn
    dir_backend_address = var.dir_backend_address
    dir_backend_port    = var.dir_backend_port
    trust_domain        = var.trust_domain
    className           = var.className

    # OIDC providers configuration
    github_enabled   = var.github_enabled
    github_issuer    = var.github_issuer
    github_jwks_uri  = var.github_jwks_uri
    github_jwks_host = var.github_jwks_host
    github_audiences = var.github_audiences

    google_enabled   = var.google_enabled
    google_issuer    = var.google_issuer
    google_jwks_uri  = var.google_jwks_uri
    google_jwks_host = var.google_jwks_host
    google_audiences = var.google_audiences

    # Custom OIDC providers
    custom_issuers = var.custom_issuers

    # RBAC configuration
    admin_principals     = var.admin_principals
    viewer_principals    = var.viewer_principals
    ci_writer_principals = var.ci_writer_principals

    # Ingress configuration
    ingress_enabled     = var.ingress_enabled
    ingress_class       = var.ingress_class
    ingress_annotations = var.ingress_annotations
    acme_email          = var.acme_email

    # Resource configuration
    envoy_replica_count       = var.envoy_replica_count
    auth_server_replica_count = var.auth_server_replica_count
    chart_version             = var.chart_version

    # JWT-SVID configuration
    jwt_svid_allow_missing_or_failed      = var.jwt_svid_allow_missing_or_failed
    auth_server_spiffe_jwt_enabled        = var.auth_server_spiffe_jwt_enabled
    auth_server_spiffe_jwt_socket_path    = var.auth_server_spiffe_jwt_socket_path
    auth_server_spiffe_jwt_audiences      = var.auth_server_spiffe_jwt_audiences
    auth_server_spiffe_jwt_federates_with = var.auth_server_spiffe_jwt_federates_with
  })
}

resource "helm_release" "oidc_gateway" {
  name             = "oidc-gateway"
  namespace        = local.namespace
  create_namespace = false # we own the namespace via kubernetes_namespace

  repository = "oci://ghcr.io/agntcy/oidc-gateway/helm-charts"
  chart      = "oidc-gateway"
  version    = var.chart_version

  values = [local.oidc_gateway_values]

  timeout          = 600
  wait             = true
  wait_for_jobs    = false
  cleanup_on_fail  = true
  disable_webhooks = true

  depends_on = [
    kubernetes_namespace.namespace,
  ]
}