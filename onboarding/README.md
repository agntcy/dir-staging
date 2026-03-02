# Directory - Public Staging Instance

Welcome to the **Directory Public Staging Environment** for development and testing with the decentralized AI agent discovery network.

> **Note:** This is a public staging environment. No SLA or data persistence guarantees. Not for production use.

## What You'll Do

1. **Install dirctl** (CLI tool)
2. **Set up federation** between your SPIRE server and the public Directory's SPIRE (required before any API calls work)
3. **Verify** with a test query

Federation is required before you can discover or publish agents. The test in step 3 will fail until federation is complete.

## Table of Contents

- [Available Endpoints](#-available-endpoints)
- [Prerequisites](#-prerequisites)
- [Step 1: Install dirctl](#step-1-install-dirctl)
- [Step 2: Federation Setup](#step-2-federation-setup)
- [Step 3: Verify](#step-3-verify)
- [Getting Help](#-getting-help)

## 🌐 Available Endpoints

| Service              | URL                                      | Purpose                                     |
| -------------------- | ---------------------------------------- | ------------------------------------------- |
| **Directory API**    | `https://prod.api.ads.outshift.io`       | Main API for agent discovery and management |
| **SPIRE Federation** | `https://prod.spire.ads.outshift.io`     | SPIRE server for secure identity federation |
| **Status Dashboard** | `https://prod.status.ads.outshift.io`    | Real-time service status and monitoring     |

## 🎯 Prerequisites

- **SPIRE server** in your environment. If you don't have one:
  - Deploy a minimal instance: [Getting Started](https://docs.agntcy.org/dir/getting-started/) (Helm or Argo CD)
  - Or install standalone SPIRE: [spiffe.io/docs](https://spiffe.io/docs/latest/spire-installing/)
- **SPIRE agent** running with the Workload API socket (e.g. `/tmp/spire-agent/public.sock`)

## Step 1: Install dirctl

```bash
brew tap agntcy/dir https://github.com/agntcy/dir
brew install dirctl
```

For SDK usage (Go, Python, JavaScript), see [Getting Started](https://docs.agntcy.org/dir/getting-started/).

## Step 2: Federation Setup

To interact with Directory, establish federation between your SPIRE server and Directory's SPIRE server.

**Two federation profiles** are supported:

| Profile       | Best For                                      |
| ------------- | --------------------------------------------- |
| **https_web** | Most organizations, cloud deployments         |
| **https_spiffe** | Air-gapped environments, zero-trust architectures |

See [Federation Profiles](https://docs.agntcy.org/dir/federation-profiles/) for comparison and technical details.

### dir-staging Workflow

1. **Copy a template** (from the dir-staging repo root):
   ```bash
   cd onboarding/federation
   cp .federation.web.template.yaml your-org.com.yaml   # or .federation.spiffe.template.yaml
   ```

2. **Edit** `your-org.com.yaml` with your trust domain, bundle endpoint URL, and profile settings.

3. **Submit a PR** to this repo with your federation file. After merge, prod will accept connections from your trust domain.

4. **Configure your SPIRE** to federate with Directory:
   - **If you deploy from this repo:** run `task gen:dir` to regenerate `applications/dir/gen.values.yaml`; ArgoCD will sync.
   - **If you have a custom deployment:** add Directory's federation config to your SPIRE. Use [federation/prod.ads.outshift.io.yaml](federation/prod.ads.outshift.io.yaml) as reference; add a `ClusterFederatedTrustDomain` (or equivalent) for `prod.ads.outshift.io`.

For full federation setup, [Partner Federation with Prod](https://docs.agntcy.org/dir/partner-prod-federation/) and [Federation Troubleshooting](https://docs.agntcy.org/dir/federation-troubleshooting/).

## Step 3: Verify

Once federation is complete, test:

```bash
dirctl pull bafytest123 \
  --server-addr prod.api.ads.outshift.io \
  --spiffe-socket-path /tmp/spire-agent/public.sock
# Expected: Error: record not found (proves connection and federation work)
```

Replace `/tmp/spire-agent/public.sock` with your SPIRE agent socket path if different.

## 🆘 Getting Help

- **Documentation**: [docs.agntcy.org/dir](https://docs.agntcy.org/dir/overview/)
- **GitHub Issues**: [agntcy/dir](https://github.com/agntcy/dir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/agntcy/dir/discussions)
