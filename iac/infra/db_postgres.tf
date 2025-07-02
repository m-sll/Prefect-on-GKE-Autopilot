###############################################################################
# Cloud SQL instance – Enterprise edition, single-zone, 1 vCPU / 3.75 GB
###############################################################################
resource "google_sql_database_instance" "postgres" {
  name                = "ok8s-db"
  database_version    = "POSTGRES_17"
  region              = var.region
  deletion_protection = true                          # “Prevent instance deletion”

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"                       # “Single zone”
    edition           = "ENTERPRISE"    
    # ------------------------------------------------------------------------
    # Storage
    # ------------------------------------------------------------------------
    disk_type       = "PD_SSD"
    disk_size       = 128                             # GB
    disk_autoresize = true                            # “Enable automatic storage increases”

    # ------------------------------------------------------------------------
    # Backups & PITR
    # ------------------------------------------------------------------------
    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"        
      point_in_time_recovery_enabled = true

      backup_retention_settings {
        retention_unit  = "COUNT"
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled = true

      private_network = data.google_compute_network.default.self_link
      enable_private_path_for_google_cloud_services = true

      authorized_networks {
        name  = "home"
        value = "70.190.232.143/32"
      }
    }

    insights_config {
      query_insights_enabled            = true
      record_application_tags           = false
      record_client_address             = false
    }

    maintenance_window {
      day  = 2        # Monday = 1 … Sunday = 7
      hour = 2        # 02:00
      update_track = "stable"
    }
  }

  depends_on = [
    google_service_networking_connection.psa
  ]
}

resource "google_sql_database" "prefect_db" {
  name     = "prefect"
  instance = google_sql_database_instance.postgres.name
}

resource "random_password" "db_password" {
  length           = 16
  override_special = false
}

resource "google_sql_user" "prefect_user" {
  name     = "prefect_user"
  instance = google_sql_database_instance.postgres.name
  password_wo = random_password.db_password.result
}

output "connection_name" {
  description = "Project:Region:Instance connection string"
  value       = google_sql_database_instance.postgres.connection_name
}

output "public_ip" {
  value = google_sql_database_instance.postgres.public_ip_address
}

output "private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

