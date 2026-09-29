resource "google_compute_address" "federation_endpoint" {
  name    = "spire-${var.cluster_name}-federation"
  project = var.project_id
  region  = var.region
}

locals {
  reserved_ip = google_compute_address.federation_endpoint.address

  fqdn = (
    var.dns_mode == "nip-io"
    ? "dir-${var.cluster_name}.${local.reserved_ip}.${var.base_domain}"
    : "dir.${var.cluster_name}.${var.base_domain}"
  )

  bundle_endpoint_url = (
    var.federation_tls_mode == "spiffe"
    ? "https://${local.reserved_ip}:8443"
    : "https://${local.fqdn}"
  )

  endpoint_spiffe_id = "spiffe://${var.trust_domain}/spire/server"
}

locals {
  spire_chart_repo         = "https://spiffe.github.io/helm-charts-hardened"
  spire_chart_name         = "spire"
  spire_chart_version      = "0.29.0"
  spire_crds_chart_version = "0.5.0"

  spire_values = (
    var.federation_tls_mode == "spiffe"
    ? templatefile("${path.module}/values/spiffe.yaml.tftpl", {
      trust_domain   = var.trust_domain
      cluster_name   = var.cluster_name
      federates_with = var.federates_with
    })
    : templatefile("${path.module}/values/web.yaml.tftpl", {
      trust_domain   = var.trust_domain
      cluster_name   = var.cluster_name
      fqdn           = local.fqdn
      acme_email     = var.acme_email
      federates_with = var.federates_with
    })
  )
}

resource "helm_release" "spire_crds" {
  name             = "spire-crds"
  namespace        = "spire-server"
  create_namespace = true

  repository = local.spire_chart_repo
  chart      = "spire-crds"
  version    = local.spire_crds_chart_version

  timeout = 300
  wait    = true
}

resource "helm_release" "spire" {
  name             = "spire"
  namespace        = "spire-server"
  create_namespace = true

  repository = local.spire_chart_repo
  chart      = local.spire_chart_name
  version    = local.spire_chart_version

  values = [local.spire_values]

  timeout          = 600
  wait             = true
  wait_for_jobs    = false
  cleanup_on_fail  = true
  disable_webhooks = true

  depends_on = [
    helm_release.spire_crds,
    helm_release.cert_manager,
    null_resource.wait_for_lb_propagation,
  ]
}

# spiffe-mode: expose spire-server's port 8443 directly via a LoadBalancer
resource "kubernetes_service" "federation_lb_spiffe" {
  count = var.federation_tls_mode == "spiffe" ? 1 : 0

  metadata {
    name      = "spire-server-federation"
    namespace = "spire-server"
  }
  spec {
    type             = "LoadBalancer"
    load_balancer_ip = local.reserved_ip
    selector = {
      "app.kubernetes.io/name"     = "server"
      "app.kubernetes.io/instance" = "spire"
    }
    port {
      name        = "federation"
      port        = 8443
      target_port = 8443
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.spire]
}

# ----- web mode -----
resource "helm_release" "ingress_nginx" {
  count = var.federation_tls_mode == "web" ? 1 : 0

  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.0"

  values = [
    yamlencode({
      controller = {
        extraArgs = {
          "enable-ssl-passthrough" = "true"
        }
        service = {
          loadBalancerIP        = local.reserved_ip
          externalTrafficPolicy = "Local"
          annotations = merge(
            {
              "cloud.google.com/load-balancer-type" = "External"
            },
            var.dns_mode == "managed" ? {
              "external-dns.alpha.kubernetes.io/hostname" = local.fqdn
            } : {}
          )
        }
      }
    })
  ]

  timeout    = 600
  wait       = true
  depends_on = [helm_release.external_dns]
}

resource "null_resource" "wait_for_lb_propagation" {
  count = var.federation_tls_mode == "web" ? 1 : 0

  triggers = {
    lb_ip = local.reserved_ip
    fqdn  = local.fqdn
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      echo "Polling http://${local.fqdn}/ for LB propagation..."
      for i in $(seq 1 60); do
        # curl (no -f) exits 0 if any HTTP response is received (404 included),
        # non-zero on connection failure / DNS / timeout. That's exactly the
        # signal we want: "is the LB answering TCP yet". Parsing curl's -w
        # output is unreliable because curl prints "000" on connection failure
        # while also exiting non-zero, and the obvious `|| echo "000"` fallback
        # concatenates with curl's "000" to produce "000000".
        if curl -s --max-time 5 --output /dev/null "http://${local.fqdn}/" 2>/dev/null; then
          echo "LB reachable on attempt $i"
          exit 0
        fi
        echo "Attempt $i: not reachable yet, sleeping 10s..."
        sleep 10
      done
      echo "ERROR: LB still not reachable after 10 minutes" >&2
      exit 1
    EOT
  }

  depends_on = [helm_release.ingress_nginx]
}

resource "helm_release" "cert_manager" {
  count = var.federation_tls_mode == "web" ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.federation_tls_mode != "web" || var.acme_email != ""
      error_message = "acme_email is required when federation_tls_mode = 'web'."
    }
  }

  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.2"

  values = [
    yamlencode({
      crds = { enabled = true }
    })
  ]

  timeout       = 600
  wait          = true
  wait_for_jobs = true
}

resource "kubectl_manifest" "cluster_issuer" {
  count = var.federation_tls_mode == "web" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
        privateKeySecretRef = {
          name = "letsencrypt-prod-key"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "federation_ingress" {
  count = var.federation_tls_mode == "web" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "spire-server-federation"
      namespace = "spire-server"
      annotations = {
        "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
        "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
        "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      }
    }
    spec = {
      ingressClassName = "nginx"
      tls = [{
        hosts      = [local.fqdn]
        secretName = "spire-server-federation-cert"
      }]
      rules = [{
        host = local.fqdn
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "spire-server"
                port = { number = 8443 }
              }
            }
          }]
        }
      }]
    }
  })

  depends_on = [helm_release.spire]
}

# ----- managed DNS mode -----
resource "helm_release" "external_dns" {
  count = var.dns_mode == "managed" ? 1 : 0

  lifecycle {
    precondition {
      condition = var.dns_mode != "managed" || (
        var.dns_project_id != "" &&
        var.dns_zone_name != "" &&
        var.external_dns_gsa_email != "" &&
        var.base_domain != "nip.io"
      )
      error_message = "dns_mode='managed' requires non-empty dns_project_id, dns_zone_name, external_dns_gsa_email, and a real base_domain (not nip.io)."
    }
  }

  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.21.1"

  values = [
    yamlencode({
      provider = {
        name = "google"
      }
      google = {
        project = var.dns_project_id
      }
      domainFilters = [var.base_domain]
      zoneIdFilters = [var.dns_zone_name]
      policy        = "sync"
      sources       = ["service", "ingress"]
      txtOwnerId    = var.cluster_name
      extraArgs = [
        "--google-project=${var.dns_project_id}"
      ]
      serviceAccount = {
        create = true
        name   = "external-dns"
        annotations = {
          "iam.gke.io/gcp-service-account" = var.external_dns_gsa_email
        }
      }
    })
  ]

  timeout         = 300
  wait            = true
  cleanup_on_fail = true
}
