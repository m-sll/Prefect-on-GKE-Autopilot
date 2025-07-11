cluster_ipv4_cidr_block  = "10.4.0.0/14"
services_ipv4_cidr_block = "10.0.32.0/20"
gke_autopilot_name       = "bigbang-lab"
cluster_dns_domain = "bigbang-cluster"
project_id = "gcp-ok8s"
deletion_protection = true
env = "prod"
region = "us-west1"
prefect_domain = "prefect.plusai.is"
gke_auth_ips = []
prefect_helm_chart_version = "2025.6.26211534"  # Specify the version of the Prefect Helm chart to deploy
prefect_worker_image = {
      repository = "ok8s/prefect-gcp"
      prefectTag = "3.4.7"
}
docker_repo_name = "prefect-ok8s"
cloudflare_api_token = ""
cloudflare_zone_id=""