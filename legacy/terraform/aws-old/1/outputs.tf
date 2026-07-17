# Outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

# output "private_key_path" {
#   description = "Path to the private key saved locally"
#   value       = var.private_key_path
# }







# # outputs.tf
# output "ec2_instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.web.id
# }

# output "ec2_public_ip" {
#   description = "Public IP of the EC2 instance"
#   value       = aws_instance.web.public_ip
# }