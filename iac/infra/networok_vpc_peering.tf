resource "google_compute_global_address" "managed_services_range" {
  name          = "google-managed-services-default"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.default.id
}


resource "google_service_networking_connection" "psa" {
  network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.managed_services_range.name]
  update_on_creation_fail = true
  deletion_policy = "ABANDON"
}
