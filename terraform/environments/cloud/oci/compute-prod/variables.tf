# variables.tf

############################################
# Compartments
############################################
variable "compartment_id" {
  description = "The OCID of the parent compartment where the resources will be created."
  type        = string
}

variable "tenancy_ocid" {
  description = "The OCID of the tenancy where the resources will be created."
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user."
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key."
  type        = string
}

variable "region" {
  description = "The region where the resources will be created."
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file."
  type        = string
}

variable "ssh_authorized_keys_path" {
  description = "The path to the public key file."
  type        = string
}

variable "compartment_name" {
  description = "Compartment Name"
  type        = string
  default     = "hushamsadd"
}

variable "compartment_description" {
  description = "The root Compartment of the tenancy. It is the parent of all other compartments in the tenancy. For more information, see Root Compartment (https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcompartments.htm#rootcompartment)."
  type        = string
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
      memory_in_gbs = 4
    }
  }
}

############################################
# Sensitive Variables
############################################

variable "tailscale_auth_key" {
  description = "Ephemeral, reusable Tailscale auth key to join the mesh"
  type        = string
  sensitive   = true
}

variable "k3s_node_token" {
  description = "The K3s cluster node token to join the control plane"
  type        = string
  sensitive   = true
}