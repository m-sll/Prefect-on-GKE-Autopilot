// Terraform variables definitions moved from main.tf
variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}


variable "gke_autopilot_name" {
  description = "Name of the GKE Autopilot cluster"
  type        = string
}

variable "cluster_ipv4_cidr_block" {
  description = "CIDR block for the cluster IP allocation"
  type        = string
}

variable "services_ipv4_cidr_block" {
  description = "CIDR block for the services IP allocation"
  type        = string
}


variable "cluster_dns_domain" {
  description = "DNS domain for the cluster"
  type        = string
  default     = "cluster.local"
}

variable "env" {
    description = "Environment for the deployment (e.g., dev, prod)"
    type        = string
    default     = "dev"
}

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = true
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
  default     = "us-west1"
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

variable "prefect_worker_subnet_cidr" {
  description = "CIDR block for Prefect worker subnet"
  type        = string
  default     = "10.100.0.0/24"
}

variable "docker_repo_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "prefect-runner-image"
}

variable "prefect_helm_chart_version" {
  description = "Version of the Prefect Helm chart to deploy"
  type        = string  
}

variable "gke_auth_ips" {
  description = "List of IPs for GKE authentication"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}