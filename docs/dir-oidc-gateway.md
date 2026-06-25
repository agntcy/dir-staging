# Optional OIDC/SPIFFE Authentication Gateway

The default Directory deployment in this repository uses SPIFFE/SPIRE-oriented authentication that works well for in-cluster workloads. If you also want to support `dirctl`, SDKs, or automation running **outside** the cluster, deploy the standalone `oidc-gateway` application alongside `dir`.

The public gateway chart lives in the dedicated repository:

- [agntcy/oidc-gateway](https://github.com/agntcy/oidc-gateway)

This gateway puts Envoy in front of Directory:

1. A remote client presents an OIDC JWT, SPIFFE JWT-SVID, or SPIFFE X.509-SVID.
2. Envoy validates bearer JWTs with `jwt_authn` or downstream SPIFFE mTLS when enabled.
3. The ext-authz service normalizes the caller to a canonical principal and checks allowed gRPC methods.
4. Only authorized requests are forwarded to the internal Directory apiserver with the configured principal header.

## When to Use It

Use the OIDC gateway when:

- You want remote `dirctl` access from a laptop or workstation outside the cluster
- You want a human login flow backed by Dex
- You want GitHub Actions or other external automation to call Directory with OIDC tokens

You do not need this gateway if you only use in-cluster, SPIFFE-based access.

## What to Configure

The staging example includes a separate `oidc-gateway` app under `applications/oidc-gateway/dev/`. The main settings are:

- `envoy.backend.*`: points Envoy at the internal Directory service
- `envoy.oidc.issuers[]`: configures Envoy `jwt_authn` providers and JWKS lookup for bearer-token validation
- `envoy.oidc.github.*`: configures GitHub Actions OIDC for automation
- `authServer.oidc.issuers`: maps verified token issuers to stable provider keys such as `dex` or `github`
- `authServer.oidc.headers.authPrincipal`: sets the canonical principal header forwarded to Directory (`x-auth-principal` by default)
- `authServer.oidc.roles`: maps canonical principals such as `oidc:dex:alice`, `oidc:github:repo:...`, or `spiffe:spiffe://...` to allowed gRPC methods
- `ingress.*`: exposes the Envoy gateway for external access over gRPC

## Dex and Remote Clients

If you want interactive user login, configure Dex in `applications/dex/dev/values.yaml` and make sure:

- `config.issuer` matches the public URL where Dex is reachable
- your GitHub OAuth app credentials are supplied through a Kubernetes Secret
- the Dex issuer values in `applications/dex/dev/values.yaml` and `applications/oidc-gateway/dev/values.yaml` match

Enabling Dex by itself is not enough for remote Directory access. Remote clients also need the standalone `oidc-gateway` deployed so their OIDC tokens can be validated before requests reach Directory.

## Canonical Field Reference

The staging values file is a user-facing example. For the complete public source of truth for all supported fields, see:

- `agntcy/dir/install/charts/dir/values.yaml`
- `agntcy/oidc-gateway/install/charts/oidc-gateway/values.yaml`

## Related Documentation

- [Getting Started](dir-getting-started.md) — deployment paths for this repository
- [Client Onboarding Guide](../onboarding/README.md) — connect clients to the public staging network
