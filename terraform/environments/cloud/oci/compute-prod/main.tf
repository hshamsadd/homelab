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
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "Temporary public SSH access protected by Vault SSH certificates"
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
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
    user_data = base64encode(<<-EOF
    #!/usr/bin/env bash
    set -Eeuo pipefail

    install \
      -d \
      -m 0755 \
      /etc/ssh/sshd_config.d

    cat > /etc/ssh/vault-user-ca.pub <<'VAULT_CA_EOF'
    ${trimspace(var.ssh_ca_public_key)}
    VAULT_CA_EOF

    chmod \
      0644 \
      /etc/ssh/vault-user-ca.pub

    cat > /etc/ssh/sshd_config.d/90-vault-user-ca.conf <<'SSHD_EOF'
    TrustedUserCAKeys /etc/ssh/vault-user-ca.pub
    PubkeyAuthentication yes
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PermitRootLogin no
    SSHD_EOF

    /usr/sbin/sshd -t

    systemctl restart ssh
  EOF
    )
  }
}