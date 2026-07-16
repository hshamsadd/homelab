# variable "libvirt_uri" {
#   default = "qemu:///system" # This is the default URI for connecting to the libvirt daemon. You can change it if you have a different setup.
# }

# variable "libvirt_uri" {
#   description = "The connection URI for the libvirt provider"
#   type        = string
#   # Default for local development, GitHub will override this with the Tailscale IP
#   default = "qemu+ssh://${var.libvirt_user}@${var.libvirt_host}/system?sshauth=privkey&keyfile=${local.ansible_key_path}&known_hosts_verify=ignore"
# }

# variable "libvirt_uri" {
#   type        = string
#   description = "Connection URI for the remote libvirt host"
#   sensitive   = true
# }

variable "libvirt_host" {
  type    = string
  default = "100.76.59.49"
}

variable "libvirt_user" {
  type    = string
  default = "zshamsadd"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Absolute path to the SSH private key used for libvirt and VM access"
  #description = "Path to the SSH private key"
  #default = "~/.ssh/github_actions_libvirt_key"
}

variable "vm_public_key" {
  type = string
  description = "Public SSH key for the VM"
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEF64ywYSV1/p7I2Fm3z/Yrc4xYLTu1UEW5uTcRYdLv github-actions-libvirt"
}

variable "vm_user" {
  type    = string
  default = "ubuntu"
}

variable "network_name" {
  type    = string
  default = "terraform-nat-1" # This is the name of the libvirt network that will be created. You can change it if needed, but make sure it doesn't conflict with existing networks.
}

variable "network_mode" {
  type        = string
  description = "Defines the type of network to create. 'nat' creates a NAT network, 'bridge' creates a bridged network, 'route' creates a routed network, and 'open' creates an open network without isolation."
  default     = "nat"
  validation {
    condition     = contains(["nat"], var.network_mode)
    error_message = "For now, only nat mode is supported by this module."
  }
}


#variable "bridge_name" { default = "br0" } # only used if mode = bridge

variable "bridge_name" {
  type        = string
  description = "Libvirt bridge name for the NAT network"
  default     = "virbr150"
}

# Only used for NAT mode
variable "network_address" {
  type        = string
  description = "Gateway IP for the libvirt NAT network"
  default     = "192.168.150.1" # This is the gateway IP for the NAT network. The VM will get an IP in the same subnet, e.g.,
}

variable "vm_ip" {
  type    = string
  default = "192.168.150.5" # This is the static IP address that will be assigned to the VM. Make sure it is within the subnet defined by network_address and does not conflict with other devices.
}

variable "vm_mac" {
  type    = string
  default = "52:54:00:5d:c7:9e" # This is a randomly generated MAC address. You can change it if needed, but make sure it doesn't conflict with other devices on the network.
}

variable "vm_hostname" {
  type    = string
  default = "ubuntu-vm-1" # This is the hostname that will be set inside the VM, and also used in cloud-init
}

# variable "vm_memory" {
#   default = 2097152 # 2 GiB in KiB
# }

variable "vm_memory" {
  type        = number
  description = "VM memory in MiB"
  default     = 2048
}
variable "vm_vcpu" {
  type    = number
  default = 2
}

variable "disk_capacity" {
  type        = number
  description = "Disk size in bytes"
  default     = 10737418240
}

variable "pool_name" {
  type    = string
  default = "default" # This is the name of the libvirt storage pool where the VM's disk image will be created. "default" is a common pool, but you can change it if you have a different setup.
}

variable "ubuntu_image_url" {
  type = string
  #default = "/var/lib/libvirt/images/ubuntu-22.04-base-20260329.qcow2"
  #default = "file:///var/lib/libvirt/images/ubuntu-22.04-base-20260329.qcow2" # This is the URL of the Ubuntu cloud image that will be used as the base for the VM. You can change it to use a different image or version if needed.
  #default = "https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

}

variable "ansible_ssh_common_args" {
  type        = string
  description = "Extra SSH args Ansible should pass (e.g. ProxyCommand/ProxyJump)."
  default     = "-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q zshamsadd@100.76.59.49 -i /home/runner/.ssh/id_ed25519_github_actions -o StrictHostKeyChecking=no\""
  # default     = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

}