variable "DO_TOKEN" {
  description = "dop_v1_38d70df10ab2c90d87bf4b1f1b6d9f269a7273077c38ebbaa1c8f25c31f0dc8e"
  type        = string
  sensitive   = true
}

variable "REGION" {
  default = "nyc3"
}

variable "TYPE" {
  default = "s-1vcpu-1gb"
}

variable "IMAGE" {
  default = "ubuntu-22-04-x64"
}

# variable "SSH_KEYS" {
#   type    = list(string)
#   default = [] # Add your SSH key IDs
# }