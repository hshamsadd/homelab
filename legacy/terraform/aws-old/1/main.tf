terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}


resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = file("~/Downloads/terraform-key-openssh.pem.pub")
}

#################################
# AMI lookup
#################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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
# EC2
#################################

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  key_name = aws_key_pair.terraform_key.key_name

  tags = {
    Name = "terraform-web-instance"
  }
}


# terraform {
#   required_version = "~> 1.14.0"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 6.36.0"
#     }
#   }
# }

# # Configure AWS provider
# provider "aws" {
#   region = var.aws_region
# }

# # Lookup latest Amazon Linux 2 AMI
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# # Create a VPC
# resource "aws_vpc" "main" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "terraform-vpc"
#   }
# }

# # Public subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.subnet_cidr
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "terraform-public-subnet"
#   }
# }

# # Internet Gateway
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "terraform-igw"
#   }
# }

# # Public route table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "terraform-public-rt"
#   }
# }

# # Associate subnet with route table
# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# # Default route to Internet Gateway
# resource "aws_route" "internet_access" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }

# # Security group
# resource "aws_security_group" "web_sg" {
#   name        = "terraform-web-sg"
#   description = "Allow SSH and HTTP"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "All outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "terraform-web-sg"
#   }
# }

# # AWS key pair generated by Terraform
# resource "aws_key_pair" "terraform_key" {
#   key_name_prefix = "terraform-key-"
#   # Terraform will generate the private key
#   provisioner "local-exec" {
#     command = <<EOT
#       echo '${self.private_key}' > ${var.private_key_path} && chmod 400 ${var.private_key_path}
#     EOT
#   }
# }

# # EC2 instance
# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.web_sg.id]
#   key_name               = aws_key_pair.terraform_key.key_name

#   tags = {
#     Name = "terraform-web-instance"
#   }
# }




# terraform {
#   required_version = "~> 1.14.0"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 6.36.0"
#     }
#   }
# }

# # Configure AWS provider
# provider "aws" {
#   region = var.aws_region
# }

# # Lookup latest Amazon Linux 2023 AMI
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2", "amzn-ami-hvm-*-x86_64-gp2", "amzn-ami-kernel-6*-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# # Create a VPC
# resource "aws_vpc" "main" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "terraform-vpc"
#   }
# }

# # Create a public subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.subnet_cidr
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "terraform-public-subnet"
#   }
# }

# # Internet Gateway
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "terraform-igw"
#   }
# }

# # Route table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "terraform-public-rt"
#   }
# }

# # Associate subnet with route table
# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# # Default route to IGW
# resource "aws_route" "internet_access" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }

# # Security group allowing SSH and HTTP
# resource "aws_security_group" "web_sg" {
#   name        = "terraform-web-sg"
#   description = "Allow SSH and HTTP"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "All outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "terraform-web-sg"
#   }
# }

# # Create an EC2 key pair using your public key
# resource "aws_key_pair" "terraform_key" {
#   key_name   = "terraform-key"
#   public_key = file(var.public_key_path)
# }

# # EC2 instance
# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.web_sg.id]
#   key_name               = aws_key_pair.terraform_key.key_name

#   tags = {
#     Name = "terraform-web-instance"
#   }
# }

