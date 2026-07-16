# OIDC Gateway Configuration

The OIDC gateway provides user authentication and authorization for the Directory API using external OIDC providers like GitHub and Google.

## Overview

The gateway sits between external users and the Directory API:

```
User/CLI → OIDC Provider (GitHub/Google) → OIDC Gateway → Directory API
```

**The gateway:**
1. Validates JWT tokens from external OIDC providers
2. Enforces RBAC policies based on user identity
3. Forwards authenticated requests to the Directory API
4. Protects the Directory service from direct external access

## Enable OIDC Gateway

Add the following to your `terraform.tfvars`:

```hcl
# OIDC Gateway configuration
oidc_gateway_enabled = true  # Enable OIDC gateway deployment
oidc_gateway_chart_version = "v1.0.0"
oidc_github_enabled = true  # Enable GitHub Actions OIDC
oidc_google_enabled = false  # Enable Google OAuth
oidc_admin_principals = ["oidc:github:your-username"]  # Admin users
oidc_viewer_principals = ["*"]  # All authenticated users have read access
oidc_ci_writer_principals = ["oidc:github:repo:your-org/your-repo:workflow:*.yml"]  # CI workflows
oidc_ingress_enabled = true  # Expose gateway via ingress
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

### Direct API Access
```bash
# Get JWT token from GitHub
TOKEN=$(gh auth token)

# Use token to call Directory API via gateway
curl -H "Authorization: Bearer $TOKEN" \
  https://gateway.example.com/agntcy.dir.store.v1.StoreService/Pull
```

## Gateway URL

After deployment, the gateway will be available at:
```
https://gateway.<your-base-fqdn>
```

For example, if your base FQDN is `dir.dev.example.com`, the gateway will be at:
```
https://gateway.dir.dev.example.com
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
You can add custom OIDC providers by modifying the Terraform module to include additional issuers.

## RBAC Configuration

The gateway supports three built-in roles:

### Admin
- **Permissions**: Full access (`*`)
- **Use case**: Directory administrators
- **Example principals**: `["oidc:github:alice", "oidc:github:bob"]`

### Viewer
- **Permissions**: Read-only (Pull, Lookup, Search)
- **Use case**: General users, monitoring
- **Example principals**: `["*"]` (all authenticated users)

### CI Writer
- **Permissions**: Push/Pull/Search
- **Use case**: CI/CD workflows
- **Example principals**: `["oidc:github:repo:my-org/my-repo:workflow:deploy.yml"]`

## Principal Format

Principals are specified in the following formats:

- **GitHub users**: `oidc:github:username`
- **GitHub Actions**: `oidc:github:repo:org/repo:workflow:name:ref:refs/heads/main`
- **Google users**: `oidc:google:user@example.com`
- **All authenticated users**: `*`
- **SPIFFE identities**: `spiffe://trust-domain/ns/namespace/sa/service-account`

## Configuration Examples

### GitHub Actions Only
```hcl
oidc_gateway_enabled = true
oidc_github_enabled = true
oidc_google_enabled = false
oidc_admin_principals = ["oidc:github:admin-user"]
oidc_viewer_principals = ["*"]
oidc_ci_writer_principals = [
  "oidc:github:repo:my-org/my-repo:workflow:deploy.yml"
]
```

### Google OAuth Only
```hcl
oidc_gateway_enabled = true
oidc_github_enabled = false
oidc_google_enabled = true
oidc_admin_principals = ["oidc:google:admin@example.com"]
oidc_viewer_principals = ["*"]
oidc_ci_writer_principals = []
```

### Both Providers
```hcl
oidc_gateway_enabled = true
oidc_github_enabled = true
oidc_google_enabled = true
oidc_admin_principals = [
  "oidc:github:github-admin",
  "oidc:google:admin@example.com"
]
oidc_viewer_principals = ["*"]
oidc_ci_writer_principals = [
  "oidc:github:repo:my-org/my-repo:workflow:*.yml"
]
```

## Security Considerations

1. **HTTPS Only**: The gateway always uses HTTPS for external access
2. **Token Validation**: All JWT tokens are validated against provider JWKS endpoints
3. **RBAC Enforcement**: All requests are checked against RBAC policies
4. **Service-to-Service**: Internal services still use SPIFFE authentication
5. **Rate Limiting**: Consider adding rate limiting annotations for public deployments

## Troubleshooting

### Gateway Not Accessible
- Check ingress is enabled: `oidc_ingress_enabled = true`
- Verify DNS records are created (may take a few minutes)
- Check cert-manager is issuing certificates

### Authentication Failures
- Verify OIDC provider is enabled
- Check token format matches expected principal format
- Review gateway logs for validation errors

### RBAC Issues
- Verify principal format is correct
- Check that user is in the correct role
- Review RBAC configuration in gateway logs

## Requirements

- GKE cluster with SPIRE
- Directory API server deployed
- cert-manager with ClusterIssuer (if ingress enabled)
- External DNS (if ingress enabled)
- OIDC provider account (GitHub, Google, or custom)

## Notes

- The gateway uses SPIFFE for service-to-service authentication
- External users authenticate via OIDC providers
- RBAC is enforced at the gateway level
- The Directory API only receives authenticated requests
- Gateway can be disabled by setting `oidc_gateway_enabled = false` (default)