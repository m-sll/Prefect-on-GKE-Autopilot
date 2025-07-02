// Terraform variables definitions moved from main.tf
variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
  default     = "us-west1"
}

variable "gke_autopilot_name" {
  description = "Name of the GKE Autopilot cluster"
  type        = string
}

variable "docker_repo_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "prefect-runner-image"
}

variable "env" {
    description = "Environment for the deployment (e.g., dev, prod)"
    type        = string
}

variable "namespace_prefect_server" {
  description = "Kubernetes namespace for Prefect"
  type        = string
  default     = "prefect"
}

variable "prefect_domain" {
  description = "Domain for Prefect"
  type        = string
}

variable "prefect_runner_subnet_cidr" {
  description = "CIDR block for Prefect worker subnet"
  type        = string
  default     = "10.100.0.0/24"
}

variable "cloudflare_api_token" {
  description = "API token for Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for DNS management"
  type        = string
}


variable "prefect_helm_chart_version" {
  description = "Version of the Prefect Helm chart to deploy"
  type        = string  
}
