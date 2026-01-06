# Directory - Public Staging Instance

Welcome to the **Directory Public Staging Environment** - a place to develop and test
with the decentralized AI agent discovery network.
This environment provides a fully functional Directory instance for development, testing, and exploration purposes.

## Table of Contents
- [What is Directory?](#-what-is-directory)
- [Architecture Overview](#-architecture-overview)
- [Available Endpoints](#-available-endpoints)
- [Quick Start Guide](#-quick-start-guide)
- [Use Cases](#-use-cases)
- [Troubleshooting](#-troubleshooting)
- [Getting Help](#-getting-help)

## 🎯 What is Directory?

Directory is a decentralized peer-to-peer network that enables:
- **AI Agent Discovery**: Find agents by capabilities like skills, domains, and modules
- **Secure Publication**: Publish agent metadata with cryptographic verification
- **Network Federation**: Connect multiple Directory instances securely
- **Capability Matching**: Match agent capabilities to specific requirements

**Note:** This is a public staging environment for development and testing.

- No SLA or data persistence guarantees
- Not for production use
- Ideal for prototyping, integration, and exploration

## 📊 Architecture Overview

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Your Application  │    │  Directory Network   │    │  Other Federation   │
│                     │    │                      │    │     Members         │
│  ┌─────────────┐    │    │ ┌──────────────────┐ │    │                     │
│  │ Directory   │◄───┼────┼►│ Directory API    │ │    │ ┌─────────────────┐ │
│  │ Client SDK  │    │    │ │ Service          │ │    │ │   Partner Org   │ │
│  └─────────────┘    │    │ └──────────────────┘ │    │ │   Directory     │ │
│                     │    │                      │    │ │   Instances     │ │
│  ┌─────────────┐    │    │ ┌──────────────────┐ │◄───┼─┤                 │ │
│  │ SPIRE Agent │◄───┼────┼►│ SPIRE Server     │ │    │ └─────────────────┘ │
│  └─────────────┘    │    │ │ (Federation)     │ │    │                     │
└─────────────────────┘    │ └──────────────────┘ │    └─────────────────────┘
                           └──────────────────────┘
```

## 🌐 Available Endpoints

| Service              | URL                                   | Purpose                                     |
| -------------------- | ------------------------------------- | ------------------------------------------- |
| **Directory API**    | `https://api.directory.agntcy.org`    | Main API for agent discovery and management |
| **SPIRE Federation** | `https://spire.directory.agntcy.org`  | SPIRE server for secure identity federation |
| **Status Dashboard** | `https://status.directory.agntcy.org` | Real-time service status and monitoring     |

## 🚀 Quick Start Guide

### Prerequisites

Before you begin, ensure you have:
- [ ] **A SPIRE server setup in your organization**
- [ ] Basic understanding of SPIFFE/SPIRE concepts
- [ ] Directory client SDK or CLI tools available

> [!IMPORTANT]
> **Don't have a SPIRE server yet?**
> 
> You need a SPIRE server before connecting to Directory. Choose an option:
> 
> **Option 1: Deploy Your Own Directory Instance** (includes SPIRE)
> - Follow the [Deployment Guide](../README.md) to deploy Directory with SPIRE
> - Then return here to setup federation
> 
> **Option 2: Setup Standalone SPIRE**
> - Install SPIRE in your environment: https://spiffe.io/docs/latest/spire-installing/
> - Then continue with federation setup below
> 
> **Option 3: Quick Testing Without SPIRE**
> - Use token-based authentication (see [Token-based Auth](#token-based-directory-client-authentication-dev) section)
> - Good for prototyping only, not production

### Prepare Your Environment

#### Option 1: Using Directory CLI

1. **Install the CLI**:
   ```bash
   # Using Homebrew (Linux/macOS)
   brew tap agntcy/dir https://github.com/agntcy/dir
   brew install dirctl
   
   # Or download directly from releases
   curl -L https://github.com/agntcy/dir/releases/latest/download/dirctl-linux-amd64 -o dirctl
   chmod +x dirctl
   sudo mv dirctl /usr/local/bin/
   ```

2. **Configure the client**:
   ```bash
   dirctl config set server-address api.directory.agntcy.org
   dirctl config set spiffe-socket-path /tmp/spire-agent/public.sock
   ```

3. **Test the connection**:
   ```bash
   dirctl ping
   # Expected: ✅ Connected to Directory API at api.directory.agntcy.org
   ```

#### Option 2: Using Directory Client SDK

Choose your preferred language:

<details>
<summary><strong>Go SDK</strong></summary>

```go
package main

import (
    "context"
    "log"
    
    "github.com/agntcy/dir/client"
)

func main() {
    // Create client with SPIRE support
    config := &client.Config{
        ServerAddress:     "api.directory.agntcy.org",
        SpiffeSocketPath:  "/tmp/spire-agent/public.sock",
    }
    client, _ := client.New(client.WithConfig(config))

    // Test connection
    _, err := client.Ping(context.Background())
    if err != nil {
        log.Printf("❌ Connection failed: %v", err)
        return
    }

    log.Println("✅ Connected to Directory!")

    // Run workflows...
}
```
</details>

<details>
<summary><strong>Python SDK</strong></summary>

```python
from agntcy.dir_sdk.client import Config, Client

def main():
    # Create client with SPIRE support
    config = Config(
        server_address="api.directory.agntcy.org",
        spiffe_socket_path="/tmp/spire-agent/public.sock"
    )
    client = Client(config)

    # Test connection
    try:
        client.ping()
        print("✅ Connected to Directory!")
    except Exception as e:
        print(f"❌ Connection failed: {e}")

    # Run workflows...

if __name__ == "__main__":
    main()
```
</details>

<details>
<summary><strong>JavaScript SDK</strong></summary>

```javascript
import {Config, Client} from 'agntcy-dir';

async function main() {
    // Create client with SPIRE support
    const config = new Config({
        serverAddress: "api.directory.agntcy.org",
        spiffeEndpointSocket: "/tmp/spire-agent/public.sock",
    });
    const transport = await Client.createGRPCTransport(config);
    const client = new Client(config, transport);

    // Test connection
    try {
        await client.ping();
        console.log('✅ Connected to Directory!');
    } catch (error) {
        console.error('❌ Connection failed:', error.message);
    }

    // Run workflows...
}

main();
```

**Note**: This SDK is intended for Node.js applications only and will not work in web browsers.
</details>

### Federation Setup (Required)

To interact with the Directory, you need to establish a trusted federation between your SPIRE server and the Directory SPIRE server.

Directory supports **two federation profiles** with different infrastructure requirements:

| Profile | SSL Passthrough | Bootstrap Bundle | Best For |
|---------|-----------------|------------------|----------|
| **https_web** | Not required | Not required | Most organizations, cloud deployments |
| **https_spiffe** | Required | Required | Air-gapped environments, zero-trust architectures |

**Recommendation**: Start with **https_web** unless you have specific requirements for https_spiffe.

For detailed comparison and technical guidance, see [Federation Profiles Guide](FEDERATION-PROFILES.md).

---

### Understanding Federation Setup

Federation is **bidirectional** and requires **two federation files**:

```
┌─────────────────────────────────────────────────────────────┐
│                     Federation Setup                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1️⃣ YOUR Federation File (you create & publish)            │
│     File: your-org.com.yaml                                 │
│     Contains: How others connect to YOUR SPIRE              │
│     Action: Submit PR to this repository                    │
│                                                             │
│  2️⃣ DIRECTORY Federation File (you download & deploy)      │
│     File: prod.ads.outshift.io.yaml (already in repo)      │
│     Contains: How YOUR SPIRE connects to Directory          │
│     Action: Deploy this to your cluster                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Important:** Both files are required for successful federation!

---

### Step 1: Choose Your Federation Profile

#### Option A: https_web Profile (Recommended)

**Best for**: Standard cloud deployments, organizations without SSL passthrough

**Requirements**:
- Public DNS for your SPIRE federation endpoint
- cert-manager with Let's Encrypt (or similar CA)
- NGINX ingress controller

**Federation file template**:
```yaml
# onboarding/federation/your-org.com.yaml

#ClassName for SPIRE Controller Manager resource matching
className: dir-spire

# Your organization's trust domain
trustDomain: your-org.com

# Your SPIRE federation endpoint URL
bundleEndpointURL: https://spire.your-org.com

# Federation profile configuration
bundleEndpointProfile:
  type: https_web
```

**That's it!** No bootstrap bundle exchange needed.

---

#### Option B: https_spiffe Profile

**Best for**: Air-gapped environments, pure SPIFFE deployments

**Requirements**:
- NGINX ingress controller with SSL passthrough enabled
- Ability to exchange bootstrap bundles with Directory team

**Federation file template**:
```yaml
# onboarding/federation/your-org.com.yaml

# className for SPIRE Controller Manager resource matching
className: dir-spire

# Your organization's trust domain
trustDomain: your-org.com

# Your SPIRE federation endpoint URL
bundleEndpointURL: https://spire.your-org.com

# Federation profile configuration
bundleEndpointProfile:
  type: https_spiffe
  endpointSPIFFEID: spiffe://your-org.com/spire/server

# Your SPIRE server trust bundle (required for https_spiffe)
trustDomainBundle: |-
  {
    "keys": [
      {
        "use": "x509-svid",
        "kty": "RSA",
        "n": "your-public-key-here...",
        "e": "AQAB",
        "x5c": ["your-certificate-chain-here..."]
      }
    ]
  }
```

**How to get your trust bundle**:
```bash
# Extract your SPIRE server trust bundle
kubectl exec -n your-spire-namespace deployment/spire-server -c spire-server -- \
  /opt/spire/bin/spire-server bundle show -format spiffe > your-trust-bundle.json

# The output goes into the trustDomainBundle field above
cat your-trust-bundle.json
```

---

### Understanding className

You'll notice both federation templates include a `className` field:

```yaml
className: dir-spire
```

**What is className?**
- A label that tells the SPIRE Controller Manager which resources belong to your SPIRE installation
- Used to match `ClusterSPIFFEID` and `ClusterFederatedTrustDomain` resources to your SPIRE server
- Think of it as a "namespace" for SPIRE resources within your cluster

**What value should I use?**

For most users: **Use `dir-spire`** (the standard value)

This value must match in THREE places:
1. ✅ Your federation file: `className: dir-spire`
2. ✅ Your SPIRE deployment: `applications/spire/*/values.yaml`
   ```yaml
   controllerManager:
     className: "dir-spire"
   ```
3. ✅ Your DIR deployment: `applications/dir/*/values.yaml`
   ```yaml
   apiserver:
     spire:
       className: dir-spire
   ```

**⚠️ Important:**
- If you deployed Directory using this repository's configs, `dir-spire` is already configured
- If you have a custom SPIRE setup with a different className, use that value instead
- All three places MUST have the same value for federation to work

**Troubleshooting:**
- If federation isn't working, verify className matches across all three locations
- Check SPIRE Controller Manager logs for "no matching className" errors

---

### Step 2: Submit Federation Request

1. **Fork the repository**: Go to https://github.com/agntcy/dir-staging and click "Fork"

2. **Create your federation file**:
   ```bash
   git clone https://github.com/your-username/dir-staging.git
   cd dir-staging/onboarding/federation/
   
   # Copy the appropriate template based on your chosen profile
   # For https_web (recommended):
   cp .federation.web.template.yaml your-org.com.yaml
   
   # Or for https_spiffe:
   cp .federation.spiffe.template.yaml your-org.com.yaml
   
   # Edit your-org.com.yaml with your details
   vim your-org.com.yaml
   ```

3. **Submit a Pull Request**:
   - Title: `federation: add <your-org.com>`
   - Description: Brief description of your organization and use case
   - Files: `onboarding/federation/your-org.com.yaml`

---

### Step 3: Configure Your SPIRE Server

After your federation request is approved, configure your SPIRE server to federate with Directory:

1. **Obtain Directory's federation file**: Download `prod.ads.outshift.io.yaml` from the [federation directory](federation/)

2. **Deploy to your cluster**: Use your preferred deployment method (Helm, ArgoCD, etc.) to apply the federation configuration

3. **Verify federation**:
   ```bash
   # Check SPIRE server logs for bundle refresh
   kubectl logs -n your-spire-namespace -l app.kubernetes.io/name=server -c spire-server | grep "Bundle refreshed"
   
   # Expected output:
   # level=info msg="Bundle refreshed" trust_domain=prod.ads.outshift.io
   ```

---

### Step 4: Verify Federation

Once federation is established, verify connectivity:

```bash
# Check federation status on your SPIRE server
kubectl exec -n your-spire-namespace deployment/spire-server -c spire-server -- \
  /opt/spire/bin/spire-server federation list

# Should show Directory trust domain
# Trust Domain: prod.ads.outshift.io

# Test Directory API connection
dirctl ping
# Expected: ✅ Connected to Directory API at api.directory.agntcy.org
```

## 📚 Use Cases

You can find various usage examples at [docs.agntcy.org](https://docs.agntcy.org/dir/scenarios/).

## 🔧 Troubleshooting

### Connection Issues

**Problem**: Cannot connect to Directory API
```bash
# Check SPIRE agent status
spire-agent api fetch x509-svid

# Verify network connectivity
curl -v https://api.directory.agntcy.org

# Check client configuration
dirctl config list
```

### Federation Issues

**Problem**: SPIRE federation not working
```bash
# Verify trust bundle exchange
spire-server federation show --trustDomain dir.agntcy.org

# Test bundle endpoint connectivity
curl https://spire.directory.agntcy.org/
```

### Common Error Messages

| Error                                           | Solution                                                   |
| ----------------------------------------------- | ---------------------------------------------------------- |
| `connection refused`                            | Check if SPIRE agent is running and socket path is correct |
| `x509: certificate signed by unknown authority` | Verify trust bundle configuration                          |
| `context deadline exceeded`                     | Check network connectivity and firewall settings           |
| `permission denied`                             | Ensure proper SPIFFE ID registration and policies          |

## 🆘 Getting Help

### Community Support
- **GitHub Issues**: [Open an issue](https://github.com/agntcy/dir/issues) for bugs and feature requests
- **Discussions**: [GitHub Discussions](https://github.com/agntcy/dir/discussions) for questions and community help
- **Documentation**: [Full Documentation](https://docs.agntcy.org/dir/overview/)

---

**Ready to get started?** 🎉 Follow the [Quick Start Guide](https://docs.agntcy.org/dir/getting-started/) or
check out our [Usage and Examples](https://docs.agntcy.org/dir/scenarios/) for sample applications!
