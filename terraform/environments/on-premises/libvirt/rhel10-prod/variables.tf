variable "libvirt_uri" {
  description = "Libvirt connection URI. Local workflows use qemu:///system; remote workflows override it with qemu+sshcmd."
  type        = string
  default     = "qemu:///system"
}

variable "vm_user" {
  description = "Linux administrative user created by cloud-init."
  type        = string
  default     = "ubuntu"
}

variable "network_name" {
  description = "Name of the libvirt network."
  type        = string
  default     = "terraform-nat-1"
}

variable "network_mode" {
  description = "Libvirt network forwarding mode."
  type        = string
  default     = "nat"

  validation {
    condition     = var.network_mode == "nat"
    error_message = "This environment currently supports only NAT networking."
  }
}

variable "bridge_name" {
  description = "Libvirt bridge name."
  type        = string
  default     = "virbr150"
}

variable "network_address" {
  description = "IPv4 gateway for the libvirt NAT network."
  type        = string
  default     = "192.168.150.1"
}

variable "vm_ip" {
  description = "Reserved DHCP address for the VM."
  type        = string
  default     = "192.168.150.5"
}

variable "vm_mac" {
  description = "Stable MAC address for the VM."
  type        = string
  default     = "52:54:00:5d:c7:9e"
}

variable "vm_hostname" {
  description = "Libvirt domain and Linux hostname."
  type        = string
  default     = "ubuntu-vm-1"
}

variable "k3s_node_name" {
  description = "Node name registered in the K3s cluster."
  type        = string
  default     = "worker-3"
}

variable "vm_memory" {
  description = "VM memory in MiB."
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "Number of virtual CPUs."
  type        = number
  default     = 2
}

variable "disk_capacity" {
  description = "VM disk size in bytes."
  type        = number
  default     = 10737418240
}

variable "pool_name" {
  description = "Libvirt storage pool."
  type        = string
  default     = "default"
}

variable "ubuntu_image_url" {
  description = "Ubuntu 24.04 cloud image URL."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}