path "kv/data/kubernetes/testing/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/testing/*" {
  capabilities = ["read", "list"]
}
