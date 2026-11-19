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
| Terraform Deployment | [terraform/environments/public-peering/README.md](terraform/environments/public-peering/README.md) |

## Dependency Updates

Renovate opens PRs for the chart and image versions of the Argo CD applications, and for the GitHub Actions. It runs from the [Dependencies](.github/workflows/dependencies.yaml) workflow on the schedule in [renovate.json](renovate.json).

- Chart versions are read from each `applications/<app>/<env>/config.json`.
- Image tags in `values.yaml` are tracked only when a comment names the image, because most of them take the repository from the chart:

  ```yaml
  image:
    # renovate: datasource=docker depName=ghcr.io/spiffe/spire-server
    tag: "1.16.0"
  ```

  Add the comment when you pin a new image. A `digest:` on the line after `tag:` is updated too.
- A chart and its images move in one PR (dir, oidc-gateway, SPIRE, Dex). Major updates are not proposed.

Run `task deps:renovate:sync RENOVATE_OPTS='--dry-run=lookup'` to see what Renovate would update without touching GitHub.

---

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License. See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
