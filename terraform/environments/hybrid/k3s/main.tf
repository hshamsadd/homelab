# Create Core Namespaces Declaratively
resource "kubernetes_namespace" "env" {
  for_each = toset(var.environments)

  metadata {
    name = each.value
    labels = {
      "apps.home.lab/managed-by" = "terraform"
      "apps.home.lab/environment" = each.value
      "network/mesh-enabled"     = "tailscale"
    }
  }
  # Add this block to ignore ArgoCD's tracking annotations
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["argocd.argoproj.io/tracking-id"]
    ]
  }
}

# Senior Resource Guardrails: Limit staging resource footprint to protect prod database workers
resource "kubernetes_resource_quota" "staging_quota" {
  metadata {
    name      = "staging-compute-guardrails"
    namespace = "staging"
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "4Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "8Gi"
      "pods"            = "15"
    }
  }
  depends_on = [kubernetes_namespace.env]
}

resource "kubernetes_resource_quota" "production_quota" {
  metadata {
    name      = "production-compute-guardrails"
    namespace = "production"
  }
  spec {
    hard = {
      "requests.cpu"    = "4"
      "requests.memory" = "8Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "12Gi"
      "pods"            = "25"
    }
  }
  depends_on = [kubernetes_namespace.env]
}