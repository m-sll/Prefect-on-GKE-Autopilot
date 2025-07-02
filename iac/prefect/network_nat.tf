# Data sources for default network and subnet
data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = var.region
}

# Create subnet for Prefect workers in default VPC
resource "google_compute_subnetwork" "prefect_runner_subnet" {
  name          = "prefect-runner-subnet-${var.env}"
  network       = data.google_compute_network.default.self_link
  region        = var.region
  ip_cidr_range = var.prefect_runner_subnet_cidr
}

# Reserve static external IP for NAT
resource "google_compute_address" "prefect_runner_nat_ip" {
  name         = "prefect-runner-nat-ip-${var.env}"
  region       = var.region
  address_type = "EXTERNAL"
}

resource "cloudflare_dns_record" "example_dns_record" {
  zone_id = var.cloudflare_zone_id
  name = var.prefect_domain
  type = "A"
  comment = "Prefect Ingress Static IP"
  content = google_compute_global_address.prefect_ingress_static_ip.address
  proxied = true
  ttl = 1
}

# Create Cloud Router for NAT
resource "google_compute_router" "prefect_runner_router" {
  name    = "prefect-runner-router-${var.env}"
  network = data.google_compute_network.default.id
  region  = var.region
}

# Create Cloud NAT with static IP
resource "google_compute_router_nat" "prefect_runner_nat" {
  name                               = "prefect-runner-nat-${var.env}"
  router                             = google_compute_router.prefect_runner_router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.prefect_runner_nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.prefect_runner_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Output the static NAT IP
output "prefect_runner_nat_ip" {
  value       = google_compute_address.prefect_runner_nat_ip.address
  description = "Static NAT IP address for Prefect runners"
}

output "prefect_runner_subnet_name" {
  value       = google_compute_subnetwork.prefect_runner_subnet.name
  description = "Subnet name for Prefect runners"
}
