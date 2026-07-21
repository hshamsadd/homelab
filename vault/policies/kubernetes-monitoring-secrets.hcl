path "kv/data/kubernetes/monitoring/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/monitoring/*" {
  capabilities = ["read", "list"]
}
