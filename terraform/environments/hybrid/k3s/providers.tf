provider "kubernetes" {
  host = var.kube_api_endpoint
  # Point to your local secure token or configuration file securely
  config_path    = "~/.kube/config"
  config_context = "default"
}