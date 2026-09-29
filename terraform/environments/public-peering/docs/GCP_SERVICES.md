# Required GCP Services

This document lists all Google Cloud Platform (GCP) services/APIs that must be enabled before deploying the AGNTCY Directory infrastructure.

## Enable All Services

Run this command to enable all required services at once:

```bash
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  dns.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="${DIR_PROJECT}"
```

## Service Breakdown

### 1. Kubernetes Engine API (`container.googleapis.com`)
**Used by:** `google_container_cluster` in gke-cluster module

**Required for:**
- Creating and managing GKE clusters
- Node pool configuration
- Workload Identity setup

**Terraform Resources:**
- `modules/gke-cluster/main.tf`: `google_container_cluster.gke`

---

### 2. Compute Engine API (`compute.googleapis.com`)
**Used by:** `google_compute_address` in spire-node module

**Required for:**
- Reserving static external IP addresses
- Load balancer configuration
- Network infrastructure

**Terraform Resources:**
- `modules/spire-node/main.tf`: `google_compute_address.federation_endpoint`

---

### 3. Cloud DNS API (`dns.googleapis.com`)
**Used by:** ExternalDNS for automatic DNS record management

**Required for:**
- Creating and managing DNS records in Cloud DNS
- Automatic DNS updates for ingress and load balancer services
- Federation endpoint DNS resolution

**Terraform Resources:**
- Managed by ExternalDNS Helm chart deployed in spire-node module
- DNS zone specified via `dns_zone_name` variable

---

### 4. Identity and Access Management API (`iam.googleapis.com`)
**Used by:** Service account creation and Workload Identity bindings

**Required for:**
- Creating Google Service Accounts (GSA)
- Configuring Workload Identity bindings between Kubernetes Service Accounts and GSAs
- Service account IAM policy management

**Terraform Resources:**
- `environments/public-peering/main.tf`: 
  - `google_service_account.external_dns`
  - `google_service_account_iam_binding.external_dns_workload_identity`

---

### 5. Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)
**Used by:** Project-level IAM policy bindings

**Required for:**
- Granting project-level IAM roles
- Managing DNS admin permissions for ExternalDNS GSA
- Cross-project IAM bindings (when DNS project differs from GKE project)

**Terraform Resources:**
- `environments/public-peering/main.tf`: 
  - `google_project_iam_binding.external_dns_dns_admin`

---

## Verification

After enabling the services, verify they are active:

```bash
gcloud services list --enabled --project="${DIR_PROJECT}" | grep -E "container|compute|dns|iam|cloudresourcemanager"
```

Expected output:
```
cloudresourcemanager.googleapis.com  Cloud Resource Manager API
compute.googleapis.com               Compute Engine API
container.googleapis.com             Kubernetes Engine API
dns.googleapis.com                   Cloud DNS API
iam.googleapis.com                   Identity and Access Management (IAM) API
```

## Troubleshooting

### Permission Errors During Terraform Apply

If you encounter permission errors during `terraform apply`, ensure:

1. **IAM API is enabled** - Required for creating service accounts
2. **Cloud Resource Manager API is enabled** - Required for project IAM bindings
3. **Your user/service account has sufficient permissions:**
   - `roles/iam.serviceAccountAdmin` - To create service accounts
   - `roles/resourcemanager.projectIamAdmin` - To manage project IAM policies
   - `roles/container.admin` - To manage GKE clusters
   - `roles/compute.admin` - To manage compute resources
   - `roles/dns.admin` - To manage DNS zones (on DNS project)

### Service Enablement Delays

After enabling services, there may be a brief delay (30-60 seconds) before they are fully available. If Terraform fails immediately after enabling services, wait a minute and retry.

### Cross-Project DNS Setup

When `dns_project_id` differs from `project_id`, ensure:
- Both projects have the required APIs enabled
- Your credentials have permissions in both projects
- The DNS project has the Cloud DNS API enabled
- The GKE project has IAM API enabled for cross-project service account bindings

## Notes

- These services may incur costs based on usage
- The original README only listed `container`, `compute`, and `dns` APIs
- `iam` and `cloudresourcemanager` APIs are required for the automated ExternalDNS GSA creation feature introduced in later versions
- If using a pre-existing ExternalDNS GSA (via `external_dns_gsa_email` variable), you may not need `iam` and `cloudresourcemanager` APIs, but they are still recommended for future flexibility
