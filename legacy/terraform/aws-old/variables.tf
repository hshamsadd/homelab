variable "USER" {
  type    = string
  default = "ec2-user"
}

variable "REGION" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "AMI" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-096a4fdbcf530d8e0"
}

variable "TYPE" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

//////////////////////////////////////////////////////////////////
# variable "KEY" {
#   description = "Key pair name for SSH access"
#   type        = string
#   default     = "terraform-key"
# }
