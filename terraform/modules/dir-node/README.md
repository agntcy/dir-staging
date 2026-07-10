# AGNTCY Directory Node

Installs the AGNTCY Directory umbrella Helm chart (`oci://ghcr.io/agntcy/dir/helm-charts/dir`) on top of a SPIRE deployment provisioned by `terraform/modules/spire-node`. The umbrella has a single subchart (`apiserver`); all component config nests under `apiserver:` in values. Provides:

- `dir-apiserver` — gRPC server, identifies itself via SPIFFE SVID from the spiffe-csi-driver
- `reconciler` — internal reconciler deployment (part of the apiserver subchart's own templates, not a separate component)
- `postgresql` — backing datastore (sub-subchart of apiserver)
- `zot` — OCI registry for record content (sub-subchart of apiserver)
- `routingService` — P2P routing service for peer discovery and publication via LoadBalancer

## Prerequisites

- A SPIRE deployment from `terraform/modules/spire-node` in web mode (`federation_tls_mode = "web"`). dir-node consumes `trust_domain` and `federation_fqdn` outputs from spire-node.
- A `letsencrypt-prod` ClusterIssuer (created by spire-node).
- A reachable ingress-nginx LoadBalancer (also created by spire-node).
- Configured Kubernetes/Helm/kubectl providers (caller's responsibility — pass via `providers` block).

## Usage

```hcl
module "example_dir" {
  source       = "../../modules/dir-node"

  project_id   = var.project_id
  region       = var.region
  cluster_name = "<your-cluster-name>"
  trust_domain = module.example_spire.trust_domain
  base_fqdn    = module.example_spire.federation_fqdn
  acme_email   = var.acme_email

  providers = {
    kubernetes = kubernetes.<your-cluster-name>
    helm       = helm.<your-cluster-name>
    kubectl    = kubectl.<your-cluster-name>
  }

  depends_on = [module.example_spire]
}
```

## Outputs

| Output | Description |
|---|---|
| `api_url` | `https://api.<base_fqdn>` |
| `zot_url` | `https://zot.<base_fqdn>` |
| `credentials_secret_name` | Name of the K8s Secret holding postgres-password + zot-htpasswd |
| `namespace` | Where the chart is installed |

## Federation Configuration

Federation with other trust domains requires configuration at **two levels**:

### 1. SPIRE-Level Federation (via spire-node module)
Configure which trust domains your SPIRE server should trust using the `federates_with` parameter in the `spire-node` module. This configures SPIRE's `controllerManager.identities.clusterSPIFFEIDs.default.federatesWith` field.

Example:
```hcl
module "your_spire" {
  source         = "../../modules/spire-node"
  # ... other configuration ...
  federates_with = ["spire.ads.outshift.io"]
}
```

### 2. DIR-Level Federation (via dir-node module)
Configure which federation peers the DIR apiserver should trust using the `federation_peers` parameter. This configures the DIR apiserver's SPIRE federation settings.

Example:
```hcl
module "your_dir" {
  source           = "../../modules/dir-node"
  # ... other configuration ...
  federation_peers = [{
    className               = "dir-spire"
    trustDomain            = "spire.ads.outshift.io"
    bundleEndpointURL      = "https://spire.ads.outshift.io"
    bundleEndpointProfile  = {
      type = "https_web"
    }
  }]
  
  depends_on = [module.your_spire]
}
```

### Two-Way Trust Requirement
Federation requires **two-way trust**:
- ✅ Your cluster trusting the public directory (configured above)
- ⚠️ The public directory trusting YOUR cluster (requires manual onboarding)

To complete the two-way trust setup, you must:
1. Ensure your SPIRE federation endpoint is publicly reachable
2. Submit a federation configuration PR to `agntcy/dir-staging` with your trust domain details
3. Wait for maintainers to merge and deploy the changes
4. Ensure authorization policies are added for your trust domain

## Authorization Policies

The DIR apiserver uses CSV-based authorization policies to control which trust domains can access which services. This is critical for federation security.

### Default Policies
If no custom policies are specified, the module uses sensible defaults that support federation:

```csv
p,<your-trust-domain>,*
p,*,/agntcy.dir.store.v1.StoreService/Pull
p,*,/agntcy.dir.store.v1.StoreService/PullReferrer
p,*,/agntcy.dir.store.v1.StoreService/Lookup
p,*,/agntcy.dir.store.v1.SyncService/RequestRegistryCredentials
```

These policies:
- Grant your local trust domain full access to all services
- Allow any trust domain to read records (Pull, PullReferrer, Lookup)
- Allow any trust domain to request registry credentials for synchronization

### Custom Policies
You can customize authorization policies using the `authz_policies_csv` parameter:

```hcl
module "your_dir" {
  source           = "../../modules/dir-node"
  # ... other configuration ...
  authz_policies_csv = "p,example.agntcy.testbed,*\np,spire.ads.outshift.io,/agntcy.dir.store.v1.StoreService/Pull"
}
```

### Policy Format
The authorization policies follow this CSV format:
- `p,<trust-domain>,<service-or-wildcard>` - Grant permission
- `<trust-domain>`: Specific trust domain or `*` for any federated domain
- `<service-or-wildcard>`: Specific service path or `*` for all services

For production deployments, consider restricting access to specific trust domains rather than using wildcards.

## DIR Reconciler

The DIR reconciler is an internal component that handles synchronization between federated Directory instances. It's deployed as part of the DIR apiserver subchart and runs continuously to keep your Directory instance synchronized with other trusted directories in the federation.

### What It Does

- **Record Synchronization**: Pulls records from federated peer directories and stores them in your local PostgreSQL database
- **Registry Synchronization**: Syncs OCI registry content (Zot) between federated instances using regsync
- **Indexing**: Maintains search indexes for federated records to enable discovery across trust domains
- **Continuous Operation**: Runs as a background deployment with periodic checks for updates

### Configuration

The reconciler is enabled by default with production-ready settings based on AGNTCY recommendations:

```hcl
module "your_dir" {
  source           = "../../modules/dir-node"
  # ... other configuration ...
  
  # Reconciler settings (all have sensible defaults)
  reconciler_enabled          = true
  reconciler_image_tag        = "v1.3.0"  # Matches dir_chart_version
  reconciler_regsync_enabled  = true
  reconciler_regsync_interval = "1m"     # Check for registry updates every minute
  reconciler_regsync_timeout  = "30m"    # Timeout for sync operations
  reconciler_indexer_enabled  = true
  reconciler_indexer_interval = "30m"    # Rebuild indexes every 30 minutes
}
```

### Expected Behavior Before Two-Way Trust

The reconciler will start immediately after deployment, but will experience authentication failures when trying to sync from federated peers until two-way trust is established. This is expected behavior:

- ✅ Deployment will complete successfully
- ✅ Reconciler will run without crashing
- ⚠️ Authentication failures will be logged until onboarding completes
- ✅ Automatic recovery once two-way trust is established

This intentional design allows you to deploy the complete infrastructure once, complete the manual onboarding process, and have federation begin working automatically without re-deployment.

## P2P Routing Service

The P2P routing service enables peer discovery and publication in the AGNTCY Directory network. It runs as part of the DIR apiserver and provides a libp2p-based routing layer for distributed peer communication.

### What It Does

- **Peer Discovery**: Allows Directory instances to discover and connect to each other
- **Record Publication**: Enables publishing records to the distributed network
- **Multiaddr Protocol**: Uses libp2p multiaddrs for peer addressing and communication
- **LoadBalancer Access**: Exposes the routing service on port 5555 via external LoadBalancer

### Configuration

The routing service is configured with cloud provider-specific LoadBalancer settings:

```hcl
module "your_dir" {
  source           = "../../modules/dir-node"
  # ... other configuration ...
  
  # Routing service is configured via the DIR Helm chart values
  # The module passes through routing configuration to the chart
}
```

### Access

The routing service is accessible via:
- **DNS**: `routing.${base_domain}` (managed by ExternalDNS)
- **Port**: TCP 5555
- **Protocol**: libp2p multiaddr protocol

### Expected Behavior

The routing service requires:
- ✅ External LoadBalancer with TCP port 5555 accessible
- ✅ DNS record pointing to the LoadBalancer IP
- ✅ Network security group allowing inbound TCP 5555
- ⚠️ VPN blocking may affect accessibility (non-standard port)

If the routing service is unreachable, peer discovery and publication will fail silently while the rest of the deployment appears healthy.
