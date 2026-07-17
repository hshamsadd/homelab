terraform {
  required_version = "~> 1.14.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.30.0"
    }
  }
}

provider "digitalocean" {
  token = var.DO_TOKEN
}

data "digitalocean_ssh_key" "terraform_key" {
  name = "id_terraform.pub" # <-- Use the name you gave in DigitalOcean
}
resource "digitalocean_droplet" "terra-droplet" {
  name     = "ExampleTerraDroplet"
  region   = var.REGION
  size     = var.TYPE
  image    = var.IMAGE
  ssh_keys = [data.digitalocean_ssh_key.terraform_key.id]
  tags     = ["Dev", "ExampleTerraDroplet"]
}