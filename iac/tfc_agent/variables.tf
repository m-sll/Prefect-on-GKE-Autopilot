variable "TFC_AGENT_TOKEN" {
  description = "Terraform Cloud agent token"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "The zone for the GKE cluster"
  type        = string
  default     = "us-west1-a"
  
}