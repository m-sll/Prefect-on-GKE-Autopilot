resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

# Needed for fleet / GKE Hub features
resource "google_project_service" "gkehub" {
  project = var.project_id
  service = "gkehub.googleapis.com"

  disable_on_destroy = false
}
