#################################
# Outputs
#################################

output "vm_ip" {
  value = try(data.libvirt_domain_interface_addresses.vm2_ip.interfaces[0].addrs[0].addr, "Waiting for DHCP...")
}

output "ssh_command" {
  value = try(
    "ssh -i ./ssh/terraform_vm_key.pem alpine@${data.libvirt_domain_interface_addresses.vm2_ip.interfaces[0].addrs[0].addr}",
    "IP not assigned yet"
  )
}

output "vm2_id" {
  value       = libvirt_domain.vm2.id
  description = "Domain ID for VM2"
}