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
# output "vm_ip" {
#   value = var.vm_ip
# }

# output "ssh_command" {
#   description = "Command to SSH into the VM from the GitHub Runner"
#   # We replaced 'ssh_private_key_path' with 'ansible_key_path' in locals.tf
#   value = "ssh -i ${var.ssh_private_key_path} ${var.vm_user}@${var.vm_ip} -o StrictHostKeyChecking=no"
# }

# output "vm_inventory_path" {
#   value = local.inventory_path
# }


# output "vm_inventory" {
#   value = local_file.ansible_inventory.content
# }