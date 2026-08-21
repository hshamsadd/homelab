variable "proxmox_endpoint" {
  type        = string
  description = "The Proxmox API Endpoint"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "The Proxmox API Token"
}