
#################################
# Ubuntu 24.04 LTS AMI
#################################

data "aws_ami" "ubuntu_noble" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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
    Name      = "${var.vm_name}-vpc"
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.vm_name}-public-subnet"
    ManagedBy = "Terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.vm_name}-igw"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.vm_name}-public-rt"
    ManagedBy = "Terraform"
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
  name        = "${var.vm_name}-sg"
  description = "AWS K3s worker managed through SSM and Tailscale"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name      = "${var.vm_name}-sg"
    ManagedBy = "Terraform"
  }
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#################################
# Systems Manager
#################################

resource "aws_iam_role" "ssm" {
  name = "${var.vm_name}-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role = aws_iam_role.ssm.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.vm_name}-ssm"
  role = aws_iam_role.ssm.name
}

#################################
# EC2 K3s Worker
#################################

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_noble.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ssm.name

  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name        = var.vm_name
    K3sNodeName = var.k3s_node_name
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_route.internet_access,
    aws_route_table_association.public_assoc,
    aws_iam_role_policy_attachment.ssm_core
  ]
}

#---------------------------------------------------------------------------------#
# resource "aws_key_pair" "terraform_key" {
#   key_name   = "terraform-key"
#   public_key = file("~/Downloads/terraform-key-openssh.pem.pub")
# }

# #################################
# # AMI lookup
# #################################

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

# #################################
# # Networking
# #################################

# resource "aws_vpc" "main" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "aws-vpc"
#   }
# }

# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.subnet_cidr
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "aws-public-subnet"
#   }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "aws-igw"
#   }
# }

# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "aws-public-rt"
#   }
# }

# resource "aws_route" "internet_access" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# #################################
# # Security Group
# #################################

# resource "aws_security_group" "web_sg" {
#   name        = "aws-web-sg"
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
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# #################################
# # EC2
# #################################

# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.web_sg.id]

#   key_name = aws_key_pair.terraform_key.key_name

#   tags = {
#     Name = "aws-web-instance"
#   }
# }



#============================================================================================================#

#resource "aws_instance" "my_vm" {
#  ami           = "ami-0705384c0b33c194c" # Ubuntu 22.04 LTS (Stockholm)
#  instance_type = "t3.micro"              # Free-tier eligible size in this region
#
#  tags = {
#    Name = "MyFirstTerraformVM"
#  }
# }
