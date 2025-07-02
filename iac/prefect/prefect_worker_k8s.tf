# Configure Prefect provider
provider "prefect" {
  endpoint   = "https://prefect.plusai.is/api"
}
locals {
  job_template = jsondecode(file("${path.module}/template/workpool.json"))
  
  customized_job_template = {
    job_configuration = local.job_template.job_configuration
    variables = merge(
      local.job_template.variables,
      {
        properties = merge(
          local.job_template.variables.properties,
          {
            service_account_name = merge(
              local.job_template.variables.properties.service_account_name,
              {
                default = google_service_account.prefect_worker.email
              }
            )
            region = merge(
              local.job_template.variables.properties.region,
              {
                default = var.region
              }
            )
            network = merge(
              local.job_template.variables.properties.network,
              {
                default = data.google_compute_network.default.name
              }
            )
            subnetwork = merge(
              local.job_template.variables.properties.subnetwork,
              {
                default = google_compute_subnetwork.prefect_runner_subnet.name
              }
            )
          }
        )
      }
    )
  }
}

resource "prefect_work_pool" "gcp_cloud_run_v2" {
  name         = "gcp-cloud-run-v2-${var.env}"
  type         = "cloud-run-v2"
  description  = "Google Cloud Run v2 work pool for ${var.env} environment"
  paused       = false

  # Use the customized job template
  base_job_template = jsonencode(local.customized_job_template)
  depends_on = [ helm_release.prefect_server ]
}



# Helm release for Prefect Worker deployment on GKE
resource "helm_release" "prefect_worker" {
  name       = "prefect-worker-${var.env}"
  repository = "https://prefecthq.github.io/prefect-helm"
  chart      = "prefect-worker"
  version    = var.prefect_helm_chart_version
  namespace  = var.namespace_prefect_server

  values = [
    templatefile("${path.module}/helm/values.prefect-worker.yaml", {
      workPoolName          = prefect_work_pool.gcp_cloud_run_v2.name
      gcpServiceAccount     = google_service_account.prefect_worker.email
      gcpProjectId          = var.project_id
      gcpRegion             = var.region
      cloudRunServiceAccount = google_service_account.prefect_worker.email
      environment           = var.env
      namespace             = var.namespace_prefect_server
    })
  ]

  depends_on = [ prefect_work_pool.gcp_cloud_run_v2 ]

}
