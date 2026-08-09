# Outputs
output "vm_name" {
  description = "Name of the AWS EC2 worker"
  value       = var.vm_name
}

output "vm_user" {
  description = "SSH user for the AWS EC2 worker"
  value       = var.vm_user
}

output "k3s_node_name" {
  description = "Kubernetes and Tailscale node name"
  value       = var.k3s_node_name
}

output "instance_id" {
  description = "AWS EC2 instance ID"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group attached to the EC2 worker"
  value       = aws_security_group.web_sg.id
}

output "vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "AWS subnet ID"
  value       = aws_subnet.public.id
}

output "vm_private_ip" {
  description = "Private IPv4 address of the EC2 worker"
  value       = aws_instance.web.private_ip
}

output "vm_public_ip" {
  description = "Public IPv4 address used only for outbound internet connectivity"
  value       = aws_instance.web.public_ip
}