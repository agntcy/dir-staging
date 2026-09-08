provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  release_channel { channel = "REGULAR" }

  network    = "projects/${var.project_id}/global/networks/default"
  subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/default"

  ip_allocation_policy {}

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Dataplane V2 for network policy enforcement
  datapath_provider = "ADVANCED_DATAPATH"

  initial_node_count = 1
  node_config {
    machine_type = var.machine_type

    # GKE_METADATA enables the node pool's metadata server, which is required
    # for Workload Identity to actually work. The cluster-level
    # workload_identity_config above is only half the wiring.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  deletion_protection = false
}
