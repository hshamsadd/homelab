terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26.0"
    }
  }
}

provider "kubernetes" {
  host = var.kube_api_endpoint

  # Point to your local secure token or configuration file securely
  config_path    = "~/.kube/config"
  config_context = "default"
}