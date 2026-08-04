# Infrastructure Components

This document describes all infrastructure components created by this Terraform deployment.

## GCP Infrastructure

### Google Kubernetes Engine (GKE)
- **Standard cluster** with Workload Identity enabled
- **Dataplane V2** for advanced networking and network policy enforcement
- **Node pools** with configurable machine types (default: `e2-medium`)
- **Regional deployment** for high availability

### Networking
- **Static External IP** reserved for federation endpoint
- **External Load Balancer** for ingress traffic
- **Default VPC and subnet** usage
- **Cloud DNS records** automatically managed by ExternalDNS

### IAM & Security
- **ExternalDNS Google Service Account** with DNS admin permissions
- **Workload Identity bindings** between Kubernetes and Google Service Accounts
- **Automated service account creation** (optional, can use pre-existing)

---

## SPIRE Components

### SPIRE Server
- **Federation enabled** for cross-domain trust
- **SPIRE Controller Manager** for Kubernetes integration
- **ClusterSPIFFEID CRDs** for workload registration
- **Web-mode federation** with TLS certificates

### Federation Endpoint
- **HTTPS bundle endpoint** for trust bundle distribution
- **TLS certificates** from Let's Encrypt
- **SPIRE OIDC Discovery provider** for JWT-SVID federation support
- **Automatic DNS registration** via ExternalDNS

---

## Networking & TLS

### Ingress Controller
- **NGINX Ingress Controller** with SSL passthrough enabled
- **External Load Balancer** with static IP
- **ExternalDNS integration** for automatic DNS updates

### Certificate Management
- **cert-manager** for automated TLS certificate lifecycle
- **Let's Encrypt ClusterIssuer** (`letsencrypt-prod`)
- **HTTP-01 challenge solver** via NGINX ingress
- **Automatic certificate renewal**

### TLS Certificates
- Federation endpoint (SPIRE bundle endpoint)
- OIDC discovery endpoint (JWT-SVID provider)
- DIR API server (gRPC endpoint)
- Zot OCI registry (HTTPS endpoint)
- HTTP gateway / AI Catalog UI (HTTPS endpoint)

---

## AGNTCY Directory Stack

### Directory API Server
- **gRPC API** with SPIFFE identity authentication
- **HTTPS ingress** with TLS passthrough
- **Authorization policies** for access control
- **Metrics endpoint** for Prometheus monitoring
- **HTTP Gateway** (optional) for REST API and AI Catalog UI

### Storage & Data
- **PostgreSQL database** (Bitnami chart) for metadata storage
- **Zot OCI registry** for record content storage
- **Persistent volumes** for data persistence
- **Automated credentials** generation and secret management

### Reconciler
- **DIR reconciler** for federation synchronization
- **Registry sync (regsync)** for OCI content synchronization
- **Indexer** for search index maintenance
- **SPIFFE authentication** (x509, jwt, or jwt-tls modes)
- **Configurable sync intervals** and timeouts

### P2P Routing
- **libp2p-based routing** for peer discovery
- **DHT (Distributed Hash Table)** for record announcement
- **GossipSub** for efficient label propagation
- **Bootstrap peers** for network entry
- **LoadBalancer service** with static external IP
- **Persistent storage** for routing data (PVC)

---

## Optional Components

### OIDC Gateway
- **Envoy-based gateway** for user authentication
- **External OIDC providers** (GitHub, Google OAuth)
- **RBAC enforcement** with role-based access control
- **JWT validation** and token exchange
- **SPIFFE JWT-SVID support** for federated reconcilers
- **Ingress endpoint** for external access

### HTTP Gateway & AI Catalog UI
- **grpc-gateway** for REST API access
- **Embedded AI Catalog UI** for browsing records
- **HTTPS ingress** with TLS certificates
- **Configurable catalog title** and branding

---

## Generated Artifacts

### Federation Configuration
- **`federation-config.yaml`** file generated automatically
- Contains trust domain and bundle endpoint URL
- Used for AGNTCY onboarding process
- Ready for submission to `agntcy/dir-staging` repository

### Kubernetes Secrets
- **DIR credentials secret** with PostgreSQL and Zot passwords
- **Routing key secret** with libp2p private key
- **TLS certificate secrets** managed by cert-manager
- **ExternalDNS credentials** via Workload Identity

---

## Resource Summary

| Component | Type | Purpose |
|-----------|------|---------|
| GKE Cluster | GCP | Kubernetes orchestration |
| Static IP | GCP | Stable federation endpoint |
| Load Balancer | GCP | Ingress traffic routing |
| DNS Records | GCP | Automatic hostname management |
| Service Account | GCP | ExternalDNS permissions |
| SPIRE Server | Kubernetes | Identity and trust |
| NGINX Ingress | Kubernetes | HTTP/HTTPS routing |
| cert-manager | Kubernetes | TLS certificate automation |
| DIR API Server | Kubernetes | Directory gRPC API |
| PostgreSQL | Kubernetes | Metadata storage |
| Zot Registry | Kubernetes | OCI content storage |
| DIR Reconciler | Kubernetes | Federation sync |
| P2P Routing | Kubernetes | Peer discovery |
| OIDC Gateway | Kubernetes (optional) | User authentication |

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         GCP Project                          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              GKE Cluster (Standard)                 │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │           SPIRE Server (spire-server ns)     │ │    │
│  │  │  - Federation Bundle Endpoint                │ │    │
│  │  │  - OIDC Discovery Provider                   │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │      AGNTCY Directory (dir ns)               │ │    │
│  │  │  - API Server (gRPC + HTTP Gateway)          │ │    │
│  │  │  - PostgreSQL Database                       │ │    │
│  │  │  - Zot OCI Registry                          │ │    │
│  │  │  - Reconciler (sync + indexer)               │ │    │
│  │  │  - P2P Routing Service                       │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │    OIDC Gateway (oidc-gateway ns, optional)  │ │    │
│  │  │  - Envoy Proxy                               │ │    │
│  │  │  - Auth Server                               │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │    Infrastructure (various namespaces)       │ │    │
│  │  │  - NGINX Ingress Controller                  │ │    │
│  │  │  - cert-manager                              │ │    │
│  │  │  - ExternalDNS                               │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Static IP ──> Load Balancer ──> Ingress Controller         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                    Cloud DNS Zone
              (Automatic record management)
```

---

## Notes

- All Helm charts are deployed with proper dependency ordering
- Secrets are automatically generated with secure random passwords
- TLS certificates are automatically provisioned and renewed
- DNS records are automatically created and updated
- The deployment supports both development and production configurations
- Federation configuration is generated automatically for easy onboarding
