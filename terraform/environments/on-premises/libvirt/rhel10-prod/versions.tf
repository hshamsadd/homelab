terraform {
  required_version = "~> 1.15.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.8"
    }
    # tls = {
    #   source  = "hashicorp/tls"
    #   version = "~> 4.0.0"
    # }
    # local = {
    #   source  = "hashicorp/local"
    #   version = "~> 2.5.0"
    # }
  }
}
