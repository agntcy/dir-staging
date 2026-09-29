provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  alias                  = "public"
  host                   = "https://${module.public_cluster.endpoint}"
  cluster_ca_certificate = base64decode(module.public_cluster.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  alias = "public"
  kubernetes {
    host                   = "https://${module.public_cluster.endpoint}"
    cluster_ca_certificate = base64decode(module.public_cluster.cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubectl" {
  alias                  = "public"
  host                   = "https://${module.public_cluster.endpoint}"
  cluster_ca_certificate = base64decode(module.public_cluster.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}
