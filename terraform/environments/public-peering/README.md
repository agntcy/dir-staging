# GKE Cluster with AGNTCY Directory Stack

Terraform module that provisions a GKE Standard cluster in a GCP project. 
Turns the GKE cluster into a SPIRE node with a reachable federation bundle endpoint.
Installs the AGNTCY Directory on top of the SPIRE deployment, and facilitates public federation **two-way trust** setup.

## Quick Links

- **[Infrastructure Components](docs/INFRASTRUCTURE.md)** - Complete list of all components created by this deployment
- **[Prerequisites](docs/PREREQUISITES.md)** - Required tools and authentication setup
- **[Required Permissions](docs/REQUIRED_PERMISSIONS.md)** - IAM roles and permissions needed to run Terraform
- **[Required GCP Services](docs/GCP_SERVICES.md)** - GCP APIs that must be enabled

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
