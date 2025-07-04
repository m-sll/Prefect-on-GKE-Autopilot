terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.38.0"
    }
    helm = {
      source  = "hashicorp/helm"   # official provider
      version = ">= 2.13.0"        # any 2.x supports kubernetes {}
    }
    prefect = {
      source  = "PrefectHQ/prefect"
      version = ">= 0.2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
  cloud {
    organization = "bigbang-lab"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "this" {}

data google_container_cluster "this" {
  name     = "${var.gke_autopilot_name}-${var.env}"
  location = var.region
}
# Build an inline kube-config from the cluster we just created
provider "helm" {
  kubernetes = {
    host                   = "https://${data.google_container_cluster.this.private_cluster_config[0].private_endpoint}"
    token                  = data.google_client_config.this.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.this.master_auth[0].cluster_ca_certificate
    )
  }
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.private_cluster_config[0].private_endpoint}"
  token                  = data.google_client_config.this.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.this.master_auth[0].cluster_ca_certificate
  )
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "google_compute_global_address" "prefect_ingress_static_ip" {
  name         = "prefect-static-ip"
  address_type = "EXTERNAL"   # implied for global, but explicit is fine
  ip_version   = "IPV4"       # optional; defaults to IPv4
}

resource "helm_release" "prefect_server" {      # <-- use the inline kube-config
  name       = "prefect-server"
  repository = "https://prefecthq.github.io/prefect-helm"
  chart      = "prefect-server"
  version    = var.prefect_helm_chart_version
  namespace  = var.namespace_prefect_server

  values = [
    templatefile("${path.module}/helm/values.prefect-server.yaml", {
      prefectTag          = var.prefect_server_image_tag
    })
  ]
}

resource "kubernetes_manifest" "prefect_cert" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "ManagedCertificate"
    "metadata" = {
      "name"      = "prefect-tls-cert"
      "namespace" = var.namespace_prefect_server
    }
    "spec" = {
      "domains" = [
        var.prefect_domain,
      ]
    }
  }
  depends_on = [helm_release.prefect_server]
}

# resource "google_compute_ssl_policy" "prefect_tls_modern" {
#   name            = "prefect-tls-modern"
#   profile         = "MODERN"
#   min_tls_version = "TLS_1_2"
# }

# resource "kubernetes_manifest" "prefect_frontend_config" {
#   manifest = {
#     apiVersion = "networking.gke.io/v1beta1"
#     kind       = "FrontendConfig"
#     metadata = {
#       name = "prefect-frontend-config"
#       namespace = var.namespace_prefect_server
#     }
#     spec = {
#       sslPolicy = google_compute_ssl_policy.prefect_tls_modern.name

#       redirectToHttps = {
#         enabled          = true
#         responseCodeName = "PERMANENT_REDIRECT"
#       }
#     }
#   }

#   depends_on = [google_compute_ssl_policy.prefect_tls_modern]
# }