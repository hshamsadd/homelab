path "kv/data/kubernetes/gitops-system/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/gitops-system/*" {
  capabilities = ["read", "list"]
}
