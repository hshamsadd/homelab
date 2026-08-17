path "kv/data/kubernetes/dev/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/dev/*" {
  capabilities = ["read", "list"]
}

path "kv/data/kubernetes/production/oci-postgres-dr-credentials" {
  capabilities = ["read"]
}