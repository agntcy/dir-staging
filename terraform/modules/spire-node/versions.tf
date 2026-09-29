terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    helm = {
      source                = "hashicorp/helm"
      version               = "~> 2.13"
      configuration_aliases = []
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "~> 2.30"
      configuration_aliases = []
    }
    # hashicorp/kubernetes' kubernetes_manifest reads CRD schemas at PLAN time,
    # which breaks "install CRD + CR in the same apply" patterns
    # kubectl_manifest validates lazily at apply time — used for the ClusterIssuer.
    kubectl = {
      source                = "gavinbunney/kubectl"
      version               = "~> 1.14"
      configuration_aliases = []
    }
  }
}
