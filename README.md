# Directory Deployment

This repository contains the deployment manifests for AGNTCY Directory project and serves as the **federation registry** for the public staging network. It is designed to be used with Argo CD for GitOps-style continuous deployment.

The manifests are organized into two main sections:
- `projects/`: Contains Argo CD project definitions.
- `projectapps/`: Contains Argo CD application definitions.

The project will deploy the following components:
- `applications/dir` - AGNTCY Directory server with storage backend (v1.2.0)
- `applications/dir-admin` - AGNTCY Directory Admin CLI client (v1.2.0)
- `applications/spire*` - SPIRE stack for identity and federation (with SPIFFE CSI driver)

**NOTE**: This is not a production-ready deployment. It is
provided as-is for demonstration and testing purposes.

**Latest Version**: v1.2.0 - See [CHANGELOG.md](CHANGELOG.md) for what's new.

## Getting Started

Choose your path based on your goal:

### 📍 I want to use Directory (connect to public staging)

**Goal:** Connect your application to the existing Directory network to discover agents.

**Prerequisites:** You'll need a SPIRE server in your environment.

**Next Step:** Follow the [Client Onboarding Guide](onboarding/README.md)

---

### 🚀 I want to deploy my own Directory instance

**Goal:** Run your own Directory instance for local testing or private deployment.

**Prerequisites:** Kubernetes cluster (Kind, Minikube, or cloud provider)

**Next Step:** See [Getting Started](https://docs.agntcy.org/dir/getting-started/) (Helm or GitOps/Argo CD)

---

### 🌐 I want to deploy AND join the public network

**Goal:** Run your own Directory instance and federate with the public staging network.

**Prerequisites:** Kubernetes cluster + SPIRE knowledge

**Next Steps:**
1. Deploy your Directory instance (see [Getting Started](https://docs.agntcy.org/dir/getting-started/))
2. Setup federation (see [Client Onboarding Guide](onboarding/README.md) after deployment)

---

## Optional OIDC Authentication Add-On

The default Directory deployment in this repository uses SPIFFE/SPIRE-oriented authentication that works well for in-cluster workloads. If you also want to support `dirctl`, SDKs, or automation running **outside** the cluster, enable the optional OIDC add-on in `applications/dir/dev/values.yaml`.

This add-on puts an Envoy gateway in front of Directory:

1. A remote client gets an OIDC token from your identity provider.
2. Envoy validates the JWT using the configured issuer and JWKS settings.
3. The ext-authz service maps token claims to roles and allowed gRPC methods.
4. Only authorized requests are forwarded to the internal Directory apiserver.

### When to Use It

Use the OIDC add-on when:

- You want remote `dirctl` access from a laptop or workstation outside the cluster
- You want a human login flow backed by Dex
- You want GitHub Actions or other external automation to call Directory with OIDC tokens

Keep it disabled if you only need in-cluster, SPIFFE-based access.

### What to Configure

The staging example now includes a fully commented, opt-in OIDC block in `applications/dir/dev/values.yaml`. The main settings are:

- `apiserver.envoyAuthz.enabled`: installs the optional Envoy/ext-authz add-on
- `apiserver.envoy-authz.envoy.backend.*`: points Envoy at the internal Directory service
- `apiserver.envoy-authz.envoy.oidc.dex.*`: configures Dex as the human/user OIDC issuer
- `apiserver.envoy-authz.envoy.oidc.github.*`: configures GitHub Actions OIDC for automation
- `apiserver.envoy-authz.authServer.oidc.issuers`: maps issuers to principal types such as `user` or `github`
- `apiserver.envoy-authz.authServer.oidc.roles`: maps users, clients, or workflows to allowed gRPC methods
- `apiserver.envoy-authz.ingress.*`: exposes the Envoy gateway for external access over gRPC

### Dex and Remote Clients

If you want interactive user login, configure Dex in `applications/dex/dev/values.yaml` and make sure:

- `config.issuer` matches the public URL where Dex is reachable
- your GitHub OAuth app credentials are supplied through a Kubernetes Secret
- the Dex issuer values in `applications/dex/dev/values.yaml` and `applications/dir/dev/values.yaml` match

Enabling Dex by itself is not enough for remote Directory access. Remote clients also need the Envoy/ext-authz add-on enabled so their OIDC tokens can be validated before requests reach Directory.

### Canonical Field Reference

The staging values file is a user-facing example. For the complete public source of truth for all supported fields, see:

- `agntcy/dir/install/charts/dir/apiserver/values.yaml`
- `agntcy/dir/install/charts/envoy-authz/values.yaml`

---

## Next Steps: Connecting to the Directory Network

After deploying your Directory instance (see [Getting Started](https://docs.agntcy.org/dir/getting-started/)), it will be **isolated** and cannot discover agents from other organizations.

### Why Join the Network?

**Current State (Standalone):**
- ✅ Your Directory works for your organization
- ❌ Cannot discover agents from other organizations
- ❌ Your agents are not discoverable by others
- ❌ Limited to your own trust domain

**After Federation:**
- ✅ All standalone benefits
- ✅ Discover agents across multiple organizations
- ✅ Your agents become globally discoverable
- ✅ Part of decentralized discovery network

### How to Setup Federation

Federation requires configuring SPIRE to exchange trust bundles with other Directory instances.

**Follow these steps:**

1. **Choose a Federation Profile**
   - **https_web** (recommended): Uses standard HTTPS + Let's Encrypt, no SSL passthrough needed
   - **https_spiffe**: Uses SPIFFE mTLS, requires SSL passthrough and bootstrap bundle exchange
   
   See [Federation Profiles](https://docs.agntcy.org/dir/federation-profiles/) for detailed comparison.

2. **Create Your Federation File**
   - Describes how others can connect to your SPIRE federation endpoint
   - Template: `onboarding/federation/.federation.web.template.yaml` (or `.federation.spiffe.template.yaml`)
   - Example: See `onboarding/federation/prod.ads.outshift.io.yaml` for reference

3. **Submit Your Federation File**
   - Fork this repository
   - Add your file to `onboarding/federation/your-domain.com.yaml`
   - Submit a Pull Request

4. **Deploy Directory's Federation File**
   - After approval, deploy `onboarding/federation/prod.ads.outshift.io.yaml` to your cluster
   - Run `task gen:dir` to regenerate `applications/dir/gen.values.yaml`
   - ArgoCD will automatically sync the federation configuration
   - This tells your SPIRE how to connect to the Directory network

**Complete Instructions:** See the [Client Onboarding Guide](onboarding/README.md) for step-by-step federation setup.

---

## Documentation

| Topic | Link |
|-------|------|
| Getting Started | [docs.agntcy.org/dir/getting-started](https://docs.agntcy.org/dir/getting-started/) |
| Partner Federation with Prod | [docs.agntcy.org/dir/partner-prod-federation](https://docs.agntcy.org/dir/partner-prod-federation/) |
| Federation Profiles | [docs.agntcy.org/dir/federation-profiles](https://docs.agntcy.org/dir/federation-profiles/) |
| Federation Troubleshooting | [docs.agntcy.org/dir/federation-troubleshooting](https://docs.agntcy.org/dir/federation-troubleshooting/) |
| Production Deployment | [docs.agntcy.org/dir/prod-deployment](https://docs.agntcy.org/dir/prod-deployment/) |

---

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License. See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
