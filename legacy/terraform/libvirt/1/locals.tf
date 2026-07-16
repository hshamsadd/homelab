locals {
  # BREAK THE CYCLE: 
  # Use the variable IP directly for the provisioner/inventory.
  # Since your DHCP is mapped to this IP in the module, it's safe.
  vm_ip = var.vm_ip
  # This is the path WHERE THE KEY ALREADY EXISTS on the GitHub Runner.
  # We don't need to write this file; the 'Setup SSH' step in deploy.yml already did!
  ansible_key_path = var.ssh_private_key_path
  # 2. THE PATHS
  # Where the inventory.json should be saved (relative to the terraform folder)
  inventory_path = "${path.module}/../ansible/inventory.json"
}