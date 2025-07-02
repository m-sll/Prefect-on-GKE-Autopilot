locals {
  db_user     = google_sql_user.prefect_user.name
  db_password = random_password.db_password.result
  db_url      = "postgresql+asyncpg://${local.db_user}:${local.db_password}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.prefect_db.name}?ssl=disable"
}

resource "kubernetes_secret" "prefect_db_conn" {
  metadata {
    name      = "prefect-db-conn"
    namespace = var.namespace_prefect_server
  }

  data = {
    "connection-string" = local.db_url
  }

  type = "Opaque"
}