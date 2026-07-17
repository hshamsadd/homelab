# main.tf

############################################
# Virtual Cloud Network (VCN)
############################################
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_config.cidr_blocks
  display_name   = var.vcn_config.display_name
}

############################################
# Public Subnet
############################################
resource "oci_core_subnet" "public_b" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = var.public_subnet_b_config.cidr_block
  display_name   = var.public_subnet_b_config.display_name
  
  # FIX: Change 'route_table_id' to point directly to the VCN's default table ID attribute.
  # This enforces the default lookup mapping safely.
  route_table_id = oci_core_vcn.main.default_route_table_id

  prohibit_public_ip_on_vnic = !var.public_subnet_b_config.is_public
  prohibit_internet_ingress  = !var.public_subnet_b_config.is_public
  security_list_ids          = [oci_core_security_list.public_sl.id]
}

############################################
# Internet Gateways
############################################
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = var.internet_gateway_config.display_name
  enabled        = true
}

############################################
# Route Tables
############################################
resource "oci_core_default_route_table" "public_rt" {
  compartment_id             = var.compartment_id
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id
  display_name               = var.public_subnet_b_config.route_table.display_name

  route_rules {
    destination       = var.internet_gateway_config.ig_destination
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
    description       = var.public_subnet_b_config.route_table.description
  }
}

############################################
# Security List (Subnet Firewall Rules)
############################################
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "dev_public_security_list"

  # Stateful egress: Allows tracked traffic out to anywhere
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }

  # Stateful ingress: Allows tracked SSH traffic in from anywhere
  ingress_security_rules {
    protocol    = "all" # CHANGE THIS TO "tcp" IF YOU ONLY WANT TO ALLOW TCP PORT 22
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "Allow all inbound traffic types globally (for testing purposes only) Mimic vanilla OS: Allow all inbound traffic globally"
    stateless   = false
  }
}

# ############################################
# # Data Source: Dynamic Ubuntu 22.04 ARM Finder
# # ############################################
data "oci_core_images" "latest_ubuntu_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.cloud-node-02.shape.name
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}


# ############################################
# # Compute Instance
# ############################################
resource "oci_core_instance" "cloud-node-02" {
  compartment_id      = var.compartment_id
  shape               = var.cloud-node-02.shape.name
  availability_domain = var.cloud-node-02.availability_domain
  display_name        = var.cloud-node-02.display_name

  source_details {
    source_id               = data.oci_core_images.latest_ubuntu_arm.images[0].id
    source_type             = "image"
    boot_volume_size_in_gbs = var.cloud-node-02.boot_volume_size_in_gbs
  }

  shape_config {
    memory_in_gbs = var.cloud-node-02.shape.memory_in_gbs
    ocpus         = var.cloud-node-02.shape.ocpus
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_b.id
    assign_public_ip = var.cloud-node-02.assign_public_ip
  }

  metadata = {
    #ssh_authorized_keys = join("\n", [for k in var.cloud-node-02.ssh_authorized_keys : chomp(k)])
    ssh_authorized_keys = file(var.ssh_authorized_keys_path)
    # THE CLOUD-INIT HANDOFF
    user_data = base64encode(<<-EOF
      #!/bin/bash
      # 1. Update and install prerequisites
      apt-get update && apt-get install -y curl apt-transport-https

      # 2. Install Tailscale
      curl -fsSL https://tailscale.com/install.sh | sh
      tailscale up --authkey=${var.tailscale_auth_key} --hostname=${var.cloud-node-02.display_name}

      # 3. Wait for Tailscale interface to be ready
      sleep 10
      TAILSCALE_IP=$(tailscale ip -4)

      # 4. Install K3s and join the mesh API
      curl -sfL https://get.k3s.io | K3S_URL=https://100.76.59.49:6443 \
      K3S_TOKEN="${var.k3s_node_token}" \
      INSTALL_K3S_EXEC="agent --node-ip=$TAILSCALE_IP --flannel-iface=tailscale0" sh -
    EOF
    )
  }
}