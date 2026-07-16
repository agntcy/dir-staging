# GKE Cluster with AGNTCY Directory Stack

Terraform module that provisions a GKE Standard cluster in a GCP project. 
Turns the GKE cluster into a SPIRE node with a reachable federation bundle endpoint.
Installs the AGNTCY Directory on top of the SPIRE deployment, and facilitates public federation **two-way trust** setup.

## What it creates

### GCP Infrastructure
- Google Kubernetes Engine Standard cluster
- Google Compute Address (static IP) for federation endpoint
- External Load Balancer for ingress controller
- Cloud DNS records (automatically managed by ExternalDNS)

### SPIRE Components
- SPIRE server with federation enabled
- SPIRE federation bundle endpoint with TLS certificates
- SPIRE OIDC discovery provider for JWT-SVID federation support

### Networking & TLS
- NGINX ingress controller with SSL passthrough
- cert-manager for automated TLS certificate management
- Let's Encrypt ClusterIssuer (`letsencrypt-prod`)
- TLS certificates for federation endpoint
- TLS certificates for OIDC discovery endpoint
- TLS certificates for DIR services (API, Zot)

### AGNTCY Directory Stack
- AGNTCY Directory service on top of SPIRE deployment:
  - Directory API server with SPIFFE identity
  - DIR reconciler for synchronization
  - PostgreSQL backing datastore
  - Zot OCI registry for record content
  - P2P routing service for peer discovery and publication (LoadBalancer)

### Federation Configuration
- Generated `federation-config.yaml` file for AGNTCY onboarding process

### Optional: OIDC Gateway
- OIDC gateway for user authentication (optional, see OIDC-GATEWAY.md)
- Support for external OIDC providers (GitHub, Google, etc.)
- RBAC enforcement for Directory API access
- Envoy-based authentication and authorization


## Prerequisites

[terraform](https://developer.hashicorp.com/terraform/install) 

[gcloud](https://docs.cloud.google.com/sdk/docs/install-sdk)

[google-cloud-cli-gke-gcloud-auth-plugin](https://docs.cloud.google.com/sdk/docs/install-sdk#deb)

## Google Cloud Auth

Tokens expire so you might have to repeat these steps if the workflow runs across multiple days.

This gets an authentication token for the gcloud CLI.

```
gcloud auth login
```

This gets an authentication token for use by the Terraform application.
```
gcloud auth application-default login
```

Set the default project and the quota project. 
```
DIR_PROJECT=<your-gcp-project-id>  # the GCP project which will host the GKE clusters for the Dirctory Stack

gcloud config set project "${DIR_PROJECT}"
gcloud auth application-default set-quota-project "${DIR_PROJECT}"
```

## One-time setup

This enables the required Google Cloud APIs:

```
gcloud services enable container.googleapis.com compute.googleapis.com dns.googleapis.com \
  --project="${DIR_PROJECT}"
```

The ExternalDNS Google Service Account and IAM bindings are now automatically created by Terraform when `external_dns_gsa_email` is not provided in your `terraform.tfvars` file. This makes the setup truly one-click.

**Permission Requirements for Automation:**
The automated GSA creation requires the following permissions on the DNS project (`dns_project_id`):
- `iam.serviceAccounts.create` - to create the service account
- `resourcemanager.projects.setIamPolicy` - to grant DNS admin role
- `iam.serviceAccounts.setIamPolicy` - to configure Workload Identity

If you don't have these permissions on the DNS project, you have two options:
1. Use a pre-existing GSA by setting `external_dns_gsa_email` in your terraform.tfvars
2. Follow the manual setup steps in `MANUAL_GSA_SETUP.md` and provide the GSA email

If you need to use a pre-existing GSA or prefer manual setup, see `MANUAL_GSA_SETUP.md` for the manual steps and set the `external_dns_gsa_email` variable in your terraform.tfvars file.

## Usage

```bash
cd terraform/environments/public-peering
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set project_id + cluster_name
```
```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply
```

## Optional: OIDC Gateway

For user authentication and authorization, you can optionally deploy the OIDC gateway. See [OIDC-GATEWAY.md](OIDC-GATEWAY.md) for configuration details.

## Join the Public Federation

After running `terraform apply`, the federation configuration file is automatically generated.

```
cat federation-config.yaml
```

This file contains the correct configuration based on your actual deployment. Use it to register with AGNTCY

1. Get access to the `agntcy/dir-staging` repository from the AGNTCY team
2. Copy the content from `federation-config.yaml`
3. Create or update `onboarding/federation/<CompanyXYZ.com.yaml>` in the `agntcy/dir-staging` repository with the copied content
4. Submit a Pull Request for review

## Teardown

The ingress must be destroyed first for the external DNS to get a chance to clean up.

```
terraform destroy \
-target=module.public_spire.kubectl_manifest.federation_ingress \
-target=module.public_spire.kubectl_manifest.oidc_discovery_ingress \
-target=module.public_spire.helm_release.ingress_nginx
```

Destroy the rest of the infrastructure.

```bash
terraform destroy
```
