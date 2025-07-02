# Create service account for Cloud Run workers
resource "google_service_account" "prefect_worker" {
  account_id   = "prefect-worker-${var.env}"
  display_name = "Prefect Worker Service Account"
  description  = "Service account for Prefect Cloud Run workers"
}

resource "google_project_iam_member" "prefect_worker_roles" {
  for_each = toset([
    "roles/run.admin",              # Cloud Run Admin role
    "roles/iam.serviceAccountUser",  # IAM Service Account User role
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",  # Artifact Registry Reader role
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.prefect_worker.email}"
}

output "prefect_worker_service_account" {
  value       = google_service_account.prefect_worker.email
  description = "Service account email for Prefect workers"
}

# Create Kubernetes service account for Prefect Worker
resource "kubernetes_service_account" "prefect_worker" {
  metadata {
    name      = "prefect-worker"
    namespace = var.namespace_prefect_server
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.prefect_worker.email
    }
  }
}

resource "google_service_account_iam_binding" "prefect_worker_workload_identity" {
  service_account_id = google_service_account.prefect_worker.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace_prefect_server}/prefect-worker]"
  ]
}