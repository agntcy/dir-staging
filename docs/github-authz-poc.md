# GitHub Authentication for Directory API

This document describes the GitHub authentication solution for the Directory API, enabling users to access Directory using their GitHub identity.

**Related Issue**: [agntcy/dir-staging#14](https://github.com/agntcy/dir-staging/issues/14)

## Overview

The solution enables Directory users to authenticate using GitHub Personal Access Tokens (PAT) instead of requiring SPIFFE federation setup. This lowers the barrier to entry while maintaining security through organization-based authorization rules.

### Design Inspiration

This implementation follows the patterns from the [SPIRE Envoy tutorials](https://github.com/spiffe/spire-tutorials):
- [Envoy JWT Tutorial](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt) - Envoy with SPIFFE for workload identity
- [Envoy JWT Auth Helper](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt-auth-helper) - External authorization patterns

## Architecture

```
                                         Kubernetes Cluster
┌──────────────────┐                    ┌─────────────────────────────────────────────────────────┐
│                  │                    │                                                         │
│  dirctl CLI      │                    │   dir-dev-github-authz namespace                        │
│                  │                    │                                                         │
│  ┌────────────┐  │   HTTP/2 + Bearer  │  ┌─────────────────┐      ┌───────────────────────┐    │
│  │ --auth-mode│  │   Token            │  │                 │      │                       │    │
│  │  github    │──┼───────────────────►│  │  Envoy Gateway  │─────►│  GitHub Auth Server   │    │
│  │            │  │                    │  │  (ext_authz)    │      │  (gRPC ext_authz)     │    │
│  └────────────┘  │                    │  │                 │      │                       │    │
│                  │                    │  └────────┬────────┘      └───────────┬───────────┘    │
└──────────────────┘                    │           │                           │               │
                                        │           │                           │               │
                                        │           │ mTLS (SPIFFE)             │ Validate      │
                                        │           │                           │ Token         │
                                        │           │                           ▼               │
                                        │           │                    ┌──────────────┐       │
                                        │           │                    │   GitHub     │       │
                                        │           │                    │   API        │       │
                                        │           │                    └──────────────┘       │
                                        │           │                                           │
                                        └───────────│───────────────────────────────────────────┘
                                                    │
                                                    │ Authorized Request
                                                    │ + x-github-user header
                                                    │ + x-github-orgs header
                                                    ▼
                                        ┌───────────────────────────────────────────────────────┐
                                        │   dir-dev-dir namespace                               │
                                        │                                                       │
                                        │   ┌─────────────────────────────────────────────┐     │
                                        │   │         Directory API Server                │     │
                                        │   │         (SPIFFE-enabled, mTLS)              │     │
                                        │   └─────────────────────────────────────────────┘     │
                                        │                                                       │
                                        └───────────────────────────────────────────────────────┘
```

## Components

| Component | Description |
|-----------|-------------|
| **Envoy Gateway** | Edge proxy that handles incoming requests and delegates authorization |
| **GitHub Auth Server** | gRPC service implementing Envoy's [ext_authz API](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ext_authz/v3/ext_authz.proto) |
| **Directory API** | Backend gRPC service protected by SPIFFE mTLS |
| **SPIRE Agent** | Provides workload identity (X.509-SVID) to Envoy for mTLS with Directory |

## Authentication Flow

```
┌─────────┐          ┌─────────┐          ┌─────────────┐          ┌────────┐          ┌───────────┐
│ dirctl  │          │ Envoy   │          │ GitHub Auth │          │ GitHub │          │ Directory │
│ CLI     │          │ Gateway │          │ Server      │          │ API    │          │ API       │
└────┬────┘          └────┬────┘          └──────┬──────┘          └───┬────┘          └─────┬─────┘
     │                    │                      │                     │                     │
     │ 1. gRPC Request    │                      │                     │                     │
     │    + Bearer Token  │                      │                     │                     │
     │───────────────────►│                      │                     │                     │
     │                    │                      │                     │                     │
     │                    │ 2. ext_authz Check   │                     │                     │
     │                    │    (gRPC)            │                     │                     │
     │                    │─────────────────────►│                     │                     │
     │                    │                      │                     │                     │
     │                    │                      │ 3. GET /user        │                     │
     │                    │                      │    GET /user/orgs   │                     │
     │                    │                      │────────────────────►│                     │
     │                    │                      │                     │                     │
     │                    │                      │ 4. User info        │                     │
     │                    │                      │◄────────────────────│                     │
     │                    │                      │                     │                     │
     │                    │                      │                     │                     │
     │                    │                      │ 5. Check authz rules│                     │
     │                    │                      │    (allowed orgs,   │                     │
     │                    │                      │     users, teams)   │                     │
     │                    │                      │                     │                     │
     │                    │ 6. OK + headers      │                     │                     │
     │                    │    x-github-user     │                     │                     │
     │                    │    x-github-orgs     │                     │                     │
     │                    │◄─────────────────────│                     │                     │
     │                    │                      │                     │                     │
     │                    │ 7. Forward request (mTLS via SPIFFE)       │                     │
     │                    │────────────────────────────────────────────────────────────────►│
     │                    │                      │                     │                     │
     │                    │ 8. Response          │                     │                     │
     │◄───────────────────│◄────────────────────────────────────────────────────────────────│
     │                    │                      │                     │                     │
```

## Two-Layer Identity Model

The solution uses a two-layer identity model, separating user identity from workload identity:

| Layer | Identity | Mechanism | Purpose |
|-------|----------|-----------|---------|
| **User** | GitHub username | OAuth Bearer Token | Identifies the human user making the request |
| **Workload** | SPIFFE ID | X.509-SVID (mTLS) | Identifies the Envoy gateway to Directory API |

This approach is similar to how the [SPIRE Envoy JWT tutorial](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt) separates JWT-based user authentication from SPIFFE workload identity.

## Authorization Rules

Access is controlled via ConfigMap with the following options:

| Rule | Environment Variable | Description |
|------|---------------------|-------------|
| Allowed Organizations | `GITHUB_ALLOWED_ORGS` | Comma-separated list (e.g., `agntcy`) |
| Allowed Users | `GITHUB_ALLOWED_USERS` | Explicitly allowed usernames |
| Denied Users | `GITHUB_DENIED_USERS` | Explicitly blocked usernames |
| Allowed Teams | `GITHUB_ALLOWED_TEAMS` | JSON map of org → teams |

**Authorization Logic**:
1. If user is in deny list → **DENY**
2. If user is in allow list → **ALLOW**
3. If allowed orgs configured and user is member of any → **ALLOW**
4. Otherwise → **DENY**

## Injected Headers

When a request is authorized, the following headers are added for the backend:

| Header | Description | Example |
|--------|-------------|---------|
| `x-github-user` | GitHub username | `clouropa` |
| `x-github-user-id` | GitHub user ID | `12345678` |
| `x-github-orgs` | Organizations | `agntcy,spiffe` |
| `x-auth-method` | Auth method | `github-oauth` |

## Usage

### Prerequisites

1. GitHub Personal Access Token with `read:user` and `read:org` scopes
2. `dirctl` CLI with GitHub auth support (from `dir` repository)

### Testing with dirctl

```bash
# Set environment variables
export DIRECTORY_CLIENT_AUTH_MODE="github"
export DIRECTORY_CLIENT_SERVER_ADDRESS="127.0.0.1:8081"
export DIRECTORY_CLIENT_GITHUB_PAT="ghp_your_token_here"

# Port forward to Envoy gateway
kubectl port-forward -n dir-dev-github-authz svc/envoy-gateway 8081:8080 &

# Run dirctl commands
dirctl search --name "*"
```

### Testing with curl

```bash
# Health check (no auth required)
curl http://localhost:8081/healthz

# API request with GitHub token
curl -H "Authorization: Bearer $DIRECTORY_CLIENT_GITHUB_PAT" \
     http://localhost:8081/api/v1/search
```

## Deployment

The PoC is deployed using Kustomize:

```bash
# Build and load images
docker build -t ghcr.io/agntcy/github-authz-server:dev -f poc/github-authz/Dockerfile.authz poc/github-authz/
kind load docker-image ghcr.io/agntcy/github-authz-server:dev --name dir-dev

# Deploy
kubectl apply -k poc/github-authz/k8s/

# Wait for pods
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/part-of=directory-github-authz-poc \
  -n dir-dev-github-authz --timeout=60s
```

## File Structure

```
poc/github-authz/
├── auth/
│   └── github.go              # GitHub API client
├── authzserver/
│   └── server.go              # Envoy ext_authz gRPC server
├── cmd/
│   └── github-authz-server/   # Server binary
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap-authz.yaml   # Authorization rules
│   ├── configmap-envoy.yaml   # Envoy configuration with SDS
│   ├── deployment-authz.yaml
│   ├── deployment-envoy.yaml  # Envoy with SPIFFE CSI
│   └── kustomization.yaml
├── Dockerfile.authz
└── go.mod
```

## References

- [SPIRE Envoy JWT Tutorial](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt)
- [SPIRE Envoy JWT Auth Helper](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt-auth-helper)
- [Envoy External Authorization](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ext_authz_filter)
- [GitHub OAuth API](https://docs.github.com/en/rest/users)

