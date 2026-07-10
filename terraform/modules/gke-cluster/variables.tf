variable "project_id" {
  description = "GCP project ID hosting the GKE cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "region" {
  description = "GCP region for the cluster (regional, multi-zone)."
  type        = string
  default     = "us-central1"
}

variable "machine_type" {
  description = "Machine type for the default node pool."
  type        = string
  default     = "e2-standard-4"
}
