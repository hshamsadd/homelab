path "kv/data/kubernetes/staging/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/staging/*" {
  capabilities = ["read", "list"]
}
