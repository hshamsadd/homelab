#################################
# Outputs
#################################
output "vm_ip" {
  value = var.vm_ip
}

output "ssh_command" {
  description = "Command to SSH into the VM from the GitHub Runner"
  # We replaced 'ssh_private_key_path' with 'ansible_key_path' in locals.tf
  value = "ssh -i ${var.ssh_private_key_path} ${var.vm_user}@${var.vm_ip} -o StrictHostKeyChecking=no"
}

output "vm_inventory_path" {
  value = local.inventory_path
}


output "vm_inventory" {
  value = local_file.ansible_inventory.content
}