# AWS region to deploy resources
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet CIDR
variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# EC2 instance type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# Path to save the generated private key
variable "private_key_path" {
  description = "Local path to save the private key for SSH"
  type        = string
  default     = "/home/zshamsadd/Downloads/terraform-key.pem"
}





# # AWS region to deploy resources
# variable "aws_region" {
#   description = "AWS region to deploy resources"
#   type        = string
#   default     = "eu-west-1"
# }

# # VPC CIDR
# variable "vpc_cidr" {
#   description = "CIDR block for the VPC"
#   type        = string
#   default     = "10.0.0.0/16"
# }

# # Subnet CIDR
# variable "subnet_cidr" {
#   description = "CIDR block for the public subnet"
#   type        = string
#   default     = "10.0.1.0/24"
# }

# # EC2 instance type
# variable "instance_type" {
#   description = "EC2 instance type"
#   type        = string
#   default     = "t3.micro"
# }

# # Path to your public key for EC2 key pair
# variable "public_key_path" {
#   description = "Path to your public key file"
#   type        = string
#   default     = "/home/zshamsadd/Downloads/my-ec2-key.pub"
# }















# # AWS region to deploy resources
# variable "aws_region" {
#   description = "AWS region to deploy resources"
#   type        = string
#   default     = "eu-west-1"
# }

# # VPC CIDR
# variable "vpc_cidr" {
#   description = "CIDR block for the VPC"
#   type        = string
#   default     = "10.0.0.0/16"
# }

# # Subnet CIDR
# variable "subnet_cidr" {
#   description = "CIDR block for the public subnet"
#   type        = string
#   default     = "10.0.1.0/24"
# }

# # EC2 instance type
# variable "instance_type" {
#   description = "EC2 instance type"
#   type        = string
#   default     = "t3.micro"
# }

# # EC2 AMI (Amazon Linux 2023)
# variable "ami_id" {
#   description = "AMI ID for EC2 instance"
#   type        = string
#   default     = "ami-0aeeebd8d2ab47354"  # replace with region-specific AMI if needed
# }

# # Key pair name for SSH access (optional)
# variable "key_name" {
#   description = "Existing EC2 key pair for SSH access"
#   type        = string
#   default     = ""
# }
