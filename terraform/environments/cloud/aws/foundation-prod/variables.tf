variable "vm_name" {
  type        = string
  description = "Name of the virtual machine."
  default     = "ec2"
}

variable "vm_user" {
  type        = string
  description = "Linux user used for SSH and Ansible."
  default     = "ubuntu"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.24.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the subnet."
  default     = "10.24.11.0/24"
}

variable "instance_type" {
  type        = string
  description = "Type of the EC2 instance."
  default     = "t3.micro"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the infrastructure."
  default     = "eu-west-1"
}

variable "k3s_node_name" {
  type        = string
  description = "Node name registered with K3s."
  default     = "worker-node"
}