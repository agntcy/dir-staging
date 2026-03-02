# Directory Deployment

This repository contains the deployment manifests for AGNTCY Directory project and serves as the **federation registry** for the public staging network. It is designed to be used with Argo CD for GitOps-style continuous deployment.

The manifests are organized into two main sections:
- `projects/`: Contains Argo CD project definitions.
- `projectapps/`: Contains Argo CD application definitions.

The project will deploy the following components:
- `applications/dir` - AGNTCY Directory server with storage backend (v1.0.0)
- `applications/dir-admin` - AGNTCY Directory Admin CLI client (v1.0.0)
- `applications/spire*` - SPIRE stack for identity and federation (with SPIFFE CSI driver)

**NOTE**: This is not a production-ready deployment. It is
provided as-is for demonstration and testing purposes.

**Latest Version**: v1.0.0 - See [CHANGELOG.md](CHANGELOG.md) for what's new.

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
