# Prerequisites

This document lists the required tools and authentication steps needed before deploying the AGNTCY Directory infrastructure.

## Required Tools

### Terraform
Install Terraform for infrastructure provisioning.

**Install:** [terraform.io](https://developer.hashicorp.com/terraform/install)

**Verify installation:**
```bash
terraform --version
```

### Google Cloud CLI (gcloud)
Install the Google Cloud CLI for GCP authentication and management.

**Install:** [cloud.google.com/sdk/docs/install-sdk](https://docs.cloud.google.com/sdk/docs/install-sdk)

**Verify installation:**
```bash
gcloud --version
```

### GKE Auth Plugin
Install the GKE authentication plugin for kubectl to work with GKE clusters.

**Install:** [cloud.google.com/sdk/docs/install-sdk#deb](https://docs.cloud.google.com/sdk/docs/install-sdk#deb)

**Verify installation:**
```bash
gke-gcloud-auth-plugin --version
```

## Google Cloud Authentication

### Authenticate with gcloud
This gets an authentication token for the gcloud CLI. Tokens expire, so you may need to repeat this step if your workflow runs across multiple days.

```bash
gcloud auth login
```

### Authenticate for Terraform
This gets an authentication token for use by the Terraform application.

```bash
gcloud auth application-default login
```

### Set Default Project
Configure the default project and quota project.

```bash
DIR_PROJECT=<your-gcp-project-id>  # The GCP project that will host the GKE clusters for the Directory Stack

gcloud config set project "${DIR_PROJECT}"
gcloud auth application-default set-quota-project "${DIR_PROJECT}"
```

## Verification

Verify your authentication is working correctly:

```bash
# Check gcloud authentication
gcloud auth list

# Check application default credentials
gcloud auth application-default print-access-token

# Verify project is set correctly
gcloud config get-value project
```

## Next Steps

After completing these prerequisites:

1. **Enable required GCP services** - See [GCP_SERVICES.md](GCP_SERVICES.md)
2. **Grant required IAM permissions** - See [REQUIRED_PERMISSIONS.md](REQUIRED_PERMISSIONS.md)
3. **Configure and deploy** - See the main README.md for usage instructions
