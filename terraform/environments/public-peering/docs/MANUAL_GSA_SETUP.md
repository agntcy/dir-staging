# Manual ExternalDNS GSA Setup

This document describes the manual setup steps for the ExternalDNS Google Service Account. These steps are now automated by Terraform, but are preserved here for reference or for use in environments where automated creation is not desired or not possible due to permission constraints.

## When to Use Manual Setup

Use manual setup when:
- You don't have the required IAM permissions on the DNS project (`iam.serviceAccounts.create`, `resourcemanager.projects.setIamPolicy`, `iam.serviceAccounts.setIamPolicy`)
- You prefer to manage service accounts manually
- Your organization requires manual approval for service account creation

## Manual Setup Steps

If you prefer to create the ExternalDNS GSA manually instead of using Terraform automation, follow these steps:

```bash
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

## Using a Pre-existing GSA

If you have a manually created GSA, set the `external_dns_gsa_email` variable in your `terraform.tfvars` file:

```hcl
external_dns_gsa_email = "external-dns@your-dns-project-id.iam.gserviceaccount.com"
```

When this variable is set, Terraform will skip automatic GSA creation and use your existing service account.