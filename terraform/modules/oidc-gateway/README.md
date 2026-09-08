# OIDC Gateway Terraform Module

This module deploys the AGNTCY OIDC Gateway, which provides user authentication and authorization for the Directory API using external OIDC providers (GitHub, Google, etc.).

## What it creates

- Kubernetes namespace: `oidc-gateway`
- OIDC Gateway Helm chart (Envoy + auth service)
- Ingress resource for external access (if enabled)
- TLS certificates via cert-manager (if ingress enabled)

## Architecture

```
User/CLI → OIDC Provider (GitHub/Google) → OIDC Gateway → Directory API
```

The gateway:
1. Validates JWT tokens from external OIDC providers
2. Enforces RBAC policies based on user identity
3. Forwards authenticated requests to the Directory API
4. Protects the Directory service from direct external access

## Usage

```hcl
module "oidc_gateway" {
  source = "../../modules/oidc-gateway"
  
  project_id          = var.project_id
  region              = var.region
  cluster_name        = var.cluster_name
  base_fqdn           = module.spire_node.federation_fqdn
  dir_backend_address = "dir-apiserver.${var.cluster_name}.svc.cluster.local"
  trust_domain        = module.spire_node.trust_domain
  className           = "dir-spire"
  acme_email          = var.acme_email
  
  # Enable GitHub OIDC for GitHub Actions
  github_enabled = true
  
  # Enable Google OAuth for user authentication
  google_enabled = true
  
  # RBAC configuration
  admin_principals = [
    "oidc:github:alice",
    "oidc:github:bob"
  ]
  viewer_principals = ["*"]  # All authenticated users
  ci_writer_principals = [
    "oidc:github:repo:my-org/my-repo:workflow:deploy.yml"
  ]
  
  # Expose via ingress
  ingress_enabled = true
}
```

## Authentication Flow

### GitHub Actions
```yaml
# In your GitHub Actions workflow
- name: Push to Directory
  run: dirctl push myapp:latest
  # GitHub OIDC token automatically available
```

### User Authentication
```bash
# User authenticates with GitHub
dirctl login --provider github

# Use Directory commands
dirctl push myimage:latest
dirctl pull someimage:latest
```

## OIDC Providers

### GitHub (GitHub Actions)
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Use case**: CI/CD workflows
- **Token format**: `oidc:github:repo:org/repo:workflow:name:ref:refs/heads/main`

### Google OAuth
- **Issuer**: `https://accounts.google.com`
- **Use case**: User authentication
- **Token format**: `oidc:google:user@example.com`

### Custom Providers
You can add custom OIDC providers via the `custom_issuers` variable.

## RBAC Roles

### Admin
- **Permissions**: Full access (`*`)
- **Use case**: Directory administrators

### Viewer
- **Permissions**: Pull, Lookup, Search (read-only)
- **Use case**: General users, monitoring

### CI Writer
- **Permissions**: Push, Pull, Search
- **Use case**: CI/CD workflows

## Inputs

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_id` | GCP project ID | string | - |
| `region` | GCP region | string | - |
| `cluster_name` | GKE cluster name | string | - |
| `base_fqdn` | Base FQDN for gateway | string | - |
| `dir_backend_address` | Directory API address | string | `dir-apiserver.dir.svc.cluster.local` |
| `dir_backend_port` | Directory API port | number | `8888` |
| `trust_domain` | SPIRE trust domain | string | - |
| `className` | SPIRE class name | string | `dir-spire` |
| `chart_version` | OIDC gateway chart version | string | `v1.0.0` |
| `github_enabled` | Enable GitHub OIDC | bool | `true` |
| `google_enabled` | Enable Google OAuth | bool | `false` |
| `admin_principals` | Admin principals | list(string) | `[]` |
| `viewer_principals` | Viewer principals | list(string) | `["*"]` |
| `ci_writer_principals` | CI writer principals | list(string) | `[]` |
| `ingress_enabled` | Enable ingress | bool | `true` |
| `acme_email` | Let's Encrypt email | string | - |

## Outputs

| Output | Description |
|--------|-------------|
| `namespace` | Gateway namespace |
| `gateway_fqdn` | Gateway FQDN |
| `gateway_url` | Gateway URL |
| `dir_backend_address` | Directory backend address |
| `enabled_oidc_providers` | List of enabled providers |

## Requirements

- GKE cluster with SPIRE
- Directory API server deployed
- cert-manager with ClusterIssuer (if ingress enabled)
- External DNS (if ingress enabled)

## Notes

- The gateway uses SPIFFE for service-to-service authentication
- External users authenticate via OIDC providers
- RBAC is enforced at the gateway level
- The Directory API only receives authenticated requests