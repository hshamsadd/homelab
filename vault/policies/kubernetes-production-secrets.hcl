path "kv/data/kubernetes/production/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/*" {
  capabilities = ["read", "list"]
}
