# outputs.tf
output "compartment_id" {
  value       = var.compartment_id
  description = "The OCID of the compartment being deployed into."
}

output "vcn_id" {
  value       = oci_core_vcn.main.id
  description = "The OCID of the newly created Virtual Cloud Network."
}

output "public_subnet_b_id" {
  value       = oci_core_subnet.public_b.id
  description = "The OCID of the public subnet."
}

output "internet_gateway_id" {
  value       = oci_core_internet_gateway.main.id
  description = "The OCID of the internet gateway."
}

output "public_route_table_id" {
  value       = oci_core_default_route_table.public_rt.id
  description = "The OCID of the managed default route table."
}

output "compute_instance_id" {
  value       = oci_core_instance.cloud-node-02.id
  description = "The OCID of the deployed compute engine VM instance."
}

# --- Recommended Additions ---

output "instance_public_ip" {
  value       = oci_core_instance.cloud-node-02.public_ip
  description = "The public IP address assigned to the virtual machine."
}

output "instance_private_ip" {
  value       = oci_core_instance.cloud-node-02.private_ip
  description = "The private internal IP address within the subnet range."
}