terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.38.0"
    }
  }
    
  cloud {
    organization = "bigbang-lab"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_address" "tfc_agent_static_ip" {
  name         = "tfc-agent-static-ip"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# Create VM instance
resource "google_compute_instance" "tfc_agent_vm" {
  name         = "tfc-agent-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip       = google_compute_address.tfc_agent_static_ip.address
      network_tier = "PREMIUM"
    }
  }

  tags = ["tfc-agent"]

  # Use metadata with startup-script key (inline version)
  metadata = {
    startup-script = templatefile("${path.module}/startup-script.sh", {
        tfc_agent_token = var.TFC_AGENT_TOKEN
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
}

# Firewall rule for TFC agent (if needed for incoming connections)
resource "google_compute_firewall" "tfc_agent_allow" {
  name    = "allow-tfc-agent"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tfc-agent"]
}

# Output the static IP
output "tfc_agent_static_ip" {
  value       = google_compute_address.tfc_agent_static_ip.address
  description = "Static IP address of the TFC agent VM"
}

output "tfc_agent_vm_name" {
  value       = google_compute_instance.tfc_agent_vm.name
  description = "Name of the TFC agent VM"
}

output "ssh_command" {
  value       = "gcloud compute ssh ${google_compute_instance.tfc_agent_vm.name} --zone=${google_compute_instance.tfc_agent_vm.zone}"
  description = "SSH command to connect to the VM"
}

output "tfc_agent_internal_ip" {
  value       = google_compute_instance.tfc_agent_vm.network_interface[0].network_ip
  description = "Internal IP address of the TFC agent VM"
}