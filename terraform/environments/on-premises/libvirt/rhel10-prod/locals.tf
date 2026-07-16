locals {
  # 1. THE KEYS
  # This is the public string we inject into the VM so it knows it's YOU.
  # BREAK THE CYCLE: 
  # Use the variable IP directly for the provisioner/inventory.
  # Since your DHCP is mapped to this IP in the module, it's safe.
  # This is the path WHERE THE KEY ALREADY EXISTS on the GitHub Runner.
  # We don't need to write this file; the 'Setup SSH' step in deploy.yml already did!
  # 2. THE PATHS
  # Where the inventory.json should be saved (relative to the terraform folder)
  inventory_path = "${path.module}/../ansible/inventory.json"
}