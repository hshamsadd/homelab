resource "libvirt_network" "vm_network" {
  name      = var.network_name
  autostart = true

  forward = var.network_mode == "nat" ? {
    mode = "nat"
  } : null

  bridge = var.network_mode == "nat" ? {
    name = var.bridge_name
  } : null


  ips = var.network_mode == "nat" ? [
    {
      family  = "ipv4"
      address = var.network_address
      prefix  = 24

      dhcp = {
        ranges = [
          {
            start = "192.168.150.2"
            end   = "192.168.150.254"
          }
        ]

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
        ip = var.vm_ip

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
  #name = "ubuntu-22.04-base.qcow2"
  name = "ubuntu-24.04-noble-base-v2.qcow2"
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
  #name = "${var.vm_hostname}-disk.qcow2"
  name = "${var.vm_hostname}-disk-v2.qcow2"
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
  #name = "${var.vm_hostname}-cloudinit"
  name = "${var.vm_hostname}-cloudinit-v2"

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    vm_hostname = var.vm_hostname
    vm_user     = var.vm_user
    vm_mac      = var.vm_mac
    public_key  = var.vm_public_key
  })

  meta_data = templatefile("${path.module}/meta-data.yaml", {
    vm_hostname = var.vm_hostname
  })
}

# Upload cloud-init ISO for VM to a volume
resource "libvirt_volume" "vm_cloudinit" {
  #name = "${var.vm_hostname}-cloudinit.iso"
  name = "${var.vm_hostname}-cloudinit-v2.iso"
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
  name        = var.vm_hostname
  memory      = var.vm_memory
  memory_unit = "MiB"
  vcpu        = var.vm_vcpu
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  features = {
    acpi = true

    apic = {
      eoi = "on"
    }
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
            network = libvirt_network.vm_network.name

          }
        }
        mac = {
          address = var.vm_mac
        }

        model = {
          type = "virtio"
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
}

resource "local_file" "ansible_inventory" {
  content = jsonencode({
    all = {
      hosts = {
        "${libvirt_domain.vm.name}" = {
          ansible_host                 = var.vm_ip
          ansible_user                 = var.vm_user
          ansible_ssh_private_key_file = var.ssh_private_key_path

          ansible_ssh_common_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=\"ssh -W %h:%p -q ${var.libvirt_user}@${var.libvirt_host} -i ${var.ssh_private_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\""
        }
      }
    }
  })

  filename        = local.inventory_path
  file_permission = "0644"
}