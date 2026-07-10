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
  external_dns_gsa_email = var.external_dns_gsa_email
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

resource "local_file" "federation_config" {
  content = templatefile("${path.module}/federation-config.yaml.tftpl", {
    trust_domain        = module.public_spire.trust_domain
    bundle_endpoint_url = module.public_spire.bundle_endpoint_url
  })
  filename = "${path.module}/federation-config.yaml"
}