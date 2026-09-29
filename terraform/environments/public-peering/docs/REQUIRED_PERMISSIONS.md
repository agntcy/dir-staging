# Required IAM Permissions

This document lists all IAM permissions required to deploy the AGNTCY Directory infrastructure using Terraform.

## Required Roles

1. `roles/container.admin`
2. `roles/compute.networkAdmin`
3. `roles/iam.serviceAccountAdmin`
4. `roles/resourcemanager.projectIamAdmin`

## Quick Setup

```bash
for role in roles/container.admin roles/compute.networkAdmin roles/iam.serviceAccountAdmin roles/resourcemanager.projectIamAdmin; do
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="user:${USER_EMAIL}" \
    --role="$role"
done
```

---

## Individual Permissions Included

The 4 roles above provide these individual permissions:

1. `container.clusters.create`
2. `container.clusters.delete`
3. `container.clusters.get`
4. `container.clusters.update`
5. `container.operations.get`
6. `container.operations.list`
7. `compute.addresses.create`
8. `compute.addresses.delete`
9. `compute.addresses.get`
10. `compute.addresses.list`
11. `compute.addresses.use`
12. `compute.networks.get`
13. `compute.subnetworks.get`
14. `compute.subnetworks.use`
15. `iam.serviceAccounts.create`
16. `iam.serviceAccounts.delete`
17. `iam.serviceAccounts.get`
18. `iam.serviceAccounts.list`
19. `iam.serviceAccounts.setIamPolicy`
20. `iam.serviceAccounts.getIamPolicy`
21. `iam.serviceAccounts.actAs`
22. `resourcemanager.projects.get`
23. `resourcemanager.projects.getIamPolicy`
24. `resourcemanager.projects.setIamPolicy`

---

## Permission Breakdown by Terraform Module

### 1. `gke-cluster` Module
**Path:** `modules/gke-cluster/`

**Purpose:** Creates GKE cluster with Workload Identity

**Resources:**
- `google_container_cluster`

**Required Permissions:**
- `container.clusters.create`
- `container.clusters.delete`
- `container.clusters.get`
- `container.clusters.update`
- `container.operations.get`
- `container.operations.list`
- `compute.networks.get`
- `compute.subnetworks.get`
- `compute.subnetworks.use`

**Provided by Role:** `roles/container.admin`, `roles/compute.networkAdmin`

---

### 2. `spire-node` Module
**Path:** `modules/spire-node/`

**Purpose:** Deploys SPIRE server with federation endpoint

**Resources:**
- `google_compute_address` (static IP for federation endpoint)

**Required Permissions:**
- `compute.addresses.create`
- `compute.addresses.delete`
- `compute.addresses.get`
- `compute.addresses.list`
- `compute.addresses.use`

**Provided by Role:** `roles/compute.networkAdmin`

---

### 3. `dir-node` Module
**Path:** `modules/dir-node/`

**Purpose:** Deploys AGNTCY Directory stack

**Resources:**
- None (uses Kubernetes/Helm resources only)

**Required Permissions:**
- None (GKE cluster access only)

---

### 4. `oidc-gateway` Module
**Path:** `modules/oidc-gateway/`

**Purpose:** Deploys OIDC gateway for user authentication

**Resources:**
- None (uses Kubernetes/Helm resources only)

**Required Permissions:**
- None (GKE cluster access only)

---

### 5. `public-peering` Environment
**Path:** `environments/public-peering/`

**Purpose:** Orchestrates all modules and manages ExternalDNS GSA

**Resources:**
- `google_service_account` (ExternalDNS GSA)
- `google_project_iam_binding` (DNS admin role)
- `google_service_account_iam_binding` (Workload Identity)

**Required Permissions:**
- `iam.serviceAccounts.create`
- `iam.serviceAccounts.delete`
- `iam.serviceAccounts.get`
- `iam.serviceAccounts.list`
- `iam.serviceAccounts.setIamPolicy`
- `iam.serviceAccounts.getIamPolicy`
- `iam.serviceAccounts.actAs`
- `resourcemanager.projects.get`
- `resourcemanager.projects.getIamPolicy`
- `resourcemanager.projects.setIamPolicy`

**Provided by Role:** `roles/iam.serviceAccountAdmin`, `roles/resourcemanager.projectIamAdmin`

---

## Using a Pre-Existing ExternalDNS GSA

If you provide `external_dns_gsa_email` in your `terraform.tfvars`, the following permissions are **NOT** required:

- Service account creation permissions on DNS project
- Project IAM policy management permissions on DNS project

However, you must manually ensure:
1. The GSA exists with email matching `external_dns_gsa_email`
2. The GSA has `roles/dns.admin` on the DNS zone
3. The GSA has Workload Identity binding configured

See `docs/MANUAL_GSA_SETUP.md` for manual setup instructions.

---

## Verification

### Check Your Permissions

```bash
# Check permissions on GKE project
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:your-email@example.com"

# Check permissions on DNS project
gcloud projects get-iam-policy ${DNS_PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:your-email@example.com"
```

### Test Permissions Before Terraform Apply

```bash
# Test GKE cluster creation permission
gcloud container clusters list --project=${PROJECT_ID}

# Test compute address creation permission
gcloud compute addresses list --project=${PROJECT_ID}

# Test service account creation permission (DNS project)
gcloud iam service-accounts list --project=${DNS_PROJECT_ID}

# Test IAM policy read permission (DNS project)
gcloud projects get-iam-policy ${DNS_PROJECT_ID} --format=json > /dev/null
```

---

## Troubleshooting

### Error: "Permission denied on resource project"

**Cause:** Missing `resourcemanager.projects.get` or `resourcemanager.projects.getIamPolicy`

**Solution:** Grant `roles/resourcemanager.projectIamAdmin` on the DNS project

---

### Error: "Required 'iam.serviceAccounts.create' permission"

**Cause:** Missing service account creation permissions

**Solution:** 
- Grant `roles/iam.serviceAccountAdmin` on the DNS project, OR
- Provide a pre-existing GSA via `external_dns_gsa_email` variable

---

### Error: "Required 'container.clusters.create' permission"

**Cause:** Missing GKE cluster creation permissions

**Solution:** Grant `roles/container.admin` on the GKE project

---

### Error: "Required 'compute.addresses.create' permission"

**Cause:** Missing compute address creation permissions

**Solution:** Grant `roles/compute.networkAdmin` or `roles/compute.admin` on the GKE project

---

## Security Best Practices

1. **Use Service Accounts for CI/CD:** Create a dedicated service account for Terraform automation
2. **Principle of Least Privilege:** Grant only the minimum required roles
3. **Separate Projects:** Consider using separate projects for GKE and DNS for better isolation
4. **Audit Logging:** Enable Cloud Audit Logs to track IAM changes
5. **Temporary Credentials:** Use short-lived credentials when possible
6. **Pre-Existing GSA:** For production, consider manually creating the ExternalDNS GSA to reduce Terraform permissions

---

## Summary Table

| Resource | Project | Predefined Role | Alternative |
|----------|---------|----------------|-------------|
| GKE Cluster | `project_id` | `roles/container.admin` | Custom role with container.* |
| Static IP | `project_id` | `roles/compute.networkAdmin` | `roles/compute.admin` |
| Service Account | `dns_project_id` | `roles/iam.serviceAccountAdmin` | Use pre-existing GSA |
| IAM Bindings | `dns_project_id` | `roles/resourcemanager.projectIamAdmin` | Use pre-existing GSA |
| Workload Identity | `dns_project_id` | `roles/iam.serviceAccountAdmin` | Use pre-existing GSA |

---

## Notes

- If `project_id` == `dns_project_id`, you only need permissions on one project
- The ExternalDNS GSA itself needs `roles/dns.admin`, but this is granted by Terraform
- Kubernetes resources (namespaces, deployments, etc.) are managed via GKE cluster credentials, not GCP IAM
- Helm charts and kubectl manifests require GKE cluster access, which is automatic after cluster creation
