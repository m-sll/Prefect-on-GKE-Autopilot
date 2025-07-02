# Enable Artifact Registry API
resource "google_project_service" "artifact_registry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Docker repository
resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.docker_repo_name
  description   = "Docker registry managed by Terraform"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry]
  vulnerability_scanning_config {
    enablement_config = "DISABLED"
  }
}

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

output "docker_repo_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.docker_repo_name}"
}