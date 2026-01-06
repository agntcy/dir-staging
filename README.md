# Directory Deployment

This repository contains the deployment manifests for AGNTCY Directory project.
It is designed to be used with Argo CD for GitOps-style continuous deployment.

The manifests are organized into two main sections:
- `projects/`: Contains Argo CD project definitions.
- `projectapps/`: Contains Argo CD application definitions.

The project will deploy the following components:
- `applications/dir` - AGNTCY Directory server with storage backend (v0.5.5)
- `applications/dir-admin` - AGNTCY Directory Admin CLI client (v0.5.5)
- `applications/spire*` - SPIRE stack for identity and federation (with SPIFFE CSI driver)

**NOTE**: This is not a production-ready deployment. It is
provided as-is for demonstration and testing purposes.

**Latest Version**: v0.5.5 - See [CHANGELOG.md](CHANGELOG.md) for what's new.

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

**Next Step:** Continue with [Quick Start (Development)](#quick-start-development-environment) below

---

### 🌐 I want to deploy AND join the public network

**Goal:** Run your own Directory instance and federate with the public staging network.

**Prerequisites:** Kubernetes cluster + SPIRE knowledge

**Next Steps:**
1. Deploy your Directory instance (see [Quick Start](#quick-start-development-environment) below)
2. Setup federation (see [Client Onboarding Guide](onboarding/README.md) after deployment)

---

## Quick Start (Development Environment)

> [!NOTE]
> This guide sets up the **development environment** for local testing and development.
> It uses a local Kind cluster with NodePort services and simplified security.
> For production deployment with Ingress and TLS, see the [Production Setup](#production-setup) section below.

> [!NOTE]
> **Trust Domain for Quick Start:** This deployment uses `example.org` as the trust domain for local testing.
> 
> **This is fine for:**
> - ✅ Local testing and development
> - ✅ Learning Directory features
> - ✅ Prototyping applications
> 
> **Need a custom trust domain?**
> - For production deployment: See [Production Setup](#production-setup) section
> - For federation with Directory network: Fork this repo, customize, and deploy from your fork
> - **Remember:** Trust domain cannot be changed after deployment

This guide demonstrates how to set up AGNTCY Directory project using
Argo CD in Kubernetes [Kind](https://kind.sigs.k8s.io/) cluster.

1. Create Kind cluster

```bash
kind create cluster --name dir-dev
```

2. Install Argo CD in the cluster

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --namespace argocd --for=condition=available deployment --all --timeout=120s
```

3. Deploy Directory via ArgoCD

```bash
# Add project
kubectl apply -f https://raw.githubusercontent.com/agntcy/dir-staging/main/projects/dir/dev/dir-dev.yaml

# Add application
kubectl apply -f https://raw.githubusercontent.com/agntcy/dir-staging/main/projectapps/dir/dev/dir-dev-projectapp.yaml

# Wait for SPIRE components to be ready
echo "Waiting for SPIRE to be ready..."
kubectl wait --for=condition=ready pod -n dir-dev-spire -l app.kubernetes.io/name=server --timeout=240s
kubectl wait --for=condition=ready pod -n dir-dev-spire -l app.kubernetes.io/name=agent --timeout=240s

# Wait for Directory components to be ready
echo "Waiting for Directory to be ready..."
kubectl wait --for=condition=ready pod -n dir-dev-dir -l app.kubernetes.io/name=apiserver --timeout=240s

echo "✅ Directory deployment complete!"
```

4. Check results in ArgoCD UI

```bash
# Retrieve password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo

# Port forward the ArgoCD API to localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Login to the UI at [https://localhost:8080](https://localhost:8080) with username `admin` and the password retrieved above.

Verify deployment by checking the results of CronJobs in `dir-admin` application.

---

### ✅ What You've Successfully Deployed

Congratulations! You now have a **standalone Directory instance** running with:

**Core Components:**
- ✅ **Directory Server** (`dir-dev-dir` namespace)
  - API endpoint for agent discovery and management
  - Running in isolated mode (not connected to any network)
- ✅ **SPIRE Server** (`dir-dev-spire` namespace)
  - Provides cryptographic identities (SPIFFE IDs) to your workloads
  - Trust domain: `example.org` (or your configured domain)
- ✅ **SPIRE Agent** (DaemonSet on all nodes)
  - Attests workload identities
  - Provides SVIDs via SPIFFE Workload API
- ✅ **Directory Admin CLI** (`dir-dev-dir` namespace)
  - Automated management tasks via CronJobs
  - Pre-configured with SPIRE authentication

**Current Status:**
- 🟢 **Working:** Your Directory instance is fully operational
- 🟡 **Isolated:** Not connected to other Directory instances
- 🔴 **Not Federated:** Cannot discover agents from other organizations

**What You Can Do Now:**

1. **Test Locally:**
   - Use the Directory Admin CLI running in your cluster
   - Create and query agent records
   - Test the API functionality

2. **Connect Your Applications:**
   - Deploy workloads that need SPIRE identities
   - Use the [Token-based Authentication](#token-based-directory-client-authentication-dev) section below for testing

3. **Want to Join the Directory Network?**
   - ⚠️ **Important:** This Quick Start uses `example.org` trust domain, which is for **local testing only**
   - **To federate with the Directory network, you need a unique trust domain**
   - **Two options to federate:**
     - **Option A (Recommended):** Deploy fresh using [Production Setup](#production-deployment) with your own trust domain
     - **Option B (Advanced):** Fork this repo, change trust domain in configs, redeploy from your fork
   - See: [Client Onboarding Guide](onboarding/README.md) for complete federation requirements

**What's Missing?**
- ❌ **Federation:** Your instance can't communicate with other Directory instances
- ❌ **External Access:** Services accessible only within the cluster
- ❌ **Production Features:** Persistent storage, TLS ingress, proper secrets management

**Next Steps:**
- **Want to join the network?** → Need custom trust domain first (see [Production Deployment](#production-deployment))
- **Want production features?** → See [Production Deployment](#production-deployment) section below
- **Want to test locally first?** → Continue with [Token-based Auth](#token-based-directory-client-authentication-dev) below

---

5. Clean up

```bash
kind delete cluster --name dir-dev
```

### Token-based Directory Client Authentication (Dev)

In some cases, you may want to use Directory Client locally
without SPIRE stack.
In this case, you can use token-based authentication
using SPIFFE X509 SVID tokens.

To generate a SPIFFE SVID token for authenticating local Directory Client
with the Directory Server in the dev environment, follow these steps:

1. Create a SPIFFE SVID for local Directory Client

```bash
kubectl exec spire-dir-dev-argoapp-server-0 -n dir-dev-spire -c spire-server -- \
   /opt/spire/bin/spire-server x509 mint \
   -dns dev.api.example.org \
   -spiffeID spiffe://example.org/local-client \
   -output json > spiffe-dev.json
```

2. Set SPIFFE Token variable for Directory Client

```bash
# Set authentication method to token
export DIRECTORY_CLIENT_AUTH_MODE="token"
export DIRECTORY_CLIENT_SPIFFE_TOKEN="spiffe-dev.json"

# Set Directory Server address and skip TLS verification
export DIRECTORY_CLIENT_SERVER_ADDRESS="127.0.0.1:8888"
export DIRECTORY_CLIENT_TLS_SKIP_VERIFY="true"
```

3. Port-forward Directory Server API

```bash
kubectl port-forward svc/dir-dir-dev-argoapp-apiserver -n dir-dev-dir 8888:8888
```

4. Run Directory Client

```bash
dirctl info baeareiesad3lyuacjirp6gxudrzheltwbodtsg7ieqpox36w5j637rchwq
```

## Production Deployment

This example configuration uses simplified settings for local Kind/Minikube testing.
For production deployment, consider these enhancements:

> [!IMPORTANT]
> **Before Production Deployment:** Choose your **trust domain** carefully - it cannot be changed later!
> 
> A trust domain is a permanent identifier for your SPIRE deployment (e.g., `acme.com`, `engineering.acme.com`).
> 
> **To customize the trust domain:**
> 1. Fork this repository
> 2. Edit `applications/spire/prod/values.yaml`:
>    ```yaml
>    global:
>      spire:
>        trustDomain: "your-domain.com"  # Replace example.org
>    ```
> 3. Commit and push to your fork
> 4. Deploy from your fork instead of `agntcy/dir-staging`
> 
> **Trust Domain Requirements:**
> - Must be globally unique
> - Cannot be changed after deployment
> - Doesn't need to be a real DNS domain (but can be)
> - Will be visible to federation partners

### This Example vs Production

| Feature | This Example (Kind) | Production |
|---------|---------------------|------------|
| **SPIFFE CSI Driver** | ✅ Enabled (v0.5.5+) | ✅ Enabled |
| **Storage** | emptyDir (ephemeral) | PVCs (persistent) |
| **Deployment Strategy** | Recreate (default) | Recreate (required with PVCs) |
| **Credentials** | Hardcoded in values.yaml | ExternalSecrets + Vault |
| **Resources** | 250m/512Mi | 500m-2000m / 1-4Gi |
| **Ingress** | NodePort (local) | Ingress + TLS |
| **Rate Limits** | 50 RPS | 500+ RPS |
| **Trust Domain** | example.org | your-domain.com |
| **Read-Only FS** | No (emptyDir) | Yes (with PVCs) |

**This configuration is optimized for local testing. For production, enable the optional features documented below.**

### Key Production Features

**SPIFFE CSI Driver** (v0.5.5+):
- Enabled by default via `spire.useCSIDriver: true`
- Provides synchronous workload identity injection
- Eliminates authentication race conditions ("certificate contains no URI SAN" errors)
- More secure than hostPath mounts in workload containers

**Persistent Storage**:
- Enable PVCs for routing datastore and database (v0.5.2+)
- Prevents data loss across pod restarts
- See `pvc.create` and `database.pvc.enabled` in values.yaml
- **IMPORTANT**: When using PVCs, set `strategy.type: Recreate` to prevent database lock conflicts

**Secure Credential Management**:
- Use ExternalSecrets Operator with Vault instead of hardcoded secrets
- See commented ExternalSecrets configuration in values.yaml
- Reference: agntcy-deployment repository for production patterns

**Resource Sizing**:
- Increase limits based on expected load (CPU: 500m-2000m, Memory: 1-4Gi)
- Monitor and adjust after observing production traffic

**Ingress & TLS**:
- Configure Ingress for external access
- Use cert-manager with Let's Encrypt for production certificates
- For SPIRE federation: Choose https_web (recommended, no SSL passthrough) or https_spiffe (requires SSL passthrough)
- See [Federation Profiles Guide](onboarding/FEDERATION-PROFILES.md) for detailed comparison

### Minikube Production Simulation

If you wish to test production-like setup locally with Ingress and TLS,
follow the steps below using Minikube.

> [!NOTE]
> We are using Minikube to simulate production setup,
as it supports Ingress and TLS out of the box.
Steps below marked as (local) are optional and intended
for local testing purposes only.

> [!CAUTION]
> It is not recommended to deploy both dev and prod environments
in the same cluster, as they may conflict with each other.

<details>
<summary><strong>View Production Setup</strong></summary>

<br/>

1. Create Minikube cluster

```bash
minikube start -p dir-prod
```

2. (local) Enable Ingress and DNS addons in Minikube

The deployment uses `*.test` domain for Ingress resources. 

For local testing purposes, Minikube Ingress controller is required to route traffic to our Ingress resources.

Otherwise, if you are deploying to a cloud provider with its own Ingress controller,
you may not need these steps (see federation profile documentation).

```bash
# Enable Ingress and Ingress-DNS addons
minikube addons enable ingress -p dir-prod
minikube addons enable ingress-dns -p dir-prod

# (Optional) Enable SSL Passthrough - only required for https_spiffe federation profile
# If using https_web profile (recommended), you can skip this step
kubectl patch deployment -n ingress-nginx ingress-nginx-controller --type='json' \
-p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--enable-ssl-passthrough"}]'
```

3. (local) Enable Local DNS inside Minikube

The deployment uses `*.test` domain for Ingress resources. 

For local testing purposes, we need to configure DNS resolution
inside Minikube cluster to resolve `*.test` domain to Minikube IP address
using [minikube/ingress-dns](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns) guide.

Otherwise, if you are deploying to a cloud provider with its own Ingress controller,
you can skip this step.

```bash
# Get Minikube IP
minikube ip -p dir-prod

# Add DNS resolver entry for `*.test` domain
# Follow guide at: https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns

# Update CoreDNS ConfigMap to forward `test` domain to Minikube IP
kubectl edit configmap coredns -n kube-system
```

4. (local) Install CertManager with Self-Signed Issuer

The deployment uses CertManager `letsencrypt` issuer to issue TLS certificates for Ingress resources.

For local testing purposes, we will create a self-signed root CA certificate
and configure CertManager to use it as `letsencrypt` issuer.

Otherwise, if you are deploying to a cloud provider with its own CertManager,
you can skip this step, but ensure that `letsencrypt` issuer is available.

```bash
# Install Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.1/cert-manager.yaml

# Wait for Cert-Manager to be ready
kubectl wait --namespace cert-manager --for=condition=available deployment --all --timeout=120s

# Create Self-Signed Issuer and Root CA Certificate
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
   name: selfsigned-issuer
spec:
   selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
   name: my-selfsigned-ca
   namespace: cert-manager
spec:
   isCA: true
   commonName: my-selfsigned-ca
   secretName: root-secret
   privateKey:
      algorithm: ECDSA
      size: 256
   issuerRef:
      name: selfsigned-issuer
      kind: ClusterIssuer
      group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
   name: letsencrypt
spec:
   ca:
      secretName: root-secret
EOF
```

5. Install Argo CD in the cluster

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --namespace argocd --for=condition=available deployment --all --timeout=120s
```

6. Deploy Directory via ArgoCD

```bash
# Add project
kubectl apply -f https://raw.githubusercontent.com/agntcy/dir-staging/main/projects/dir/prod/dir-prod.yaml

# Add application
kubectl apply -f https://raw.githubusercontent.com/agntcy/dir-staging/main/projectapps/dir/prod/dir-prod-projectapp.yaml
```

7. Check results in ArgoCD UI:

```bash
# Retrieve password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo

# Port forward the ArgoCD API to localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Login to the UI at [https://localhost:8080](https://localhost:8080) with username `admin` and the password retrieved above.

Verify deployment by checking the results of CronJobs in `dir-admin` application.

8. Clean up

```bash
minikube delete -p dir-prod
```

### Token-based Directory Client authentication

To generate a SPIFFE SVID token for authenticating local Directory Client
with the Directory Server, follow these steps:

1. Create a SPIFFE SVID for local Directory Client

```bash
kubectl exec spire-dir-prod-argoapp-server-0 -n dir-prod-spire -c spire-server -- \
   /opt/spire/bin/spire-server x509 mint \
   -dns prod.api.example.org \
   -spiffeID spiffe://example.org/local-client \
   -output json > spiffe-prod.json
```

2. Set SPIFFE Token variable for Directory Client

```bash
# Set authentication method to token
export DIRECTORY_CLIENT_AUTH_MODE="token"
export DIRECTORY_CLIENT_SPIFFE_TOKEN="spiffe-prod.json"

# Set Directory Server address (via Ingress)
export DIRECTORY_CLIENT_SERVER_ADDRESS="prod.api.example.org:443"

# Or, set Directory Server address and skip TLS verification (via port-forwarding)
export DIRECTORY_CLIENT_SERVER_ADDRESS="127.0.0.1:8888"
export DIRECTORY_CLIENT_TLS_SKIP_VERIFY="true"
```

3. Port-forward Directory Server API

```bash
kubectl port-forward svc/dir-dir-prod-argoapp-apiserver -n dir-prod-dir 8888:8888
```

4. Run Directory Client

```bash
dirctl info baeareiesad3lyuacjirp6gxudrzheltwbodtsg7ieqpox36w5j637rchwq
```

</details>

---

## Next Steps: Connecting to the Directory Network

You've successfully deployed your own Directory instance! However, it's currently **isolated** and cannot discover agents from other organizations.

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
   
   See [Federation Profiles Guide](onboarding/FEDERATION-PROFILES.md) for detailed comparison.

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

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License. See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
