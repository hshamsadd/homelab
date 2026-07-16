module "vm_network" {
  source      = "./modules/networks"
  name        = var.network_name
  mode        = var.network_mode
  bridge_name = var.bridge_name

  ips = var.network_mode == "nat" ? [
    {
      address = var.network_address
      prefix  = 24

      dhcp = {
        hosts = [
          {
            ip   = var.vm_ip
            mac  = var.vm_mac
            name = var.vm_hostname
          }
        ]
      }
    }
  ] : []

  dns = {
    enable = var.network_mode == "nat" ? "yes" : "no"

    host = var.network_mode == "nat" ? [
      {
        ip        = var.vm_ip
        hostnames = [
          {
            hostname = var.vm_hostname
          }
        ]
      }
    ] : []
  }
}

# Download Ubuntu 22.04 cloud image
resource "libvirt_volume" "ubuntu_base" {
  name = "ubuntu-22.04-base.qcow2"
  pool = var.pool_name
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.ubuntu_image_url
    }
  }
}

# Create boot disk for VM (uses Ubuntu base image as backing store)
resource "libvirt_volume" "vm_disk" {
  name = "${var.vm_hostname}-disk.qcow2"
  pool = var.pool_name
  target = {
    format = {
      type = "qcow2"
    }
  }

  capacity = var.disk_capacity

  backing_store = {
    path = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

# Cloud-init configuration for VM
resource "libvirt_cloudinit_disk" "vm_init" {
  name = "${var.vm_hostname}-cloudinit"

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    vm_hostname = var.vm_hostname
    vm_user     = var.vm_user
    vm_mac      = var.vm_mac
    public_key  = file(var.vm_public_key_path) # Use the public key from the file
  })

  meta_data = templatefile("${path.module}/meta-data.yaml", {
    vm_hostname = var.vm_hostname
  })

  network_config = templatefile("${path.module}/network-config.yaml", {
    vm_mac = var.vm_mac
  })
}

# Upload cloud-init ISO for VM to a volume
resource "libvirt_volume" "vm_cloudinit" {
  name = "${var.vm_hostname}-cloudinit.iso"
  pool = var.pool_name

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm_init.path
      format = {
        type = "raw"
      }
    }
  }
}

# Virtual Machine 
resource "libvirt_domain" "vm" {
  name   = var.vm_hostname
  memory = var.vm_memory
  vcpu   = var.vm_vcpu
  type   = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      # Main disk (Ubuntu)
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm_disk.pool
            volume = libvirt_volume.vm_disk.name
          }
        }
        target = {
          bus = "virtio"
          dev = "vda"
        }
        driver = {
          type = "qcow2"
        }
      },
      # Cloud-init ISO as CD-ROM
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.vm_cloudinit.pool
            volume = libvirt_volume.vm_cloudinit.name
          }
        }
        target = {
          bus = "sata"
          dev = "sda"
        }
      }
    ]

    interfaces = [
      {
        type = "network"
        source = {
          network = {
            network = module.vm_network.name

          }
        }

        mac = {
          address = var.vm_mac
        }

        model = {
          type = "virtio"
        }
        wait_for_ip = {
          timeout = 300
        }

      }
    ]

    channels = [{
      type = "unix"
      target = {
        virt_io = {
          name = "org.qemu.guest_agent.0"
          type = "virtio"
        }
      }
    }]

    graphics = [
      {
        vnc = {
          listen_type = "address"
          auto_port   = true
          listen      = "127.0.0.1"
        }
      }
    ]
    # Optional but useful: Serial console (for virsh console)
    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]

  }
  running = true # Start the VM immediately after creation

  provisioner "remote-exec" {
    inline = ["echo 'VM is ready for SSH'"]

    connection {
      type = "ssh"
      # host        = var.vm_ip
      host = var.vm_ip
      user = var.vm_user
      # This reads the secret file GitHub Actions just created
      private_key = file(var.ssh_private_key_path)
      timeout     = "10m"
    }
  }
}

#################################
# IP Discovery
#################################
# data "libvirt_domain_interface_addresses" "vm_ip" {
#   domain     = libvirt_domain.vm.name
#   source     = "lease" # INSTANT: Look at DHCP leases instead of waiting for Agent
#   depends_on = [libvirt_domain.vm]
# }


resource "local_file" "ansible_inventory" {
  content = jsonencode({
    all = {
      hosts = {
        "${libvirt_domain.vm.name}" = {
          ansible_host = var.vm_ip
          ansible_user = var.vm_user
          ansible_ssh_private_key_file = var.ssh_private_key_path
          ansible_ssh_common_args      = var.ansible_ssh_common_args
        }
      }
    }
  })
  filename        = local.inventory_path
  file_permission = "0644"
}






# terraform {
#   required_providers {
#     libvirt = {
#       source = "dmacvicar/libvirt"
#     }
#     tls = {
#       source  = "hashicorp/tls"
#       version = "~> 4.0.0"
#     }
#     local = {
#       source  = "hashicorp/local"
#       version = "~> 2.5.0"
#     }
#   }
# }

# provider "libvirt" {
#   uri = var.libvirt_uri
# }
# provider "tls" {}
# provider "local" {}

# module "vm_network" {
#   source      = "./modules/networks"
#   name        = var.network_name
#   mode        = var.network_mode
#   bridge_name = var.bridge_name

#   # Only pass NAT-specific settings if mode = "nat"
#   ips = var.network_mode == "nat" ? [
#     {
#       address = var.network_address
#       prefix  = 24
#       dhcp = {
#         hosts = [
#           {
#             ip   = var.vm_ip
#             mac  = var.vm_mac
#             name = var.vm_hostname
#           }
#         ]
#       }
#     }
#   ] : []

#   dns = var.network_mode == "nat" ? {
#     enable = "yes"
#     host = [
#       {
#         ip        = var.vm_ip
#         hostnames = [{ hostname = var.vm_hostname }]
#       }
#     ]
#     } : {
#     enable = "no"
#     host   = []
#   }
# }

# #################################
# # SSH Key
# #################################
# resource "tls_private_key" "vm_key" {
#   algorithm = "ED25519"
# }

# # Save private key for Ansible
# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.vm_key.private_key_openssh
#   filename        = local.ssh_private_key_path
#   file_permission = "0400"
# }

# # Save public key for cloud-init
# resource "local_file" "ssh_public_key" {
#   content         = tls_private_key.vm_key.public_key_openssh
#   filename        = local.ssh_public_key_path
#   file_permission = "0644"
# }


# # Download Ubuntu 22.04 cloud image
# resource "libvirt_volume" "ubuntu_base" {
#   name = "ubuntu-22.04-base.qcow2"
#   pool = var.pool_name
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   create = {
#     content = {
#       # Ubuntu 22.04 generic cloud image (BIOS, cloudinit)
#       url = var.ubuntu_image_url
#     }
#   }
# }

# # Create boot disk for VM (uses Ubuntu base image as backing store)
# resource "libvirt_volume" "vm_disk" {
#   name = "${var.vm_hostname}-disk.qcow2"
#   pool = var.pool_name
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   capacity = var.disk_capacity

#   backing_store = {
#     path = libvirt_volume.ubuntu_base.path
#     format = {
#       type = "qcow2"
#     }
#   }
# }

# # Cloud-init configuration for VM
# resource "libvirt_cloudinit_disk" "vm_init" {
#   name = "${var.vm_hostname}-cloudinit"

#   user_data = templatefile("${path.module}/cloud-init.yaml", {
#     vm_hostname = var.vm_hostname
#     vm_user     = var.vm_user
#     vm_mac      = var.vm_mac
#     public_key  = tls_private_key.vm_key.public_key_openssh
#   })

#   meta_data = templatefile("${path.module}/meta-data.yaml", {
#     vm_hostname = var.vm_hostname
#   })

#   network_config = templatefile("${path.module}/network-config.yaml", {
#     vm_mac = var.vm_mac
#   })
# }

# # Upload cloud-init ISO for VM to a volume
# resource "libvirt_volume" "vm_cloudinit" {
#   name = "${var.vm_hostname}-cloudinit.iso"
#   pool = var.pool_name
#   create = {
#     content = {
#       url = libvirt_cloudinit_disk.vm_init.path
#     }
#   }
# }

# # Virtual Machine 
# resource "libvirt_domain" "vm" {
#   name   = var.vm_hostname
#   memory = var.vm_memory
#   vcpu   = var.vm_vcpu
#   type   = "kvm"

#   os = {
#     type         = "hvm"
#     type_arch    = "x86_64"
#     type_machine = "q35"
#   }

#   devices = {
#     disks = [
#       # Main disk (Ubuntu)
#       {
#         source = {
#           volume = {
#             pool   = libvirt_volume.vm_disk.pool
#             volume = libvirt_volume.vm_disk.name
#           }
#         }
#         target = {
#           bus = "virtio"
#           dev = "vda"
#         }
#         driver = {
#           type = "qcow2"
#         }
#       },
#       # Cloud-init ISO as CD-ROM
#       {
#         device = "cdrom"
#         source = {
#           volume = {
#             pool   = libvirt_volume.vm_cloudinit.pool
#             volume = libvirt_volume.vm_cloudinit.name
#           }
#         }
#         target = {
#           bus = "sata"
#           dev = "sda"
#         }
#       }
#     ]

#     interfaces = [
#       {
#         type = "network"
#         source = {
#           network = {
#             network = module.vm_network.name

#           }
#         }

#         mac = {
#           address = var.vm_mac
#         }

#         model = {
#           type = "virtio"
#         }
#         wait_for_ip = {
#           timeout = 300
#         }

#       }
#     ]

#     channels = [{
#       type = "unix"
#       target = {
#         virt_io = {
#           name = "org.qemu.guest_agent.0"
#           type = "virtio"
#         }
#       }
#     }]

#     graphics = [
#       {
#         vnc = {
#           listen_type = "address"
#           auto_port   = true
#           listen      = "127.0.0.1"
#         }
#       }
#     ]
#     # Optional but useful: Serial console (for virsh console)
#     consoles = [
#       {
#         type        = "pty"
#         target_type = "serial"
#         target_port = "0"
#       }
#     ]

#   }
#   running = true # Start the VM immediately after creation
# }

# #################################
# # IP Discovery
# #################################
# data "libvirt_domain_interface_addresses" "vm_ip" {
#   domain     = libvirt_domain.vm.name
#   source     = "lease" # INSTANT: Look at DHCP leases instead of waiting for Agent
#   depends_on = [libvirt_domain.vm]
# }


# resource "local_file" "ansible_inventory" {
#   filename = local.inventory_path
#   content = jsonencode({
#     all = {
#       hosts = {
#         (libvirt_domain.vm.name) = {
#           ansible_host                 = local.vm_ip
#           ansible_user                 = var.vm_user
#           ansible_ssh_private_key_file = local.ssh_private_key_path
#           ansible_ssh_common_args      = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#         }
#       }
#   } })
#   file_permission = "0644"
# }


# terraform {
#   required_providers {
#     libvirt = {
#       source = "dmacvicar/libvirt"
#     }
#     tls = {
#       source  = "hashicorp/tls"
#       version = "~> 4.0.0"
#     }
#     local = {
#       source  = "hashicorp/local"
#       version = "~> 2.5.0"
#     }
#   }
# }

# provider "libvirt" {
#   uri = "qemu:///system"
# }

# provider "tls" {}
# provider "local" {}

# ###############################
# # Libvirt NAT Network
# ###############################
# resource "libvirt_network" "nat" {
#   name      = "terraform-nat"
#   autostart = true
#   forward = {
#     mode = "nat"
#   }

#   ips = [
#     {
#       address = "192.168.150.1"
#       prefix  = 24
#       dhcp = {
#         hosts = [
#           {
#             ip   = "192.168.150.5"
#             mac  = "52:54:00:5d:c7:9e"
#             name = "ubuntu-vm2"
#           }
#         ]
#       }
#     }
#   ]

#   dns = {
#     enable = "yes"
#     host = [
#       {
#         ip        = "192.168.150.5"
#         hostnames = [{ hostname = "ubuntu-vm2" }]
#       }
#     ]
#   }
# }

# ###############################
# # SSH Key Generation
# ###############################
# resource "tls_private_key" "vm_key" {
#   algorithm = "ED25519"
# }

# # Save private key for Ansible
# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.vm_key.private_key_openssh
#   filename        = "${path.module}/ansible/terraform_vm_key.pem"
#   file_permission = "0400"
# }

# # Save private key for Ansible
# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.vm_key.private_key_openssh
#   filename        = "${path.module}/ansible/terraform_vm_key.pem"
#   file_permission = "0400"
# }

# ###############################
# # Ubuntu Base Image
# ###############################
# resource "libvirt_volume" "ubuntu_base" {
#   name = "ubuntu-22.04-base.qcow2"
#   pool = "default"
#   target = {
#     format = { type = "qcow2" }
#   }
#   create = {
#     content = { url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" }
#   }
# }

# ###############################
# # VM Disk
# ###############################
# resource "libvirt_volume" "vm2_disk" {
#   name     = "vm2-disk.qcow2"
#   pool     = "default"
#   target   = { format = { type = "qcow2" } }
#   capacity = 10737418240 # 10GB
#   backing_store = {
#     path   = libvirt_volume.ubuntu_base.path
#     format = { type = "qcow2" }
#   }
# }

# ###############################
# # Create VM with cloud-init
# ###############################
# resource "libvirt_cloudinit_disk" "vm2_init" {
#   name = "vm2-cloudinit"
#   user_data  = templatefile("${path.module}/cloud-init.yaml", {
#   public_key = tls_private_key.vm_key.public_key_openssh})

#   meta_data = <<-EOF
#   instance-id: vm2-001
#   local-hostname: ubuntu-vm2
#   EOF

#   network_config = <<-EOF
#   version: 2
#   ethernets:
#   eth0:
#     match:
#       macaddress: "52:54:00:5d:c7:9e"
#     set-name: eth0
#     dhcp4: true
#   EOF
# }

# resource "libvirt_volume" "vm2_cloudinit" {
#   name = "vm2-cloudinit.iso"
#   pool = "default"
#   create = { content = {
#     url = libvirt_cloudinit_disk.vm2_init.path
#   } }
# }

# ###############################
# # VM2 Domain
# ###############################
# resource "libvirt_domain" "vm2" {
#   name   = "ubuntu-vm2"
#   memory = 2097152 # 2GB
#   vcpu   = 2
#   type   = "kvm"

#   os = {
#     type         = "hvm"
#     type_arch    = "x86_64"
#     type_machine = "q35"
#   }

#   devices = {
#     disks = [
#       { source = { volume = { pool = libvirt_volume.vm2_disk.pool, volume = libvirt_volume.vm2_disk.name } },
#       target = { bus = "virtio", dev = "vda" }, driver = { type = "qcow2" } },
#       { device = "cdrom",
#         source = { volume = { pool = libvirt_volume.vm2_cloudinit.pool, volume = libvirt_volume.vm2_cloudinit.name } },
#       target = { bus = "sata", dev = "sda" } }
#     ]

#     interfaces = [
#       {
#         type        = "network"
#         source      = { network = { network = libvirt_network.nat.name } }
#         mac         = { address = "52:54:00:5d:c7:9e" }
#         model       = { type = "virtio" }
#         wait_for_ip = { timeout = 300 }
#       }
#     ]

#     channels = [
#       {
#         type   = "unix"
#         target = { virt_io = { name = "org.qemu.guest_agent.0", type = "virtio" } }
#       }
#     ]

#     graphics = [{ vnc = { listen_type = "address", auto_port = true, listen = "127.0.0.1" } }]

#     consoles = [{ type = "pty", target_type = "serial", target_port = "0" }]
#   }

#   running = true
# }

# ###############################
# # IP Discovery
# ###############################
# data "libvirt_domain_interface_addresses" "vm2_ip" {
#   domain     = libvirt_domain.vm2.name
#   source     = "lease"
#   depends_on = [libvirt_domain.vm2]
# }

# ###############################
# # Ansible Inventory
# ###############################
# locals {
#   ansible_inventory = {
#     all = {
#       hosts = {
#         (libvirt_domain.vm2.name) = {
#           ansible_host = try(
#             flatten([
#               for i in data.libvirt_domain_interface_addresses.vm2_ip.interfaces :
#               [for a in i.addrs : a.addr]
#             ])[0],
#             "0.0.0.0"
#           )
#           ansible_user                 = "ubuntu"
#           ansible_ssh_private_key_file = "${path.module}/ansible/terraform_vm_key.pem"
#           ansible_ssh_common_args      = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#         }
#       }
#     }
#   }
# }

# # Save inventory.json directly into ansible/ folder for Ansible to consume
# resource "local_file" "ansible_inventory" {
#   filename = "${path.module}/ansible/inventory.json"
#   content  = jsonencode(local.ansible_inventory.all)
#   file_permission = "0644"
# }

# ###############################
# # Outputs
# ###############################
# output "ssh_command" {
#   value = "ssh -i ${path.module}/ssh/terraform_vm_key.pem ubuntu@${data.libvirt_domain_interface_addresses.vm2_ip.interfaces[0].addrs[0].addr}"
# }

# output "vm_ip" {
#   value = try(
#     flatten([
#       for i in data.libvirt_domain_interface_addresses.vm2_ip.interfaces :
#       [for a in i.addrs : a.addr]
#     ])[0],
#     "IP_NOT_READY"
#   )
# }






# terraform {
#   required_providers {
#     libvirt = {
#       source = "dmacvicar/libvirt"
#     }
#     tls = {
#       source  = "hashicorp/tls"
#       version = "~> 4.0.0"
#     }
#     local = {
#       source  = "hashicorp/local"
#       version = "~> 2.5.0"
#     }
#   }
# }

# provider "libvirt" {
#   uri = "qemu:///system"
# }

# provider "tls" {}
# provider "local" {}

# resource "libvirt_network" "nat" {
#   name      = "terraform-nat"
#   autostart = true
#   # Mode must be inside forward
#   forward = {
#     mode = "nat"
#   }

#   # Change from 122 to 150 (or any number not in use)
#   ips = [
#     {
#       address = "192.168.150.1"
#       prefix  = 24
#       dhcp = {
#         hosts = [
#           {
#             ip   = "192.168.150.5"
#             mac  = "52:54:00:5d:c7:9e"
#             name = "ubuntu-vm2"
#           }
#         ]
#       }
#     }
#   ]

#   dns = {
#     enable = "yes"
#     host = [
#       {
#         ip        = "192.168.150.5"
#         hostnames = [{ hostname = "ubuntu-vm2" }]
#       }
#     ]
#   }
# }



# #################################
# # SSH Key
# #################################
# resource "tls_private_key" "vm_key" {
#   algorithm = "ED25519"
# }

# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.vm_key.private_key_pem
#   filename        = "${path.module}/ssh/terraform_vm_key.pem"
#   file_permission = "0400"
# }

# resource "local_file" "ssh_public_key" {
#   content  = tls_private_key.vm_key.public_key_openssh
#   filename = "${path.module}/ssh/terraform_vm_key.pub"
# }

# # Download Ubuntu 22.04 cloud image
# resource "libvirt_volume" "ubuntu_base" {
#   name = "ubuntu-22.04-base.qcow2"
#   pool = "default"
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   create = {
#     content = {
#       # Ubuntu 22.04 generic cloud image (BIOS, cloudinit)
#       url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
#     }
#   }
# }

# # Create boot disk for VM2 (uses Ubuntu base image as backing store)
# resource "libvirt_volume" "vm2_disk" {
#   name = "vm2-disk.qcow2"
#   pool = "default"
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   capacity = 10737418240 # 10GB in bytes

#   backing_store = {
#     path = libvirt_volume.ubuntu_base.path
#     format = {
#       type = "qcow2"
#     }
#   }
# }

# # Cloud-init configuration for VM2
# resource "libvirt_cloudinit_disk" "vm2_init" {
#   name = "vm2-cloudinit"

#   user_data = <<-EOF
# #cloud-config
# hostname: ubuntu-vm2

# # Enable SSH password auth (optional fallback)
# ssh_pwauth: true

# # Set passwords
# chpasswd:
#   list: |
#     root:password
#     ubuntu:terraform
#   expire: false

# # Users
# users:
#   - name: ubuntu
#     groups: sudo
#     groups: wheel
#     shell: /bin/bash
#     sudo: ALL=(ALL) NOPASSWD:ALL
#     lock_passwd: false
#     ssh_authorized_keys:
#       - ${tls_private_key.vm_key.public_key_openssh}

# # We skip 'packages' here because it fails without internet 
# # and slows down the boot/terraform wait time.
# EOF

#   meta_data = <<-EOF
#     instance-id: vm2-001
#     local-hostname: ubuntu-vm2
#   EOF

#   network_config = <<-EOF
#     version: 2
#     ethernets:
#       eth0:
#         match:
#           macaddress: "52:54:00:5d:c7:9e"
#         set-name: eth0
#         dhcp4: true
#   EOF
# }

# # Upload cloud-init ISO for VM2 to a volume
# resource "libvirt_volume" "vm2_cloudinit" {
#   name = "vm2-cloudinit.iso"
#   pool = "default"
#   # Format will be auto-detected as "iso"

#   create = {
#     content = {
#       url = libvirt_cloudinit_disk.vm2_init.path
#     }
#   }
# }

# # Virtual Machine 2
# resource "libvirt_domain" "vm2" {
#   name   = "ubuntu-vm2"
#   memory = 2097152 # 2GB in KiB (1024 * 1024)
#   vcpu   = 2
#   type   = "kvm"

#   os = {
#     type         = "hvm"
#     type_arch    = "x86_64"
#     type_machine = "q35"
#   }

#   devices = {
#     disks = [
#       # Main disk (Ubuntu)
#       {
#         source = {
#           volume = {
#             pool   = libvirt_volume.vm2_disk.pool
#             volume = libvirt_volume.vm2_disk.name
#           }
#         }
#         target = {
#           bus = "virtio"
#           dev = "vda"
#         }
#         driver = {
#           type = "qcow2"
#         }
#       },
#       # Cloud-init ISO as CD-ROM
#       {
#         device = "cdrom"
#         source = {
#           volume = {
#             pool   = libvirt_volume.vm2_cloudinit.pool
#             volume = libvirt_volume.vm2_cloudinit.name
#           }
#         }
#         target = {
#           bus = "sata"
#           dev = "sda"
#         }
#       }
#     ]

#     interfaces = [
#       {
#         type = "network"
#         # The error says 'source' -> 'network' needs an object
#         source = {
#           network = {
#             network = libvirt_network.nat.name # This links it to "terraform-nat"

#           }
#         }

#         mac = {
#           address = "52:54:00:5d:c7:9e"
#         }

#         model = {
#           type = "virtio"
#         }
#         # This tells the resource to populate the 'ip' attribute
# wait_for_ip = {
#   timeout = 300
# }

#       }
#     ]

#     channels = [{
#       type = "unix"
#       target = {
#         virt_io = {
#           name = "org.qemu.guest_agent.0"
#           type = "virtio"
#         }
#       }
#       # target = {
#       #   virt_io = {
#       #     name = "org.qemu.guest_agent.0"
#       #     type = "virtio"
#       #   }
#       # }
#     }]

#     graphics = [
#       {
#         vnc = {
#           listen_type = "address"
#           auto_port   = true
#           listen      = "127.0.0.1"
#         }
#       }
#     ]

#     # Optional but useful: Serial console (for virsh console)
#     consoles = [
#       {
#         type        = "pty"
#         target_type = "serial"
#         target_port = "0"
#       }
#     ]

#   }

#   running = true
# }

# #################################
# # IP Discovery
# #################################
# data "libvirt_domain_interface_addresses" "vm2_ip" {
#   domain     = libvirt_domain.vm2.name
#   source     = "lease" # INSTANT: Look at DHCP leases instead of waiting for Agent
#   depends_on = [libvirt_domain.vm2]
# }

# output "vm_ip" {
#   value = try(
#     flatten([
#       for i in data.libvirt_domain_interface_addresses.vm2_ip.interfaces :
#       [for a in i.addrs : a.addr]
#     ])[0],
#     "IP_NOT_READY"
#   )
# }

# output "ssh_command" {
#   value = "ssh -i ./ssh/terraform_vm_key.pem ubuntu@${try(
#     flatten([
#       for i in data.libvirt_domain_interface_addresses.vm2_ip.interfaces :
#       [for a in i.addrs : a.addr]
#     ])[0],
#     "0.0.0.0"
#   )}"
# }

# locals {
#   ansible_inventory = {
#     all = {
#       hosts = {
#         (libvirt_domain.vm2.name) = {
#           ansible_host                 = try(
#             flatten([
#               for i in data.libvirt_domain_interface_addresses.vm2_ip.interfaces :
#               [for a in i.addrs : a.addr]
#             ])[0],
#             "0.0.0.0"
#           )
#           ansible_user                 = "ubuntu"
#           ansible_ssh_private_key_file = "./ssh/terraform_vm_key.pem"

#           # Automatically handle host key changes
#           ansible_ssh_common_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#         }
#       }
#     }
#   }
# }

# resource "local_file" "ansible_inventory" {
#   filename = "${path.module}/inventory.json"
#   content  = jsonencode(local.ansible_inventory)
# }





















# terraform {
#   required_providers {
#     libvirt = {
#       source = "dmacvicar/libvirt"
#     }
#   }
# }

# provider "libvirt" {
#   uri = "qemu:///system"
# }

# # Download Ubuntu 22.04 (Jammy) cloud image
# resource "libvirt_volume" "ubuntu_base" {
#   name   = "ubuntu-jammy-base.qcow2"
#   pool   = "default"
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   create = {
#     content = {
#       url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
#     }
#   }
# }

# # Create boot disk for VM1 (uses base image as backing store)
# resource "libvirt_volume" "vm1_disk" {
#   name   = "vm1-disk.qcow2"
#   pool   = "default"
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   capacity = 10737418240 # 10GB recommended for Ubuntu

#   backing_store = {
#     path   = libvirt_volume.ubuntu_base.path
#     format = {
#       type = "qcow2"
#     }
#   }
# }

# # Cloud-init configuration for VM1
# resource "libvirt_cloudinit_disk" "vm1_init" {
#   name = "vm1-cloudinit"

#   user_data = <<-EOF
#     #cloud-config
#     chpasswd:
#       list: |
#         root:password
#       expire: false

#     ssh_pwauth: true

#     packages:
#       - openssh-server

#     timezone: UTC

#     final_message: "VM1 is ready! SSH: ssh root@<IP>"
#   EOF

#   meta_data = <<-EOF
#     instance-id: vm1-001
#     local-hostname: ubuntu-vm1
#   EOF

#   network_config = <<-EOF
#     version: 2
#     ethernets:
#       eth0:
#         dhcp4: true
#   EOF
# }

# # Upload cloud-init ISO for VM1 to a volume
# resource "libvirt_volume" "vm1_cloudinit" {
#   name = "vm1-cloudinit.iso"
#   pool = "default"

#   create = {
#     content = {
#       url = libvirt_cloudinit_disk.vm1_init.path
#     }
#   }
# }

# # Virtual Machine 1
# resource "libvirt_domain" "vm1" {
#   name   = "ubuntu-vm1"
#   memory = 2097152 # 2 GB in KiB (1024 * 1024)
#   vcpu   = 2
#   type   = "kvm"

#   os = {
#     type         = "hvm"
#     type_arch    = "x86_64"
#     type_machine = "q35"
#   }

#   devices = {
#     disks = [
#       {
#         source = {
#           volume = {
#             pool   = libvirt_volume.vm1_disk.pool
#             volume = libvirt_volume.vm1_disk.name
#           }
#         }
#         target = {
#           bus = "virtio"
#           dev = "vda"
#         }
#         driver = {
#           type = "qcow2"
#         }
#       },
#       {
#         device = "cdrom"
#         source = {
#           volume = {
#             pool   = libvirt_volume.vm1_cloudinit.pool
#             volume = libvirt_volume.vm1_cloudinit.name
#           }
#         }
#         target = {
#           bus = "sata"
#           dev = "sda"
#         }
#       }
#     ]

#     interfaces = [
#       {
#         type  = "network"
#         model = { type = "virtio" }
#         source = {
#           network = {
#             network = "default"
#           }
#         }
#       }
#     ]

#     graphics = [
#       {
#         vnc = {
#           auto_port = true
#           listen    = "127.0.0.1"
#         }
#       }
#     ]
#   }

#   running = true
# }

# output "vm1_id" {
#   value       = libvirt_domain.vm1.id
#   description = "Domain ID for VM1"
# }

# output "instructions" {
#   value = <<-EOF

#     Virtual machine has been created!

#     To find IP address assigned by DHCP:
#       sudo virsh domifaddr ubuntu-vm1

#     To connect via SSH:
#       ssh root@<IP-ADDRESS>
#       Password: password

#     To view VM console:
#       sudo virsh console ubuntu-vm1
#   EOF
# }





# terraform {
#   required_providers {
#     libvirt = {
#       source = "dmacvicar/libvirt"
#     }
#     tls = {
#       source  = "hashicorp/tls"
#       version = "~> 4.0.0"
#     }
#     local = {
#       source  = "hashicorp/local"
#       version = "~> 2.5.0"
#     }
#   }
# }

# provider "libvirt" {
#   uri = "qemu:///system"
# }

# provider "tls" {}
# provider "local" {}


# #################################
# # SSH Key
# #################################
# resource "tls_private_key" "vm_key" {
#   algorithm = "ED25519"
# }

# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.vm_key.private_key_pem
#   filename        = "${path.module}/ssh/terraform_vm_key.pem"
#   file_permission = "0400"
# }

# resource "local_file" "ssh_public_key" {
#   content  = tls_private_key.vm_key.public_key_openssh
#   filename = "${path.module}/ssh/terraform_vm_key.pub"
# }

# # Download Ubuntu 24.04 cloud image
# resource "libvirt_volume" "ubuntu_base" {
#   name = "ubuntu-jammy-base.qcow2"
#   pool = "default"
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   create = {
#     content = {
#       # Ubuntu 24.04 LTS (Noble Numbat) generic cloud image
#       url = "https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
#     }
#   }
# }

# # Create boot disk for Ubuntu VM (uses Ubuntu base image as backing store)
# resource "libvirt_volume" "ubuntu_disk" {
#   name = "ubuntu-disk.qcow2"
#   pool = "default"
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }

#   capacity = 10737418240 # 10GB recommended for Ubuntu

#   backing_store = {
#     path = libvirt_volume.ubuntu_base.path
#     format = {
#       type = "qcow2"
#     }
#   }
# }

# # Cloud-init configuration for Ubuntu VM
# resource "libvirt_cloudinit_disk" "ubuntu_init" {
#   name = "ubuntu-cloudinit"

#   user_data = <<-EOF
# #cloud-config

# hostname: ubuntu-vm

# # Enable SSH password auth (optional fallback)
# ssh_pwauth: true

# # Set passwords
# chpasswd:
#   list: |
#     root:password
#     ubuntu:terraform
#   expire: false

# # Users
# users:
#   - name: ubuntu
#     groups: sudo
#     shell: /bin/bash
#     sudo: ALL=(ALL) NOPASSWD:ALL
#     lock_passwd: false
#     ssh_authorized_keys:
#       - ${tls_private_key.vm_key.public_key_openssh}

# # Packages (Ubuntu uses standard package names)
# packages:
#   - openssh-server
#   - sudo
#   - qemu-guest-agent
#   - python3

# # Write proper SSH config
# write_files:
#   - path: /etc/ssh/sshd_config
#     permissions: '0644'
#     content: |
#       Port 22
#       PermitRootLogin yes
#       PasswordAuthentication yes
#       PubkeyAuthentication yes
#       ChallengeResponseAuthentication no
#       UsePAM yes
#       Subsystem sftp /usr/lib/ssh/sftp-server

# # Enable & start services
# runcmd:
#   - systemctl enable qemu-guest-agent
#   - systemctl start qemu-guest-agent
#   - systemctl enable ssh
#   - systemctl start ssh
#   # Debug
#   - echo "==== SSH CONFIG ====" >> /root/debug.log
#   - cat /etc/ssh/sshd_config >> /root/debug.log
#   - echo "==== AUTHORIZED KEYS ====" >> /root/debug.log
#   - cat /home/ubuntu/.ssh/authorized_keys >> /root/debug.log

# final_message: "Ubuntu VM is ready!"
# EOF

#   meta_data = <<-EOF
#     instance-id: ubuntu-001
#     local-hostname: ubuntu-vm
#   EOF

#   network_config = <<-EOF
#     version: 2
#     ethernets:
#       eth0:
#         dhcp4: true
#   EOF
# }

# # Upload cloud-init ISO for Ubuntu VM to a volume
# resource "libvirt_volume" "ubuntu_cloudinit" {
#   name = "ubuntu-cloudinit.iso"
#   pool = "default"

#   create = {
#     content = {
#       url = libvirt_cloudinit_disk.ubuntu_init.path
#     }
#   }
# }

# # Virtual Machine definition for Ubuntu VM
# resource "libvirt_domain" "ubuntu" {
#   name   = "ubuntu-vm"
#   memory = 2097152 # 2 GB recommended for Ubuntu
#   vcpu   = 2
#   type   = "kvm"

#   os = {
#     type         = "hvm"
#     type_arch    = "x86_64"
#     type_machine = "q35"
#   }

#   devices = {
#     disks = [
#       # Main disk (Ubuntu)
#       {
#         source = {
#           volume = {
#             pool   = libvirt_volume.ubuntu_disk.pool
#             volume = libvirt_volume.ubuntu_disk.name
#           }
#         }
#         target = {
#           bus = "virtio"
#           dev = "vda"
#         }
#         driver = {
#           type = "qcow2"
#         }
#       },
#       # Cloud-init ISO as CD-ROM
#       {
#         device = "cdrom"
#         source = {
#           volume = {
#             pool   = libvirt_volume.ubuntu_cloudinit.pool
#             volume = libvirt_volume.ubuntu_cloudinit.name
#           }
#         }
#         target = {
#           bus = "sata"
#           dev = "sda"
#         }
#       }
#     ]

#     interfaces = [
#       {
#         source = {
#           network = {
#             network = "default"
#           }
#         }
#         model = {
#           type = "virtio"
#         }
#         wait_for_ip = { enabled = true }
#       }
#     ]

#     channels = [
#       {
#         type = "unix"
#         target = {
#           virt_io = {
#             name = "org.qemu.guest_agent.0"
#             type = "virtio"
#           }
#         }
#       }
#     ]

#     graphics = [
#       {
#         vnc = {
#           listen_type = "address"
#           auto_port   = true
#           listen      = "127.0.0.1"
#         }
#       }
#     ]

#     consoles = [
#       {
#         type        = "pty"
#         target_type = "serial"
#         target_port = "0"
#       }
#     ]

#   }

#   running = true

# }

# #################################
# # IP Discovery
# #################################

# data "libvirt_domain_interface_addresses" "ubuntu_ip" {
#   domain = libvirt_domain.ubuntu.name
#   source = "lease"
# }

# output "vm_ip" {
#   value = try(data.libvirt_domain_interface_addresses.ubuntu_ip.interfaces[0].addrs[0].addr, "Waiting for DHCP...")
# }

# output "ssh_command" {
#   value = try(
#     "ssh -i ./ssh/terraform_vm_key.pem ubuntu@${data.libvirt_domain_interface_addresses.ubuntu_ip.interfaces[0].addrs[0].addr}",
#     "IP not assigned yet"
#   )
# }

# output "ubuntu_id" {
#   value       = libvirt_domain.ubuntu.id
#   description = "Domain ID for Ubuntu VM"
# }

# resource "local_file" "ansible_inventory" {
#   content  = <<-EOT
#     [ubuntu_vms]
#     ${data.libvirt_domain_interface_addresses.ubuntu_ip.interfaces[0].addrs[0].addr} ansible_user=ubuntu ansible_ssh_private_key_file=${local_file.ssh_private_key.filename} ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
#   EOT
#   filename = "${path.module}/inventory.ini"
# }