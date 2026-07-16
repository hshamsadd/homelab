terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}


resource "libvirt_network" "this" {
  count     = var.mode == "nat" || var.mode == "bridge" ? 1 : 0
  name      = var.name
  autostart = true

  # ✅ Correct forward block
  forward = {
    mode = var.mode
  }

  # ✅ Only for NAT
  ips = var.mode == "nat" ? [
    {
      address = var.ips[0].address
      prefix  = var.ips[0].prefix

      dhcp = {
        enabled = true

        hosts = [
          {
            ip   = var.ips[0].dhcp.hosts[0].ip
            mac  = var.ips[0].dhcp.hosts[0].mac
            name = var.ips[0].dhcp.hosts[0].name
          }
        ]
      }
    }
  ] : []

  dns = {
  enable = var.mode == "nat" ? var.dns.enable : "no"
  host   = var.mode == "nat" ? var.dns.host : []
}
}

# resource "libvirt_network" "this" {
#   count     = var.mode == "nat" || var.mode == "bridge" ? 1 : 0
#   name      = var.name
#   autostart = true

#   # Forward configuration for NAT or bridge
#   forward = {
#     mode   = var.mode
#     bridge = var.mode == "bridge" ? var.bridge_name : null
#     nat = var.mode == "nat" ? {
#       addresses = [for ip in var.ips : {
#         start = ip.address
#         end   = ip.address
#       }]
#       ipv6  = "no"
#       ports = []
#     } : null
#   }

#   # IPs (only for NAT)
#   ips = var.mode == "nat" ? var.ips : []

#   # DNS (only for NAT)
#   dns = var.mode == "nat" ? var.dns : {
#     enable = "no"
#     host   = []
#   }
# }