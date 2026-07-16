# Validation Steps

## Login
Users can now:
  • Authenticate with Google OAuth via gcloud auth print-identity-token
  • Access the Directory API via the OIDC gateway
  • Use dirctl with --auth-token flag
  • Perform all Directory operations (search, push, pull, etc.)

```
dirctl \
  --server-addr gateway.dir.dev.agntcy-research-dell.com:443 \
  --auth-token "$(gcloud auth print-identity-token)" \
  search
```

## Anonymous directly to DIR (via port-forward)
```
kubectl -n dir port-forward svc/dir-apiserver 8888:8888
```

```
dirctl \
  --server-addr localhost:8888 \
  --auth-mode none \
  search
```