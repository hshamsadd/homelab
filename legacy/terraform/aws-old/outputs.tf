# Outputs
# Public IP of the EC2 instance
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance for SSH access"
  value       = aws_instance.terra-ec2.public_ip
}

# Private key (sensitive)
output "private_key_pem" {
  description = "The private key PEM for SSH"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

# SSH command for easy copy-paste
# output "ec2_ssh_command" {
#   description = "SSH command to connect to the EC2 instance"
#   value       = "ssh -i ${path.module}/ec2-key-final.pem ${var.USER}@${aws_instance.terra-ec2.public_ip}"
# }

output "ssh_instructions" {
  description = "Clean instructions for connecting"
  value       = <<EOT
    1. Ensure permissions: chmod 400 ${local_file.ssh_key.filename}
    2. Connect: ssh -i ${local_file.ssh_key.filename} ${var.USER}@${aws_instance.terra-ec2.public_ip}
  EOT
}

# VPC ID
output "vpc_id" {
  description = "VPC ID of the created network"
  value       = aws_vpc.main.id
}

# Security Group ID
output "security_group_id" {
  description = "Security Group ID allowing SSH/HTTP"
  value       = aws_security_group.web_sg.id
}

# Subnet ID
output "subnet_id" {
  description = "Public Subnet ID where EC2 is launched"
  value       = aws_subnet.public.id
}

# output "ec2_public_ip" {
#   description = "Public IP address of the EC2 instance for SSH access"
#   value       = aws_instance.terra-ec2.public_ip
# }

# # Output the private key (for SSH)
# output "private_key_pem" {
#   value     = tls_private_key.ec2_key.private_key_pem
#   sensitive = true
# }

# # Output the public IP for SSH
# output "ec2_public_ip" {
#   value = aws_instance.terra_ec2.public_ip
# }

# output "ec2_ssh_command" {
#   description = "SSH command to connect to the EC2 instance"
#   value       = "ssh -i ~/.ssh/${var.KEY}.pem ec2-user@${aws_instance.terra-ec2.public_ip}"
# }