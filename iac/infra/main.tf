terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.41.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
  }
  cloud {
    organization = "bigbang-lab"
  }
}


# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "this" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.this.private_cluster_config[0].private_endpoint}"
  token                  = data.google_client_config.this.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.this.master_auth[0].cluster_ca_certificate
  )
}

# Data sources for default network and subnet
data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = var.region
}

# GKE Autopilot Cluster
resource "google_container_cluster" "this" {
  name     = "${var.gke_autopilot_name}-${var.env}"
  location = var.region  # Regional cluster
  
  # Autopilot mode
  enable_autopilot = true
  
  deletion_protection = var.deletion_protection

  # Release channel configuration
  release_channel {
    channel = "REGULAR"
  }
  
  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T09:00:00Z"
      end_time   = "2024-01-01T13:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=TU,TH,SU"
    }
  }
  
  # Network configuration
  network    = data.google_compute_network.default.name
  subnetwork = data.google_compute_subnetwork.default.name
  
  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_ipv4_cidr_block
    services_ipv4_cidr_block = var.services_ipv4_cidr_block
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
  }
  control_plane_endpoints_config {

    ## Enable the new DNS endpoint
    dns_endpoint_config {
      allow_external_traffic = true    # uncomment to let *any* network reach
                                       # the DNS endpoint (IAM still gates access)
                                       # keep the field unset for the default
                                       # “internal-only” behaviour
    }

    ## (Optional) Keep or disable the old IP endpoint
    ip_endpoints_config {
      enabled = true                # set to false to *remove* the IP address
    }
  }
  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.gke_auth_ips
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  
  dns_config {
    cluster_dns                     = "CLOUD_DNS"          # turn on Cloud DNS for GKE
    cluster_dns_scope               = "CLUSTER_SCOPE"      # keep records cluster-scoped
    additive_vpc_scope_dns_domain   = "${var.cluster_dns_domain}.${var.env}.internal"
    # cluster_dns_domain = "cluster.local" # optional override of the default
  }
  
  # Gateway API
  gateway_api_config {
    channel = "CHANNEL_STANDARD"  # Use standard channel for Gateway API          
  }
  
  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Logging and monitoring
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS"
    ]
  }
  
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS"
    ]
    
  }
  
  # Addons configuration - only non-defaults
  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    # Explicitly disable parallelstore CSI driver
    parallelstore_csi_driver_config {
      enabled = false
    }
  }
  
  # Fleet membership
  fleet {
    project = var.project_id
  }
  
  # Lifecycle rule to ignore certain changes
  lifecycle {
    ignore_changes = [
      min_master_version,
      node_version,
    ]
  }
}


resource "kubernetes_namespace" "prefect_server" {
  metadata {
    name = var.namespace_prefect_server
  }
  depends_on = [google_container_cluster.this]
}

# Output cluster information
output "cluster_name" {
  value       = google_container_cluster.this.name
  description = "GKE cluster name"
}

output "cluster_location" {
  value       = google_container_cluster.this.location
  description = "GKE cluster location"
}

output "cluster_endpoint" {
  value       = google_container_cluster.this.endpoint
  description = "GKE cluster endpoint"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  description = "Cluster CA certificate"
  sensitive   = true
}

output "workload_identity_pool" {
  value       = "${var.project_id}-${var.env}.svc.id.goog"
  description = "Workload Identity Pool"
}

output "fleet_membership_id" {
  value       = google_container_cluster.this.fleet[0].membership_id
  description = "Fleet membership ID"
}