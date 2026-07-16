terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "tls" {}
provider "local" {}


#################################
# SSH Key
#################################
resource "tls_private_key" "vm_key" {
  algorithm = "ED25519"
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.vm_key.private_key_pem
  filename        = "${path.module}/ssh/terraform_vm_key.pem"
  file_permission = "0400"
}

resource "local_file" "ssh_public_key" {
  content  = tls_private_key.vm_key.public_key_openssh
  filename = "${path.module}/ssh/terraform_vm_key.pub"
}

# Download Alpine Linux 3.22 cloud image
resource "libvirt_volume" "alpine_base" {
  name = "alpine-3.22-base.qcow2"
  pool = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      # Alpine Linux 3.22 generic cloud image (BIOS, cloudinit)
      url = "https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/cloud/generic_alpine-3.22.2-x86_64-bios-cloudinit-r0.qcow2"
    }
  }
}

# Create boot disk for VM2 (uses Alpine base image as backing store)
resource "libvirt_volume" "vm2_disk" {
  name = "vm2-disk.qcow2"
  pool = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }

  capacity = 2147483648 # 2GB in bytes

  backing_store = {
    path = libvirt_volume.alpine_base.path
    format = {
      type = "qcow2"
    }
  }
}

# Cloud-init configuration for VM2
resource "libvirt_cloudinit_disk" "vm2_init" {
  name = "vm2-cloudinit"

  user_data = <<-EOF
#cloud-config

hostname: alpine-vm2

# Enable SSH password auth (optional fallback)
ssh_pwauth: true

# Set passwords
chpasswd:
  list: |
    root:password
    alpine:terraform
  expire: false

# Users
users:
  - name: alpine
    groups: wheel
    shell: /bin/ash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys:
      - ${tls_private_key.vm_key.public_key_openssh}

# Packages (Alpine uses openssh-server, NOT openssh)
packages:
  - openssh-server
  - sudo
  - qemu-guest-agent

# Write proper SSH config (DON'T rely only on drop-in)
write_files:
  - path: /etc/ssh/sshd_config
    permissions: '0644'
    content: |
      Port 22
      PermitRootLogin yes
      PasswordAuthentication yes
      PubkeyAuthentication yes
      ChallengeResponseAuthentication no
      UsePAM no
      Subsystem sftp /usr/lib/ssh/sftp-server

# Enable & start services (IMPORTANT for Alpine)
runcmd:
  # 1. Wait for internet to be stable for apk
  - until ping -c 1 google.com; do sleep 2; done

  - apk update
  - for i in 1 2 3; do apk add --no-cache qemu-guest-agent && break || sleep 5; done

  - until [ -e /dev/virtio-ports/org.qemu.guest_agent.0 ]; do sleep 2; done

  # SSH setup
  - rc-update add sshd default
  - service sshd start

  # QEMU guest agent (THIS was your main issue)
  - rc-update add qemu-guest-agent default
  - /etc/init.d/qemu-guest-agent start || service qemu-guest-agent start

  # Debug (optional but useful)
  - echo "==== SSH CONFIG ====" >> /root/debug.log
  - cat /etc/ssh/sshd_config >> /root/debug.log
  - echo "==== AUTHORIZED KEYS ====" >> /root/debug.log
  - cat /home/alpine/.ssh/authorized_keys >> /root/debug.log

final_message: "Alpine VM is ready!"
EOF

  meta_data = <<-EOF
    instance-id: vm2-001
    local-hostname: alpine-vm2
  EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      eth0:
        dhcp4: true
  EOF
}

# Upload cloud-init ISO for VM2 to a volume
resource "libvirt_volume" "vm2_cloudinit" {
  name = "vm2-cloudinit.iso"
  pool = "default"
  # Format will be auto-detected as "iso"

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm2_init.path
    }
  }
}

# Virtual Machine 2
resource "libvirt_domain" "vm2" {
  name   = "alpine-vm2"
  memory = 1048576 # 1 GB in KiB (1024 * 1024)
  vcpu   = 1
  type   = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      # Main disk (Alpine)
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm2_disk.pool
            volume = libvirt_volume.vm2_disk.name
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
            pool   = libvirt_volume.vm2_cloudinit.pool
            volume = libvirt_volume.vm2_cloudinit.name
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
        source = {
          network = {
            network = "default"
          }
        }
        model = {
          type = "virtio"
        }
        # This tells the resource to populate the 'ip' attribute
        wait_for_ip = {
          # Use empty block if it's just a trigger, 
          # or check if your provider needs 'enabled = true'
        }
      }
    ]

    # This is the "Hardware" side of the agent
    channels = [
      {
        type = "unix"
        target = {
          virt_io = {
            name = "org.qemu.guest_agent.0"
            type = "virtio"
          }
        }
      }
    ]

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

  running = true
}

#################################
# IP Discovery
#################################

data "libvirt_domain_interface_addresses" "vm2_ip" {
  domain = libvirt_domain.vm2.name
  source = "lease"
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [alpine_vms]
    ${data.libvirt_domain_interface_addresses.vm2_ip.interfaces[0].addrs[0].addr} ansible_user=alpine ansible_ssh_private_key_file=${local_file.ssh_private_key.filename} ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
  EOT
  filename = "${path.module}/inventory.ini"
}