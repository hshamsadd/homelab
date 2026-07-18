path "kv/data/platforms/hcp-terraform/ci" {
  capabilities = ["read"]
}

path "kv/data/platforms/tailscale/provisioner" {
  capabilities = ["read"]
}

path "ssh-client-signer/sign/homelab-ci" {
  capabilities = ["update"]
}