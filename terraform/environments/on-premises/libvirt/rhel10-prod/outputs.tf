#################################
# Outputs
#################################
output "vm_name" {
  description = "Libvirt domain and Linux hostname."
  value       = libvirt_domain.vm.name
}

output "vm_ip" {
  description = "Reserved IPv4 address for the VM."
  value       = var.vm_ip
}

output "vm_user" {
  description = "Linux user used by Ansible."
  value       = var.vm_user
}

output "vm_mac" {
  description = "VM MAC address."
  value       = var.vm_mac
}

output "k3s_node_name" {
  description = "Node name registered with K3s."
  value       = var.k3s_node_name
}