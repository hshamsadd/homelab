Argo CD ownership
Argo CD should own:

Kubernetes namespaces
cert-manager
CloudNativePG operator
Vault Secrets Operator
monitoring stack
networking controllers
MinIO
Wallabag
pgAdmin
Redis
CloudNativePG clusters
Ingress resources
Services
Deployments
StatefulSets
application configuration references


Terraform should stop owning Kubernetes namespaces. Your current:

terraform/modules/k8s-namespace

should eventually be retired after confirming no Terraform state still references it.

The gitops/.../secrets directories may remain, but their future contents should be Vault Secrets Operator references—not plaintext Secrets or long-term SealedSecrets.


linkding
docmost
hoarder
linkwarden
mariadb
elastic search
mongodb
