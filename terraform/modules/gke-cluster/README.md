# Google Kubernetes Engine (GKE) Cluster

Terraform module that provisions a single GKE Standard cluster in a GCP project. Equivalent to a single `gcloud container clusters create` call, parameterized so the same module can be applied any number of times with different `cluster_name` values.

## What it creates

A single `google_container_cluster` named per `var.cluster_name`, with:

- The project's `default` VPC and subnetwork
- The `REGULAR` GKE release channel
- Workload Identity (workload pool `<project>.svc.id.goog`)
- One `e2-standard-4` node per zone (3 nodes total for a regional cluster)
- `deletion_protection = false` so `terraform destroy` works cleanly

## Prerequisites

- Terraform `>= 1.5.0`
- `gcloud auth application-default login` (or a service account with `roles/container.admin` + `roles/compute.networkUser`)
- The Container API enabled on the project (`gcloud services enable container.googleapis.com`)

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set project_id + cluster_name

terraform init
terraform plan
terraform apply

# Wire up kubectl
$(terraform output -raw get_credentials_command)
```

## Cleanup

```bash
terraform destroy
```
