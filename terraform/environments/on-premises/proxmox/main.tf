# 1. Download the Ubuntu LXC Template
resource "proxmox_download_file" "ubuntu_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "proxmox-01"
  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

# 2. Provision the LXC Container
resource "proxmox_virtual_environment_container" "github_runner" {
  description  = "GitHub Actions Runner - Managed by Terraform"
  node_name    = "proxmox-01"
  vm_id        = 200
  unprivileged = true

  initialization {
    hostname = "gh-runner-01"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      password = "SuperSecretPassword123!"
    }
  }

  network_interface {
    name = "veth0"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  operating_system {
    template_file_id = proxmox_download_file.ubuntu_lxc_img.id
    type             = "ubuntu"
  }

  features {
    nesting = true
  }
}