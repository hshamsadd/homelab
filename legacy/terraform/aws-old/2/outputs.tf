# Outputs
output "droplet_ip" {
  description = "The public IPv4 address of the droplet"
  value       = digitalocean_droplet.terra-droplet.ipv4_address
}

output "ssh_command" {
  description = "Command to SSH into the droplet"
  value       = "ssh -i ~/.ssh/id_terraform root@${digitalocean_droplet.terra-droplet.ipv4_address}"
}