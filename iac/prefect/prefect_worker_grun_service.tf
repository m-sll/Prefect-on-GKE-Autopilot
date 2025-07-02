# Cloud Run Service for Prefect Worker Will use up free tier resources
# resource "google_cloud_run_v2_service" "prefect_worker" {
#   name     = "prefect-worker-${var.env}"
#   location = var.region
#   project  = var.project_id

#   template {
#     service_account = google_service_account.prefect_worker.email
    
#     # Disable CPU throttling
#     execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    
#     # Set minimum instances
#     scaling {
#       min_instance_count = 1
#       max_instance_count = 2
#     }

#     vpc_access {
#       network_interfaces {
#         network    = data.google_compute_network.default.name
#         subnetwork = google_compute_subnetwork.prefect_worker_subnet.name
#       }
#       egress = "ALL_TRAFFIC"
#     }
    
#     containers {
#       image = "prefecthq/prefect:3-latest"
      
#       # Startup command
#       args = [
#         "prefect",
#         "worker",
#         "start",
#         "--install-policy",
#         "always",
#         "--with-healthcheck",
#         "-p",
#         prefect_work_pool.gcp_cloud_run_v2.name,
#         "-t",
#         "cloud-run"
#       ]
      
#       # Environment variables
#       env {
#         name  = "PREFECT_API_URL"
#         value = "https://prefect.godone.xyz/api"
#       }
      
#       # Health check startup probe
#       startup_probe {
#         initial_delay_seconds = 100
#         timeout_seconds       = 20
#         period_seconds        = 20
#         failure_threshold     = 3
        
#         http_get {
#           path = "/health"
#           port = 8080
#         }
#       }
      
#       # Resource limits
#       resources {
#         limits = {
#           cpu    = "1"
#           memory = "1Gi"
#         }
#         cpu_idle = false  # No CPU throttling
#       }
#     }
#   }

#   traffic {
#     type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
#     percent = 100
#   }

#   depends_on = [ prefect_work_pool.gcp_cloud_run_v2 ]
# }

# output "prefect_worker_service_url" {
#   value       = google_cloud_run_v2_service.prefect_worker.uri
#   description = "URL of the Prefect worker Cloud Run service"
# }