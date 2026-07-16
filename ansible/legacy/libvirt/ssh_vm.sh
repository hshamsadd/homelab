#!/bin/bash
# Usage: ./ssh_vm.sh ubuntu-vm2
# Automatically uses Terraform-generated ephemeral key and inventory

VM_NAME=${1:-ubuntu-vm2}
INVENTORY_FILE="$(dirname "$0")/inventory.json"

# Extract host and key from inventory.json
HOST=$(jq -r ".all.hosts[\"$VM_NAME\"].ansible_host" $INVENTORY_FILE)
KEY=$(jq -r ".all.hosts[\"$VM_NAME\"].ansible_ssh_private_key_file" $INVENTORY_FILE)
USER=$(jq -r ".all.hosts[\"$VM_NAME\"].ansible_user" $INVENTORY_FILE)

if [[ -z "$HOST" || -z "$KEY" || -z "$USER" ]]; then
  echo "Error: VM $VM_NAME not found in inventory."
  exit 1
fi

# SSH into VM with ephemeral key
ssh -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$HOST"