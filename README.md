# Directory Deployment

This repository contains the deployment manifests for AGNTCY Directory project and serves as the **federation registry** for the public staging network. It is designed to be used with Argo CD for GitOps-style continuous deployment.

The manifests are organized into two main sections:
- `projects/`: Contains Argo CD project definitions.
- `projectapps/`: Contains Argo CD application definitions.

The project will deploy the following components:
- `applications/dir` - AGNTCY Directory server with storage backend (v1.3.0)
- `applications/oidc-gateway` - optional standalone OIDC/SPIFFE gateway for external `dirctl` / SDK / automation access (v1.0.0)
- `applications/spire*` - SPIRE stack for identity and federation (with SPIFFE CSI driver)

**NOTE**: This is not a production-ready deployment. It is
provided as-is for demonstration and testing purposes.

**Latest Version**: v1.3.0 - See [CHANGELOG.md](CHANGELOG.md) for what's new.

## Documentation

| Topic | Link |
|-------|------|
| Getting Started | [docs/dir-getting-started.md](docs/dir-getting-started.md) |
| OIDC/SPIFFE Gateway | [docs/dir-oidc-gateway.md](docs/dir-oidc-gateway.md) |
| Client Onboarding | [onboarding/README.md](onboarding/README.md) |
| Partner Federation with Prod | [docs/dir-federation-setup.md](docs/dir-federation-setup.md) |
| Federation Profiles | [docs/dir-federation-profiles.md](docs/dir-federation-profiles.md) |
| Federation Troubleshooting | [docs/dir-federation-troubleshooting.md](docs/dir-federation-troubleshooting.md) |
| Helm / GitOps Deployment | [docs.agntcy.org/dir/getting-started](https://docs.agntcy.org/dir/getting-started/) |
| Production Deployment | [docs.agntcy.org/dir/prod-deployment](https://docs.agntcy.org/dir/prod-deployment/) |

---

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License. See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
