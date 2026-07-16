terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

provider "aws" {
  region = var.REGION
}

provider "tls" {
  # TLS provider usually doesn’t need config
}

#################################
# Networking
#################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-public-rt"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#################################
# Security Group
#################################

resource "aws_security_group" "web_sg" {
  name        = "terraform-web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################
# SSH Key
#################################

# Generate an ED25519 key pair locally
resource "tls_private_key" "ec2_key" {
  algorithm = "ED25519"
}

# Upload the public key to AWS as a key pair
resource "aws_key_pair" "aws_key" {
  key_name   = "ec2-key-final"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "null_resource" "create_ssh_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/ssh && chmod 700 ${path.module}/ssh"
  }
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/ssh/ec2-key-final.pem"
  file_permission = "0400" # Important: SSH keys require strict permissions

  depends_on = [null_resource.create_ssh_dir]
}


#################################
# Amazon EC2 Instance
#################################

resource "aws_instance" "terra-ec2" {
  ami                         = var.AMI
  instance_type               = var.TYPE
  key_name                    = aws_key_pair.aws_key.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name        = "Terraform-EC2"
    Environment = "Dev"
  }
}



# terraform {
#   required_version = "~> 1.14.0"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 6.36.0"
#     }
#     tls = {
#       source  = "hashicorp/tls"
#       version = "~> 4.0.0"
#     }
#   }
# }

# provider "aws" {
#   region = var.REGION
# }

# provider "tls" {
#   # TLS provider usually doesn’t need config
# }

# # # Amazon Key pair
# # resource "aws_key_pair" "aws-key" {
# #   key_name   = "ec2-key-final"           // private key
# #   public_key = file("ec2-key-final.pub") // public key
# # }

# # Generate an ED25519 key pair locally
# resource "tls_private_key" "ec2_key" {
#   algorithm = "ED25519"
# }

# # Upload the public key to AWS as a key pair
# resource "aws_key_pair" "aws_key" {
#   key_name   = "ec2-key-final"
#   public_key = tls_private_key.ec2_key.public_key_openssh
# }

# # Amazon EC2 Instance Resource
# resource "aws_instance" "terra-ec2" {
#   ami                         = var.AMI
#   instance_type               = var.TYPE
#   key_name                    = aws_key_pair.aws_key.key_name
#   vpc_security_group_ids      = var.SECURITY_GROUP_IDS
#   subnet_id                   = "subnet-057d9cb6ec49d25d4"
#   associate_public_ip_address = true
#   tags = {
#     Name        = "Terraform-EC2"
#     Environment = "Dev"
#   }
# }



# resource "aws_vpc" "example" {
# cidr_block = "10.0.0.0/16"
# }

