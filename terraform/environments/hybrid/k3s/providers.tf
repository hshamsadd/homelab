provider "kubernetes" {
  host = var.kube_api_endpoint
  config_path    = "~/.kube/config"
  config_context = "default"
}