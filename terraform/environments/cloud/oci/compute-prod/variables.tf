# variables.tf
############################################
# Compartments
############################################
variable "compartment_id" {
  type        = string
  description = "The OCID of the parent compartment where the resources will be created."
}

variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the tenancy where the resources will be created."
}

variable "user_ocid" {
  type        = string
  description = "The OCID of the user."
}

variable "fingerprint" {
  type        = string
  description = "The fingerprint of the API key."
}

variable "region" {
  type        = string
  description = "The region where the resources will be created."
}

variable "compartment_name" {
  type        = string
  description = "Compartment Name"
  default     = "hushamsadd"
}

variable "compartment_description" {
  type        = string
  description = "The root Compartment of the tenancy. It is the parent of all other compartments in the tenancy. For more information, see Root Compartment (https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcompartments.htm#rootcompartment)."
  default     = "dev-compartment description"
}

############################################
# Network (VCN)
############################################
variable "vcn_config" {
  description = "Network configuration details for the main VCN"
  type = object({
    cidr_blocks  = list(string)
    display_name = string
  })
  default = {
    cidr_blocks  = ["10.24.0.0/20"]
    display_name = "dev_vcn_02"
  }
}

############################################
# Public Subnet & Route Table
############################################
variable "public_subnet_b_config" {
  description = "Configuration settings for Public Subnet B"
  type = object({
    cidr_block   = string
    display_name = string
    is_public    = bool
    route_table = object({
      display_name = string
      description  = string
    })
  })
  default = {
    cidr_block   = "10.24.11.0/24"
    display_name = "dev_pub_subnet_b"
    is_public    = true
    route_table = {
      display_name = "dev_pub_rt_b"
      description  = "Route table routing public traffic to the Internet Gateway"
    }
  }
}

############################################
# Internet Gateway
############################################
variable "internet_gateway_config" {
  description = "Configuration details for the Internet Gateway"
  type = object({
    display_name   = string
    ig_destination = string
  })
  default = {
    display_name   = "dev_internet_gateway"
    ig_destination = "0.0.0.0/0"
  }
}

############################################
# Compute Instance
############################################
variable "cloud-node-02" {
  description = "The details of the compute instance"
  default = {
    display_name : "cloud-node-02"
    assign_public_ip : true
    availability_domain : "JBGx:eu-amsterdam-1-AD-1"
    image_ocid : ""
    boot_volume_size_in_gbs = 50
    shape : {
      name          = "VM.Standard.A1.Flex"
      ocpus         = 1
      memory_in_gbs = 2
    }
  }
}

############################################
# Runtime / CI
############################################
variable "oci_private_key" {
  type        = string
  description = "OCI API signing private key supplied by Vault at runtime."
  sensitive   = true
}

variable "ssh_ca_public_key" {
  type        = string
  description = "Vault SSH user CA public key trusted by the VM."
}

variable "vm_user" {
  type        = string
  description = "Linux user used for SSH and Ansible."
  default     = "ubuntu"
}

variable "k3s_node_name" {
  type        = string
  description = "Node name registered with K3s."
  default     = "worker-3"
}


############################################
# Sensitive Variables
############################################
# variable "tailscale_auth_key" {
#   type        = string
#   description = "Ephemeral, reusable Tailscale auth key to join the mesh"
#   sensitive   = true
# }

# variable "private_key_path" {
#   type        = string
#   description = "The path to the private key file."
# }

# variable "ssh_authorized_keys_path" {
#   type        = string
#   description = "The path to the public key file."
# }

# variable "k3s_node_token" {
#   type        = string
#   description = "The K3s cluster node token to join the control plane"
#   sensitive   = true
# }