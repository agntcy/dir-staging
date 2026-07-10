# Spire Node

Turns one configured GKE cluster into a SPIRE node with a reachable
federation bundle endpoint, with the TLS profile selectable via
`federation_tls_mode`.

## What it creates

The resources created by this module vary based on the `federation_tls_mode` and `dns_mode` configuration.

### federation_tls_mode = web, dns_mode = managed

When using `federation_tls_mode = "web"` with `dns_mode = "managed"`, this module creates:

**GCP Resources:**
- `google_compute_address`: A reserved static IP address for the federation endpoint

**Helm Releases:**
- `spire-crds`: SPIRE Custom Resource Definitions (version 0.5.0)
- `spire`: SPIRE server with federation enabled (version 0.27.0)
  - Includes SPIRE OIDC discovery provider for federation
- `ingress-nginx`: NGINX ingress controller with SSL passthrough enabled (version 4.12.0)
- `cert-manager`: Certificate management for TLS certificates (version v1.16.2)
- `external-dns`: DNS management for Cloud DNS integration (version 1.21.1)

**Kubernetes Resources:**
- `kubectl_manifest.cluster_issuer`: Let's Encrypt ClusterIssuer for automated SSL certificate provisioning
- `kubectl_manifest.federation_ingress`: Kubernetes Ingress resource routing HTTPS traffic to SPIRE server
- `kubectl_manifest.oidc_discovery_ingress`: Kubernetes Ingress resource for OIDC discovery provider
- Namespaces: `spire-server`, `ingress-nginx`, `cert-manager`, `external-dns`

**Supporting Resources:**
- `null_resource.wait_for_lb_propagation`: Ensures the load balancer is reachable before proceeding with certificate issuance

**Resulting Infrastructure:**
- Publicly accessible HTTPS federation endpoint at `https://dir.${cluster_name}.${base_domain}`
- OIDC discovery endpoint at `https://oidc-discovery.${cluster_name}.${base_domain}`
- Automatic SSL/TLS certificate provisioning via Let's Encrypt
- DNS records automatically managed in Cloud DNS via ExternalDNS
- SPIRE server configured for HTTPS federation with web PKI
- SPIRE OIDC discovery provider for JWT-SVID federation support

## Important Configuration Notes

### OIDC Discovery Provider Domain Configuration

The SPIRE Helm chart derives OIDC discovery endpoints from the trust domain by default. To use a custom domain for OIDC discovery (e.g., for federation with external systems), the `global.spire.jwtIssuer` value must be set in the Helm values. This is configured in the `web.yaml.tftpl` values file to ensure both the OIDC provider ConfigMap and SPIRE server configuration use the correct domain.

## Usage

```hcl
module "my_spire_node" {
  source              = "../../modules/spire-node"
  project_id          = "my-project"
  region              = "us-central1"
  cluster_name        = "testbed"
  trust_domain        = "example.agntcy.testbed"
  federation_tls_mode = "spiffe"

  providers = {
    kubernetes = kubernetes.my_cluster
    helm       = helm.my_cluster
  }
}
```

The caller supplies the kubernetes/helm providers already pointed at the
right cluster.

## Inputs

| Name | Type | Notes                                                                                                             |
|---|---|-------------------------------------------------------------------------------------------------------------------|
| `project_id` | string | Required. Static IP project.                                                                                      |
| `region` | string | Required. Static IP region.                                                                                       |
| `cluster_name` | string | Required. SPIRE clusterName, helm release suffix, FQDN label.                                                     |
| `trust_domain` | string | Required. SPIRE trust domain.                                                                                     |
| `federation_tls_mode` | `"spiffe"` \| `"web"` | Required. The toggle.                                                                                             |
| `acme_email` | string | Required iff `web` mode. LE registration.                                                                         |
| `base_domain` | string | Default `nip.io` (for nip-io mode). In managed mode, set to the real domain (e.g. `"example.com"`).               |
| `dns_mode` | `"nip-io"` \| `"managed"` | Default `"nip-io"`. `"managed"` provisions Cloud DNS records via ExternalDNS for a real domain.                   |
| `dns_project_id` | string | Required iff `managed`. GCP project hosting the Cloud DNS zone (typically a different project than `project_id`). |
| `dns_zone_name` | string | Required iff `managed`. Cloud DNS managed zone resource name (not the domain).                                    |
| `external_dns_gsa_email` | string | Required iff `managed`. Pre-provisioned GSA email with `roles/dns.admin` on the zone; see env README pre-flight.  |

## Outputs

| Name | Notes |
|---|---|
| `trust_domain` | echoed |
| `bundle_endpoint_url` | peer-facing URL |
| `endpoint_spiffe_id` | only meaningful in `spiffe` mode |
| `reserved_ip` | the federation static IP |
