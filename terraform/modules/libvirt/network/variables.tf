variable "name" {
  description = "Name of the network"
  type        = string
}

variable "mode" {
  description = "Network mode: nat or bridge"
  type        = string
}

variable "bridge_name" {
  description = "Name of the bridge (only used for bridge mode)"
  type        = string
  default     = "br0"
}

variable "ips" {
  description = "NAT mode IP configuration"
  type        = list(any)
  default     = []
}

variable "dns" {
  description = "NAT mode DNS configuration"
  type        = any
  default     = {}
}