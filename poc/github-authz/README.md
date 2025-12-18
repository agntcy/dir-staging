# GitHub OAuth + Envoy Authorization PoC

This PoC demonstrates GitHub OAuth authentication for Directory API access using Envoy as an edge proxy with external authorization.

**Related Issue**: [agntcy/dir-staging#14](https://github.com/agntcy/dir-staging/issues/14)

Based on the [SPIRE Envoy JWT tutorials](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt).

## Overview

```
┌─────────────┐     ┌─────────────────┐     ┌───────────────────┐     ┌─────────────┐
│   Client    │────►│     Envoy       │────►│  GitHub Auth      │────►│  GitHub     │
│   (curl/    │     │     Gateway     │     │  Server           │     │  API        │
│   dirctl)   │     │   (ext_authz)   │     │  (validate token) │     │             │
└─────────────┘     └────────┬────────┘     └───────────────────┘     └─────────────┘
                             │
                             │ Authorized Request
                             │ + x-github-user
                             │ + x-github-orgs
                             ▼
                    ┌─────────────────┐
                    │   Directory     │
                    │   API Server    │
                    └─────────────────┘
```

## Quick Start

### Prerequisites

1. Directory deployment running in the cluster (see main [README](../../README.md))
2. GitHub Personal Access Token with `read:user` and `read:org` scopes

### Deploy

```bash
# Build and load image to Kind cluster
docker build -t ghcr.io/agntcy/github-authz-server:dev -f Dockerfile.authz .
kind load docker-image ghcr.io/agntcy/github-authz-server:dev --name dir-dev

# Deploy to Kubernetes
kubectl apply -k k8s/

# Wait for pods
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/part-of=directory-github-authz-poc \
  -n dir-dev-github-authz --timeout=60s

# Port forward for testing (8081 since 8080 is used by ArgoCD)
kubectl port-forward -n dir-dev-github-authz svc/envoy-gateway 8081:8080
```

### Test

```bash
# Health check (no auth)
curl http://localhost:8081/healthz

# With GitHub token
curl -H "Authorization: Bearer $DIRECTORY_CLIENT_GITHUB_PAT" \
     http://localhost:8081/api/v1/search
```

See [k8s/README.md](k8s/README.md) for detailed Kubernetes deployment instructions.

## Project Structure

```
poc/github-authz/
├── auth/
│   └── github.go              # GitHub API client
├── authzserver/
│   └── server.go              # Envoy ext_authz gRPC server
├── cmd/
│   └── github-authz-server/   # Auth server binary
│       └── main.go
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap-authz.yaml   # Authorization rules
│   ├── configmap-envoy.yaml   # Envoy configuration
│   ├── deployment-authz.yaml  # Auth server deployment
│   ├── deployment-envoy.yaml  # Envoy gateway deployment
│   ├── kustomization.yaml
│   └── README.md
├── Dockerfile.authz
├── go.mod
└── README.md
```

## Configuration

### Authorization Rules

Configure via the `github-authz-config` ConfigMap:

| Key | Description | Example |
|-----|-------------|---------|
| `GITHUB_ALLOWED_ORGS` | Allowed organizations | `agntcy,spiffe` |
| `GITHUB_ALLOWED_USERS` | Explicitly allowed users | `admin-user` |
| `GITHUB_DENIED_USERS` | Explicitly denied users | `blocked-user` |
| `GITHUB_ALLOWED_TEAMS` | Team restrictions (JSON) | `{"agntcy": ["devs"]}` |
| `AUTHZ_CACHE_TTL` | Cache duration | `5m` |
| `DEBUG` | Enable debug logging | `true` |

### Restrict to Organization

```bash
kubectl patch configmap github-authz-config -n dir-dev-github-authz \
  --type merge -p 'data:
  GITHUB_ALLOWED_ORGS: "agntcy,spiffe"
'

kubectl rollout restart deployment github-authz-server -n dir-dev-github-authz
```

## Response Headers

When authorized, Envoy adds these headers to backend requests:

| Header | Description |
|--------|-------------|
| `x-github-user` | GitHub username |
| `x-github-user-id` | GitHub user ID |
| `x-github-orgs` | Comma-separated list of organizations |
| `x-auth-method` | Authentication method (`github-oauth`) |

## Documentation

- [Architecture Overview](../../docs/github-authz-poc.md)
- [Kubernetes Deployment](k8s/README.md)
