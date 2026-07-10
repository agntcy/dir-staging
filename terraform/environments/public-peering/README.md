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

This sets up DNS service accounts. ExternalDNS in this project needs access via Workload Identity. The following one-time setup must be done by whoever has IAM admin on the DNS project — `terraform apply` does NOT create these.

```
# Set these to your reality. DNS_PROJECT and DIR_PROJECT can have the same value.
DNS_PROJECT=<dns-project-id>                 # the project hosting the zone
DIR_PROJECT=<dir-deploy-project-id>          # the project hosting our clusters
ZONE=<managed-zone-resource-name>            # the Cloud DNS resource name
GSA=external-dns

# 1. Create the GSA in the DNS project.
gcloud iam service-accounts create "$GSA" --project "$DNS_PROJECT"

# 2. Grant it dns.admin on project 
gcloud projects add-iam-policy-binding "$DNS_PROJECT" \
  --member "serviceAccount:${GSA}@${DNS_PROJECT}.iam.gserviceaccount.com" \
  --role "roles/dns.admin"

# 3. Allow the dir-deploy cluster's KSA to impersonate it (Workload Identity).
gcloud iam service-accounts add-iam-policy-binding \
  "${GSA}@${DNS_PROJECT}.iam.gserviceaccount.com" \
  --project "$DNS_PROJECT" \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${DIR_PROJECT}.svc.id.goog[external-dns/external-dns]"
```

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
