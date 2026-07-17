output "name" {
  value = libvirt_network.this[0].name
}

output "mode" {
  value = var.mode
}

output "ips" {
  value = var.mode == "nat" ? libvirt_network.this[0].ips : []
}