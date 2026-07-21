path "kv/data/kubernetes/dev/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/dev/*" {
  capabilities = ["read", "list"]
}
