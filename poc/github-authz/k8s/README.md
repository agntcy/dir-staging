# GitHub OAuth + Envoy Authentication - Kubernetes Deployment

This directory contains Kubernetes manifests to deploy the GitHub OAuth authentication PoC alongside the existing Directory deployment.

**Related Issue**: [agntcy/dir-staging#14](https://github.com/agntcy/dir-staging/issues/14)

## Architecture

```
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                 dir-dev-github-authz namespace          │
┌─────────────┐                     │                                                         │
│   Client    │                     │  ┌─────────────────┐     ┌───────────────────┐         │
│   (curl/    │────────────────────►│  │  Envoy Gateway  │────►│  GitHub Auth      │         │
│   dirctl)   │    NodePort:30088   │  │  (ext_authz)    │     │  Server           │         │
└─────────────┘                     │  │  :8080          │     │  :9001            │         │
                                    │  └────────┬────────┘     └─────────┬─────────┘         │
                                    │           │                        │                   │
                                    └───────────│────────────────────────│───────────────────┘
                                                │                        │
                                                │ Authorized             │ Validate Token
                                                │ Request                │ (GitHub API)
                                                │                        ▼
                                                │                 ┌──────────────┐
                                                │                 │   GitHub     │
                                                │                 │   API        │
                                                │                 └──────────────┘
                                                ▼
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                   dir-dev-dir namespace                 │
                                    │                                                         │
                                    │           ┌─────────────────────────────┐               │
                                    │           │     Directory API Server    │               │
                                    │           │     :8888 (mTLS/SPIRE)      │               │
                                    │           └─────────────────────────────┘               │
                                    │                                                         │
                                    └─────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Directory deployment** must be running in the cluster
   ```bash
   kubectl get pods -n dir-dev-dir
   ```

2. **GitHub Personal Access Token** for testing
   - Go to https://github.com/settings/tokens
   - Create a token with `read:user` and `read:org` scopes

## Quick Start

### 1. Build and Push Images (if not using pre-built)

```bash
# From poc/github-authz directory
docker build -t ghcr.io/agntcy/github-authz-server:dev -f Dockerfile.authz .

# For Kind cluster, load the image directly
kind load docker-image ghcr.io/agntcy/github-authz-server:dev --name dir-dev
```

### 2. Deploy to Kubernetes

```bash
# From repository root
kubectl apply -k poc/github-authz/k8s/

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=directory-github-authz-poc -n dir-dev-github-authz --timeout=60s

# Check status
kubectl get pods -n dir-dev-github-authz
```

### 3. Test Authentication

```bash
# Port forward (using 8081 since 8080 is used by ArgoCD)
kubectl port-forward -n dir-dev-github-authz svc/envoy-gateway 8081:8080 &

# Health check (no auth required)
curl http://localhost:8081/healthz

# Test without token (should fail)
curl http://localhost:8081/api/v1/search
# Returns: {"error": "Unauthenticated", "message": "missing Authorization header"}

# Test with GitHub token
curl -H "Authorization: Bearer $DIRECTORY_CLIENT_GITHUB_PAT" \
     http://localhost:8081/api/v1/search
```

### 4. Configure Authorization Rules

Edit the ConfigMap to restrict access:

```bash
kubectl edit configmap github-authz-config -n dir-dev-github-authz
```

Or apply a patch:

```bash
kubectl patch configmap github-authz-config -n dir-dev-github-authz --type merge -p '
data:
  GITHUB_ALLOWED_ORGS: "agntcy,spiffe"
'

# Restart the auth server to pick up changes
kubectl rollout restart deployment github-authz-server -n dir-dev-github-authz
```

## Manifests

| File | Description |
|------|-------------|
| `namespace.yaml` | Creates `dir-dev-github-authz` namespace |
| `configmap-authz.yaml` | Authorization rules configuration |
| `configmap-envoy.yaml` | Envoy proxy configuration with ext_authz |
| `deployment-authz.yaml` | GitHub Auth Server deployment + service |
| `deployment-envoy.yaml` | Envoy Gateway deployment + service |
| `kustomization.yaml` | Kustomize configuration for easy deployment |

## Configuration

### Authorization Rules (ConfigMap)

| Key | Description | Example |
|-----|-------------|---------|
| `GITHUB_ALLOWED_ORGS` | Allowed organizations (comma-separated) | `agntcy,spiffe` |
| `GITHUB_ALLOWED_USERS` | Explicitly allowed users | `admin-user` |
| `GITHUB_DENIED_USERS` | Explicitly denied users | `blocked-user` |
| `GITHUB_ALLOWED_TEAMS` | Team restrictions (JSON) | `{"agntcy": ["devs"]}` |
| `AUTHZ_CACHE_TTL` | Cache duration | `5m` |
| `DEBUG` | Enable debug logging | `true` |

### Envoy Configuration

The Envoy gateway is configured to:
- Listen on port 8080 for HTTP requests
- Call the GitHub Auth Server via gRPC ext_authz
- Proxy authorized requests to the Directory API at `dir-dir-dev-argoapp-apiserver.dir-dev-dir.svc.cluster.local:8888`
- Add `x-github-user`, `x-github-orgs` headers to authorized requests

## Troubleshooting

### Check Pod Logs

```bash
# Auth server logs
kubectl logs -n dir-dev-github-authz -l app.kubernetes.io/name=github-authz-server -f

# Envoy logs
kubectl logs -n dir-dev-github-authz -l app.kubernetes.io/name=envoy-gateway -f
```

### Check Envoy Stats

```bash
kubectl port-forward -n dir-dev-github-authz svc/envoy-gateway 9901:9901 &
curl http://localhost:9901/stats | grep ext_authz
```

### Verify Connectivity

```bash
# Test auth server from within cluster
kubectl run -n dir-dev-github-authz test --rm -it --image=curlimages/curl -- \
  curl -v http://github-authz-server:9001/

# Test Directory API
kubectl run -n dir-dev-dir test --rm -it --image=curlimages/curl -- \
  curl -v http://dir-dir-dev-argoapp-apiserver:8888/healthz
```

## Cleanup

```bash
kubectl delete -k poc/github-authz/k8s/
```

## Integration with Directory

This PoC runs as a separate gateway. To integrate it as the primary entry point:

1. Update Ingress to point to Envoy Gateway instead of Directory API
2. Or configure the Directory Helm chart to deploy Envoy as a sidecar

See [docs/github-authz-poc.md](../../../docs/github-authz-poc.md) for the architecture overview.

