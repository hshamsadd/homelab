resource "aws_instance" "my_vm" {
  ami           = "ami-0705384c0b33c194c" # Ubuntu 22.04 LTS (Stockholm)
  instance_type = "t3.micro"              # Free-tier eligible size in this region

  tags = {
    Name = "MyFirstTerraformVM"
  }
}
