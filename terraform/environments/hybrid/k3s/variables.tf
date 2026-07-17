variable "kube_api_endpoint" {
  type        = string
  description = "The Tailscale internal IP address for the K3s API control plane control layer."
  default     = "https://100.76.59.49:6443"
}

variable "environments" {
  type        = list(string)
  description = "Target deployment namespaces to initialize inside the cluster mesh."
  default     = ["dev", "staging", "testing", "production", "monitoring", "gitops-system"]
}