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

# variable "libvirt_host" {
#   type    = string
#   default = "100.76.59.49"
# }

# variable "libvirt_user" {
#   type    = string
#   default = "zshamsadd"
# }

# variable "ssh_private_key_path" {
#   type        = string
#   description = "Absolute path to the SSH private key used for libvirt and VM access"
#   #description = "Path to the SSH private key"
#   #default = "~/.ssh/github_actions_libvirt_key"
# }

# variable "vm_public_key" {
#   type = string
#   description = "Public SSH key for the VM"
#   default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEF64ywYSV1/p7I2Fm3z/Yrc4xYLTu1UEW5uTcRYdLv github-actions-libvirt"
# }

# variable "network_mode" {
#   type        = string
#   description = "Defines the type of network to create. 'nat' creates a NAT network, 'bridge' creates a bridged network, 'route' creates a routed network, and 'open' creates an open network without isolation."
#   default     = "nat"
#   validation {
#     condition     = contains(["nat"], var.network_mode)
#     error_message = "For now, only nat mode is supported by this module."
#   }
# }


# #variable "bridge_name" { default = "br0" } # only used if mode = bridge

# variable "bridge_name" {
#   type        = string
#   description = "Libvirt bridge name for the NAT network"
#   default     = "virbr150"
# }

# # Only used for NAT mode
# variable "network_address" {
#   type        = string
#   description = "Gateway IP for the libvirt NAT network"
#   default     = "192.168.150.1" # This is the gateway IP for the NAT network. The VM will get an IP in the same subnet, e.g.,
# }

# variable "vm_ip" {
#   type    = string
#   default = "192.168.150.5" # This is the static IP address that will be assigned to the VM. Make sure it is within the subnet defined by network_address and does not conflict with other devices.
# }

# variable "vm_mac" {
#   type    = string
#   default = "52:54:00:5d:c7:9e" # This is a randomly generated MAC address. You can change it if needed, but make sure it doesn't conflict with other devices on the network.
# }

# variable "vm_hostname" {
#   type    = string
#   default = "ubuntu-vm-1" # This is the hostname that will be set inside the VM, and also used in cloud-init
# }

# # variable "vm_memory" {
# #   default = 2097152 # 2 GiB in KiB
# # }

# variable "vm_memory" {
#   type        = number
#   description = "VM memory in MiB"
#   default     = 2048
# }
# variable "vm_vcpu" {
#   type    = number
#   default = 2
# }

# variable "disk_capacity" {
#   type        = number
#   description = "Disk size in bytes"
#   default     = 10737418240
# }

# variable "ansible_ssh_common_args" {
#   type        = string
#   description = "Extra SSH args Ansible should pass (e.g. ProxyCommand/ProxyJump)."
#   default     = "-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q zshamsadd@100.76.59.49 -i /home/runner/.ssh/id_ed25519_github_actions -o StrictHostKeyChecking=no\""
#   # default     = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# }