# Create ExternalDNS GSA and IAM bindings if external_dns_gsa_email is not provided
resource "google_service_account" "external_dns" {
  count        = var.external_dns_gsa_email == "" ? 1 : 0
  account_id   = var.external_dns_gsa_name
  display_name = "ExternalDNS Service Account"
  project      = var.dns_project_id
}

resource "google_project_iam_binding" "external_dns_dns_admin" {
  count   = var.external_dns_gsa_email == "" ? 1 : 0
  project = var.dns_project_id
  role    = "roles/dns.admin"

  members = [
    "serviceAccount:${google_service_account.external_dns[0].email}",
  ]
}

resource "google_service_account_iam_binding" "external_dns_workload_identity" {
  count              = var.external_dns_gsa_email == "" ? 1 : 0
  service_account_id = google_service_account.external_dns[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]",
  ]
}

# Use the provided GSA email or the created one
locals {
  external_dns_gsa_email = var.external_dns_gsa_email != "" ? var.external_dns_gsa_email : ""
}

module "public_cluster" {
  source       = "../../modules/gke-cluster"
  project_id   = var.project_id
  region       = var.region
  cluster_name = var.gke_cluster_name
  machine_type = var.machine_type
}

data "google_client_config" "default" {}

module "public_spire" {
  source                 = "../../modules/spire-node"
  project_id             = var.project_id
  region                 = var.region
  cluster_name           = var.cluster_name
  trust_domain           = var.public_trust_domain
  federation_tls_mode    = "web"
  acme_email             = var.acme_email
  dns_mode               = "managed"
  base_domain            = var.base_domain
  dns_project_id         = var.dns_project_id
  dns_zone_name          = var.dns_zone_name
  external_dns_gsa_email = try(local.external_dns_gsa_email != "" ? local.external_dns_gsa_email : google_service_account.external_dns[0].email, local.external_dns_gsa_email)
  federates_with         = var.federates_with

  providers = {
    kubernetes = kubernetes.public
    helm       = helm.public
    kubectl    = kubectl.public
  }
}

module "public_dir" {
  source                      = "../../modules/dir-node"
  project_id                  = var.project_id
  region                      = var.region
  cluster_name                = var.cluster_name
  dir_chart_version           = var.dir_chart_version
  zot_pvc_size                = var.zot_pvc_size
  federation_peers            = var.dir_federation_peers
  authz_policies_csv          = var.authz_policies_csv
  routing_bootstrap_peers     = var.dir_routing_bootstrap_peers
  routing_autosync_enabled    = var.routing_autosync_enabled
  routing_autosync_peerlist   = var.routing_autosync_peerlist
  reconciler_enabled          = var.reconciler_enabled
  reconciler_image_tag        = var.reconciler_image_tag != "" ? var.reconciler_image_tag : var.dir_chart_version
  reconciler_regsync_enabled  = var.reconciler_regsync_enabled
  reconciler_regsync_interval = var.reconciler_regsync_interval
  reconciler_regsync_timeout  = var.reconciler_regsync_timeout
  reconciler_indexer_enabled  = var.reconciler_indexer_enabled
  reconciler_indexer_interval = var.reconciler_indexer_interval

  trust_domain = module.public_spire.trust_domain
  base_fqdn    = module.public_spire.federation_fqdn

  acme_email = var.acme_email

  providers = {
    kubernetes = kubernetes.public
    helm       = helm.public
    kubectl    = kubectl.public
  }

  depends_on = [module.public_spire]
}

module "public_oidc_gateway" {
  count                  = var.oidc_gateway_enabled ? 1 : 0
  source                 = "../../modules/oidc-gateway"
  project_id             = var.project_id
  region                 = var.region
  cluster_name           = var.cluster_name
  base_fqdn              = module.public_spire.federation_fqdn
  dir_backend_address    = "dir-apiserver.dir.svc.cluster.local"
  trust_domain           = module.public_spire.trust_domain
  className              = "dir-spire"
  chart_version          = var.oidc_gateway_chart_version
  acme_email             = var.acme_email
  github_enabled         = var.oidc_github_enabled
  google_enabled         = var.oidc_google_enabled
  google_audiences       = var.oidc_google_audiences
  admin_principals       = var.oidc_admin_principals
  viewer_principals      = var.oidc_viewer_principals
  ci_writer_principals   = var.oidc_ci_writer_principals
  ingress_enabled        = var.oidc_ingress_enabled

  providers = {
    kubernetes = kubernetes.public
    helm       = helm.public
  }

  depends_on = [module.public_dir]
}

resource "local_file" "federation_config" {
  content = templatefile("${path.module}/federation-config.yaml.tftpl", {
    trust_domain        = module.public_spire.trust_domain
    bundle_endpoint_url = module.public_spire.bundle_endpoint_url
  })
  filename = "${path.module}/federation-config.yaml"
}