# variable "libvirt_uri" {
#   default = "qemu:///system" # This is the default URI for connecting to the libvirt daemon. You can change it if you have a different setup.
# }

# variable "libvirt_uri" {
#   description = "The connection URI for the libvirt provider"
#   type        = string
#   # Default for local development, GitHub will override this with the Tailscale IP
#   default = "qemu+ssh://${var.libvirt_user}@${var.libvirt_host}/system?sshauth=privkey&keyfile=${local.ansible_key_path}&known_hosts_verify=ignore"
# }

variable "libvirt_host" {
  type    = string
  description = "The IP address or hostname of the libvirt host"
}

variable "libvirt_user" {
  type    = string
  description = "The username to use for SSH connections to the libvirt host"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key"
}

variable "vm_public_key_path" {
  type        = string
  description = "The path to the public key file."
}

variable "vm_user" {
  type        = string
  description = "The username to use for SSH connections to the VM"
}

variable "network_name" {
  type        = string
  description = "The name of the libvirt network to create"
  default = "terraform-nat-1" # This is the name of the libvirt network that will be created. You can change it if needed, but make sure it doesn't conflict with existing networks.
}

variable "network_mode" {
  type        = string
  description = "Defines the type of network to create. 'nat' creates a NAT network, 'bridge' creates a bridged network, 'route' creates a routed network, and 'open' creates an open network without isolation."
  default     = "nat"
}

variable "bridge_name" { 
  type = string 
  description = "The name of the bridge network to create" # only used if mode = bridge
  default = "br0" 
}

# Only used for NAT mode
variable "network_address" {
  type = string
  description = "The network address for the NAT network. The VM will get an IP in the same subnet, e.g., 192.167.140.0/24"
}

variable "vm_ip" {
  type = string
  description = "This is the static IP address that will be assigned to the VM. Make sure it is within the subnet defined by network_address and does not conflict with other devices."
}

variable "vm_mac" {
  type = string
  description = "This is a randomly generated MAC address. You can change it if needed, but make sure it doesn't conflict with other devices on the network."
}

variable "vm_hostname" {
  type = string
  description = "This is the hostname that will be set inside the VM, and also used in cloud-init"
  default = "ubuntu-vm-1"
}

variable "vm_memory" {
  type = number
  description = "This is the amount of memory (in bytes) that will be allocated to the VM. You can change it if needed, but make sure it is within the limits of your host machine."
  default = 2097152
}

variable "vm_vcpu" {
  type = number
  description = "This is the number of virtual CPUs that will be allocated to the VM. You can change it if needed, but make sure it is within the limits of your host machine."
  default = 1
}

variable "disk_capacity" {
  type = number
  description = "The capacity of the disk (in bytes) for the VM"
  default = 10737418240 # 10GB in bytes
}

variable "pool_name" {
  type = string
  description = "This is the name of the libvirt storage pool where the VM's disk image will be created. 'default' is a common pool, but you can change it if you have a different setup."
  default = "default"
}

variable "ubuntu_image_url" {
  type = string
  description = "This is the URL of the Ubuntu cloud image that will be used as the base for the VM. You can change it to use a different image or version if needed."
}

variable "ansible_ssh_common_args" {
  type        = string
  description = "Extra SSH args Ansible should pass (e.g. ProxyCommand/ProxyJump)."
}


############################################
# Sensitive Variables
############################################

# variable "tailscale_auth_key" {
#   type        = string
#   description = "Ephemeral, reusable Tailscale auth key to join the mesh"
#   sensitive   = true
# }

# variable "k3s_node_token" {
#   type        = string
#   description = "The K3s cluster node token to join the control plane"
#   sensitive   = true
# }