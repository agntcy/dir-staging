terraform {
  required_version = ">= 1.7"

  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "~> 2.38"
      configuration_aliases = [kubernetes]
    }
    helm = {
      source                = "hashicorp/helm"
      version               = "~> 2.17"
      configuration_aliases = [helm]
    }
    kubectl = {
      source                = "gavinbunney/kubectl"
      version               = "~> 1.19"
      configuration_aliases = [kubectl]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "~> 1.2"
    }
  }
}
