sudo virsh vol-delete --pool default ubuntu-22.04-base.qcow2

sudo virsh vol-delete --pool default ubuntu-vm-cloudinit.iso

sudo virsh vol-delete --pool default ubuntu-vm-disk.qcow2

sudo virsh -c qemu:///system list --all

sudo virsh -c qemu:///system net-list --all

sudo virsh -c qemu:///system net-destroy ubuntu-vm-1 && sudo virsh -c qemu:///system net-undefine ubuntu-vm-1

sudo virsh -c qemu:///system undefine ubuntu-vm --remove-all-storage

virsh -c qemu:///system net-uuid terraform-nat-1

sudo virsh net-lis

sudo virsh -c qemu:///system net-list





zshamsadd@localhost:~/development/devops/ops/terraform-libvirt/terraform$ terraform apply

Acquiring state lock. This may take a few moments....


2 Bio and content info
write a short bio
mention your role

-------------
do
linkedin profile link
professional email
portofolio website
pin some projects
readme for each project with screenshots and how to use and install

-------------
majd jadal haq




kubectl port-forward svc/argocd-server -n argocd 8080:443
vault login -method=userpass username=zshamsadd
ssh-keygen -R worker-3



cat > vault/policies/kubernetes-testing-secrets.hcl <<'EOF'
path "kv/data/kubernetes/testing/*" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/testing/*" {
  capabilities = ["read", "list"]
}
EOF


vault write \
  auth/kubernetes/role/kubernetes-gitops-system \
  bound_service_account_names=vault-secrets \
  bound_service_account_namespaces=gitops-system \
  token_policies=kubernetes-gitops-system-secrets \
  audience=vault \
  ttl=1h








I will give you a very very important and long task. You must go through all these links. Read all the chats literally all of them from the begening till the end and create documentation of what we have achieved for this project. And in your documentation you must include by section what was achieved until we finished today and how they all relate to each other. and how one can use each feature etc. it must have a main doc or read me and of course readme for each big feature or section. This task cannot be done hastly but it must be production grade documented and illustrated and you must not leave or ignore the slightest feature or thing we have done. You can in the end suggest feature improvement or features. But again it has to be 100000000% accurate and documented and show what we did/achieved and how it can be used. I will list the links of our chats for the past 4 or 5 weeks as well as the current project repo structure. If you ever need to read any document in the just tell me to give you access if you want so that you can access the repo https://github.com/hshamsadd/homelab  which is now public. Again take as long as you can and want but never just finish fast.

https://chatgpt.com/share/6a639dd5-1be8-83eb-9085-44cfa5e1a297

https://chatgpt.com/share/6a639ec3-6aec-83eb-b765-08f461e26c02

https://chatgpt.com/share/6a628e37-3680-83ed-8dd6-0522990e67f9

https://chatgpt.com/share/6a639ef8-8ddc-83ed-95c8-a4ca657f10b4  (This one is our current chat)




zshamsadd@RHEL10 …/homelab 󰘬 main ✓ ➜ : tree
.
├── ansible
│   ├── ansible.cfg
│   ├── inventories
│   │   ├── dev
│   │   ├── production
│   │   │   ├── group_vars
│   │   │   │   └── all
│   │   │   │       └── vault.yml
│   │   │   ├── hosts.yml
│   │   │   └── host_vars
│   │   ├── staging
│   │   └── testing
│   │       └── hosts.yml
│   ├── legacy
│   │   ├── aws
│   │   │   ├── ansible.cfg
│   │   │   ├── bootstrap.yml
│   │   │   ├── deploy.yml
│   │   │   └── inventory.ini
│   │   └── libvirt
│   │       ├── ansible.cfg
│   │       ├── inventory.json
│   │       ├── playbooks
│   │       │   └── site.yml
│   │       ├── roles
│   │       ├── ssh_vm.sh
│   │       ├── terraform_vm_key.pem
│   │       └── terraform_vm_key.pub
│   ├── notes
│   │   └── ownership.md
│   ├── playbooks
│   │   ├── app-ci-multiarch.yaml
│   │   ├── bootstrap.yml
│   │   ├── configure-k3s-worker.yml
│   │   ├── configure-libvirt-host.yml
│   │   ├── configure-libvirt-worker.yml
│   │   ├── install-k3s-server.yml
│   │   ├── join-k3s-agent.yml
│   │   ├── tailscale-k3s.yaml
│   │   ├── terraform-ci.yaml
│   │   ├── update-hosts.yml
│   │   └── update-vm.yaml
│   ├── roles
│   │   ├── common
│   │   │   └── tasks
│   │   │       └── main.yml
│   │   ├── docker
│   │   ├── k3s_agent
│   │   │   └── tasks
│   │   │       └── main.yml
│   │   ├── k3s_server
│   │   ├── ssh_ca
│   │   └── tailscale
│   │       └── tasks
│   │           └── main.yml
│   └── ssh_known_hosts
│       └── rhel10
├── docs
│   ├── ADR-001-multi-arch-tailscale-mesh.md
│   ├── architecture
│   └── runbooks
│       └── postgresql-ha-offsite-dr.md
├── gitops
│   ├── apps
│   │   ├── base
│   │   │   ├── argocd-ui
│   │   │   │   ├── argocd-cm.yaml
│   │   │   │   ├── argocd-rbac-cm.yaml
│   │   │   │   ├── configmap.yaml
│   │   │   │   ├── ingress.yaml
│   │   │   │   ├── kustomization.yaml
│   │   │   │   └── transport.yaml
│   │   │   ├── cloudnative-pg
│   │   │   │   ├── cluster.yaml
│   │   │   │   └── kustomization.yaml
│   │   │   ├── minio
│   │   │   │   ├── ingress.yaml
│   │   │   │   ├── kustomization.yaml
│   │   │   │   ├── minio-pvc.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   └── statefulset.yaml
│   │   │   ├── pgadmin
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── ingress.yaml
│   │   │   │   └── kustomization.yaml
│   │   │   ├── redis
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── kustomization.yaml
│   │   │   │   └── service.yaml
│   │   │   └── wallabag
│   │   │       ├── deployment.yaml
│   │   │       ├── ingress.yaml
│   │   │       ├── kustomization.yaml
│   │   │       ├── service.yaml
│   │   │       └── wallabag.json
│   │   └── environments
│   │       ├── production
│   │       │   ├── kustomization.yaml
│   │       │   ├── namespace.yaml
│   │       │   ├── patches
│   │       │   │   ├── cloudnative-pg
│   │       │   │   │   ├── barman-objectstore.yaml
│   │       │   │   │   ├── central-postgres-ha.yaml
│   │       │   │   │   ├── oci-postgres-dr-mirror-cronjob.yaml
│   │       │   │   │   └── scheduled-backup-ha.yaml
│   │       │   │   ├── minio
│   │       │   │   │   ├── minio-bucket-job.yaml
│   │       │   │   │   ├── minio-local-pv.yaml
│   │       │   │   │   └── minio-vault-secret.yaml
│   │       │   │   ├── pgadmin
│   │       │   │   │   └── pgadmin-vault-secret.yaml
│   │       │   │   └── wallabag
│   │       │   │       └── wallabag-vault-secret.yaml
│   │       │   └── secrets
│   │       │       ├── kustomization.yaml
│   │       │       ├── vault-auth.yaml
│   │       │       ├── vault-serviceaccount.yaml
│   │       │       ├── vault-static-secret-cnpg-minio-production.yaml
│   │       │       ├── vault-static-secret-oci-postgres-dr.yaml
│   │       │       ├── vault-static-secret-pgadmin.yaml
│   │       │       └── vault-static-secret-wallabag.yaml
│   │       └── staging
│   │           ├── kustomization.yaml
│   │           ├── namespace.yaml
│   │           ├── patches
│   │           │   ├── cloudnative-pg
│   │           │   │   ├── barman-objectstore.yaml
│   │           │   │   ├── central-postgres.yaml
│   │           │   │   ├── disable-wal-archiver.yaml
│   │           │   │   └── production-backups-store.yaml
│   │           │   ├── minio
│   │           │   │   ├── minio-ingress-patch.yaml
│   │           │   │   ├── minio-pvc-patch.yaml
│   │           │   │   └── minio-staging-patch.yaml
│   │           │   ├── pgadmin
│   │           │   │   ├── pgadmin-ingress-patch.yaml
│   │           │   │   └── pgadmin-vault-secret.yaml
│   │           │   ├── redis
│   │           │   │   └── redis-resources.yaml
│   │           │   └── wallabag
│   │           │       ├── wallabag-env.yaml
│   │           │       ├── wallabag-ingress.yaml
│   │           │       └── wallabag-vault-secret.yaml
│   │           └── secrets
│   │               ├── kustomization.yaml
│   │               ├── vault-auth.yaml
│   │               ├── vault-serviceaccount.yaml
│   │               ├── vault-static-secret-cnpg-minio-production-fallback.yaml
│   │               ├── vault-static-secret-cnpg-minio-staging.yaml
│   │               ├── vault-static-secret-pgadmin.yaml
│   │               └── vault-static-secret-wallabag.yaml
│   ├── bootstrap
│   │   ├── app-infrastructure.yaml
│   │   ├── app-monitoring.yaml
│   │   ├── app-production.yaml
│   │   ├── app-staging.yaml
│   │   ├── argocd-repository
│   │   │   ├── kustomization.yaml
│   │   │   ├── vault-auth.yaml
│   │   │   ├── vault-serviceaccount.yaml
│   │   │   └── vault-static-secret.yaml
│   │   ├── kustomization.yaml
│   │   ├── root-application.yaml
│   │   └── vault-secrets-operator.yaml
│   ├── infrastructure
│   │   ├── cert-manager
│   │   │   └── local-issuer.yaml
│   │   ├── cloudnative-pg-operator
│   │   ├── kustomization.yaml
│   │   ├── monitoring-stack
│   │   │   ├── blackbox-exporter.yaml
│   │   │   ├── grafana-ingress.yaml
│   │   │   ├── kube-prometheus-stack-values.yaml
│   │   │   ├── kustomization.yaml
│   │   │   ├── vault-auth.yaml
│   │   │   ├── vault-serviceaccount.yaml
│   │   │   ├── vault-static-secret-alertmanager-email.yaml
│   │   │   └── vault-static-secret-grafana-admin.yaml
│   │   ├── networking
│   │   │   ├── external-docker-bridge.yaml
│   │   │   └── vault-external.yaml
│   │   └── vault-secrets-operator
│   │       ├── kustomization.yaml
│   │       └── token-reviewer.yaml
│   └── notes
│       └── ownership.md
├── hack
├── legacy
│   ├── terraform
│   │   ├── aws-old
│   │   │   ├── 1
│   │   │   │   ├── main.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── variables.tf
│   │   │   ├── 2
│   │   │   │   ├── ec2-key-final
│   │   │   │   ├── ec2-key-final.pub
│   │   │   │   ├── main.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── variables.tf
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── ssh
│   │   │   │   └── ec2-key-final.pem
│   │   │   ├── terraform.tf
│   │   │   ├── terraform.tfstate
│   │   │   ├── terraform.tfstate.backup
│   │   │   ├── terraform-user_accessKeys (1).csv
│   │   │   └── variables.tf
│   │   ├── libvirt
│   │   │   ├── 1
│   │   │   │   ├── cloud-init
│   │   │   │   │   ├── cloud-init.yaml
│   │   │   │   │   ├── meta-data.yaml
│   │   │   │   │   └── network-config.yaml
│   │   │   │   ├── cloud.tf
│   │   │   │   ├── local.auto.tfvars
│   │   │   │   ├── locals.tf
│   │   │   │   ├── main.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   ├── provider.tf
│   │   │   │   ├── README.md
│   │   │   │   ├── terraform.tfvars
│   │   │   │   └── variables.tf
│   │   │   └── 2
│   │   │       ├── backend.tf
│   │   │       ├── cloud-init.yaml
│   │   │       ├── locals.tf
│   │   │       ├── main.tf
│   │   │       ├── meta-data.yaml
│   │   │       ├── modules
│   │   │       │   └── networks
│   │   │       │       ├── main.tf
│   │   │       │       ├── outputs.tf
│   │   │       │       └── variables.tf
│   │   │       ├── network-config.yaml
│   │   │       ├── outputs.tf
│   │   │       ├── providers.tf
│   │   │       └── variables.tf
│   │   └── oci
│   │       ├── backend.tf
│   │       ├── cloud.tf
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── provider.tf
│   │       ├── terraform.tfvars
│   │       ├── variables.tf
│   │       └── versions.tf
│   ├── vms
│   │   └── alpine-vm
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── ssh
│   └── workflows
│       ├── ci.yml
│       ├── cleanup.yml
│       ├── deploy.yaml
│       └── deploy.yml
├── notes
│   ├── commands.md
│   └── docker-commads.md
├── README.md
├── scripts
│   ├── cd
│   ├── ci
│   ├── maintenance
│   ├── selinux
│   │   └── install-virtproxyd-gha.sh
│   ├── tailscale
│   │   └── create-node-auth-key.sh
│   ├── terraform
│   └── vault
│       ├── sign-ci-ssh-key.sh
│       └── sign-ssh-key.sh
├── selinux
│   └── virtproxyd_gha.te
├── services
│   └── portfolio-apps
│       └── app-demo
│           ├── client
│           │   └── Dockerfile
│           ├── docker-commads.md
│           ├── docker-compose.yml
│           └── server
│               ├── Dockerfile
│               ├── eslint.config.js
│               ├── package.json
│               ├── package-lock.json
│               ├── server.js
│               ├── src
│               │   ├── app.js
│               │   ├── config
│               │   │   ├── db.js
│               │   │   └── env.js
│               │   ├── controllers
│               │   │   └── book.controller.js
│               │   ├── helpers
│               │   │   └── example.helper.js
│               │   ├── middlewares
│               │   │   └── error.middleware.js
│               │   ├── models
│               │   │   └── book.model.js
│               │   ├── routes
│               │   │   └── book.routes.js
│               │   ├── server.js
│               │   ├── services
│               │   │   └── book.service.js
│               │   └── utils
│               │       ├── apiError.js
│               │       ├── asyncHandler.js
│               │       ├── examples.util.js
│               │       └── response.js
│               └── tests
│                   └── book.test.js
├── terraform
│   ├── environments
│   │   ├── cloud
│   │   │   ├── aws
│   │   │   │   └── foundation-prod
│   │   │   │       ├── cloud.tf
│   │   │   │       ├── main.tf
│   │   │   │       ├── outputs.tf
│   │   │   │       ├── providers.tf
│   │   │   │       ├── variables.tf
│   │   │   │       └── versions.tf
│   │   │   ├── azure
│   │   │   └── oci
│   │   │       ├── compute-prod
│   │   │       │   ├── backend.tf
│   │   │       │   ├── cloud.tf
│   │   │       │   ├── main.tf
│   │   │       │   ├── outputs.tf
│   │   │       │   ├── provider.tf
│   │   │       │   ├── terraform.tfvars
│   │   │       │   ├── variables.tf
│   │   │       │   └── versions.tf
│   │   │       └── object-storage-prod
│   │   │           ├── cloud.tf
│   │   │           ├── identity.tf
│   │   │           ├── main.tf
│   │   │           ├── outputs.tf
│   │   │           ├── provider.tf
│   │   │           ├── terraform.tfvars
│   │   │           ├── variables.tf
│   │   │           └── versions.tf
│   │   ├── hybrid
│   │   │   └── k3s
│   │   │       ├── cloud.tf
│   │   │       ├── main.tf
│   │   │       ├── providers.tf
│   │   │       ├── terraform.tfstate
│   │   │       ├── terraform.tfstate.backup
│   │   │       ├── terraform.tfvars
│   │   │       ├── variables.tf
│   │   │       └── versions.tf
│   │   └── on-premises
│   │       └── libvirt
│   │           └── rhel10-prod
│   │               ├── cloud-init
│   │               │   ├── cloud-init.yaml
│   │               │   ├── meta-data.yaml
│   │               │   ├── network-config.yaml
│   │               │   └── vault-ssh-user-ca.pub
│   │               ├── cloud.tf
│   │               ├── main.tf
│   │               ├── outputs.tf
│   │               ├── providers.tf
│   │               ├── README.md
│   │               ├── variables.tf
│   │               └── versions.tf
│   └── modules
│       ├── aws
│       │   └── network
│       │       ├── main.tf
│       │       ├── outputs.tf
│       │       └── variables.tf
│       ├── libvirt
│       │   └── network
│       │       ├── main.tf
│       │       ├── outputs.tf
│       │       └── variables.tf
│       └── oci
│           └── network
│               ├── main.tf
│               ├── outputs.tf
│               └── variables.tf
└── vault
    ├── auth
    ├── policies
    │   ├── github-aws-foundation-prod.hcl
    │   ├── github-libvirt-prod.hcl
    │   ├── github-oci-compute-prod.hcl
    │   ├── kubernetes-dev-secrets.hcl
    │   ├── kubernetes-gitops-system-secrets.hcl
    │   ├── kubernetes-monitoring-secrets.hcl
    │   ├── kubernetes-production-secrets.hcl
    │   ├── kubernetes-staging-secrets.hcl
    │   └── kubernetes-testing-secrets.hcl
    ├── roles
    │   ├── github-aws-foundation-remote.json
    │   ├── github-libvirt-local.json
    │   ├── github-libvirt-remote.json
    │   ├── github-oci-compute-remote.json
    │   └── github-oci-remote-compute-prod-cleanup.json
    └── ssh
        └── vault-ssh-user-ca.pub

135 directories, 272 files

zshamsadd@RHEL10 …/homelab 󰘬 main ✓ ➜ : ls -la
total 72
drwxr-xr-x. 16 zshamsadd zshamsadd 4096 Jul 22 01:40 .
drwxrwxr-x. 34 zshamsadd zshamsadd 4096 Jul 22 18:55 ..
drwxr-xr-x.  8 zshamsadd zshamsadd 4096 Jul 17 21:24 ansible
drwxr-xr-x.  2 zshamsadd zshamsadd 4096 Jun 30 09:25 .devcontainer
drwxr-xr-x.  4 zshamsadd zshamsadd 4096 Jul 15 01:57 docs
drwxr-xr-x.  9 zshamsadd zshamsadd 4096 Jul 24 19:07 .git
drwxr-xr-x.  3 zshamsadd zshamsadd 4096 Jun 30 12:25 .github
-rw-r--r--.  1 zshamsadd zshamsadd 2670 Jul 22 02:09 .gitignore
drwxr-xr-x.  6 zshamsadd zshamsadd 4096 Jul 17 21:24 gitops
drwxr-xr-x.  2 zshamsadd zshamsadd 4096 Jul  5 04:28 hack
drwxr-xr-x.  5 zshamsadd zshamsadd 4096 Jul 17 21:24 legacy
drwxr-xr-x.  2 zshamsadd zshamsadd 4096 Jul 17 21:24 notes
-rw-r--r--.  1 zshamsadd zshamsadd 3886 Jul 17 21:24 README.md
drwxr-xr-x.  9 zshamsadd zshamsadd 4096 Jul 17 21:24 scripts
drwxr-xr-x.  2 zshamsadd zshamsadd 4096 Jul 17 21:24 selinux
drwxr-xr-x.  3 zshamsadd zshamsadd 4096 Jul 15 01:55 services
drwxr-xr-x.  4 zshamsadd zshamsadd 4096 Jul 17 21:24 terraform
drwxr-xr-x.  6 zshamsadd zshamsadd 4096 Jul 18 21:21 vault

zshamsadd@RHEL10 …/homelab 󰘬 main ✓ ➜ :


(
echo "===== GIT ====="
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"
git status --short

echo "===== ARGO CD ====="
kubectl -n argocd get applications.argoproj.io \
  root-bootstrap stack-production stack-dev \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision'

echo "===== DATABASES ====="
kubectl -n production get cluster central-postgres-ha
kubectl -n dev get cluster central-postgres-dev

echo "===== DEV PLACEMENT ====="
kubectl -n dev get pods,pvc -o wide
kubectl get pv minio-dev-local-pv \
  -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,RECLAIM:.spec.persistentVolumeReclaimPolicy,NODE:.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0],PATH:.spec.local.path'

echo "===== RETIREMENT ====="
test -z "$(kubectl get namespace staging --ignore-not-found -o name)"
test -z "$(kubectl -n argocd get application stack-staging --ignore-not-found -o name)"

STAGING_ARCHIVE="$(cat /tmp/staging-retirement-archive.current)"
test -s "$STAGING_ARCHIVE"
gzip -t "$STAGING_ARCHIVE"
echo "Archive: $STAGING_ARCHIVE"

printf 'Production Wallabag HTTP: '
curl -sS -o /dev/null -w '%{http_code}\n' http://wallabag.home/

printf 'Dev Wallabag HTTP: '
curl -sS -o /dev/null -w '%{http_code}\n' http://wallabag-dev.home/

echo "PASS: stack-dev migration and staging retirement completed"  
)

# Get status of different components
kubectl get {k8s-component} or kubectl get {k8s-component} -n {namespace}
kubectl get nodes -n {namespace}
kubectl get pods -n {namespace}
kubectl get pod {pod-name} -n {namespace} -o wide
kubectl get services -n {namespace}
kubectl get deployment -n {namespace}
kubectl get deployment {deployment-name} -n {namespace} -o yaml
kubectl get replicaset -n {namespace}
kubectl get ingress -n {namespace}
kubectl get gateway -n {namespace}
kubectl get apps -n {namespace}
note: You can use -A instead of -n {namespace} to see results from all namespaces

# CRUD
kubectl create {k8s-component} {name} {options}
kubectl create deployment my-nginx-depl --image=nginx

kubectl edit {k8s-component} {name} {options}
kubectl delete {k8s-component} {name} {options}
kubectl apply -f {config-file.yaml}
kubectl delete -f {config-file.yaml}

# Debugg
kubectl logs {pod-name} -n {namespace}
kubectl logs -f {pod-name} -n {namespace} # For live logs
kubectl describe pod {pod-name} -n {namespace}

kubectl exec -it {pod-name} -n {namespace} -- bash

# Show Live Resource Usage (CPU/Memory)
kubectl top pod -n {namespace}
kubectl top node

# Advanced Debugging & TroubleshootingView Real-Time Logs (Stream/Follow)
kubectl logs -f {pod-name} -n {namespace}

# View Logs of a Previous (Crashed) Container Instance
kubectl logs {pod-name} -p -n {namespace}

# Stream Multi-Pod Logs by Label
kubectl logs -l app={label-name} -f -n {namespace}

# Forward a Local Port to a Pod/Service (Bypass Ingress)
kubectl port-forward {pod-or-service-name} {local-port}:{cluster-port} -n {namespace}

# Copy Files To or From a Container
kubectl cp {local-file-path} {namespace}/{pod-name}:{container-path}
kubectl cp {namespace}/{pod-name}:{container-path} {local-file-path}

# Enhanced Cluster & Component InspectionList All Resources Across ALL Namespaces
kubectl get all -A

# List All Namespaces
kubectl get ns

# Show Labels Assigned to Resources
kubectl get pods --show-labels -n {namespace}

# List Ingress / Network Routes
kubectl get ingress -n {namespace}

# List Configurations & Secretsbashkubectl get configmap -n {namespace}
kubectl get secret -n {namespace}

# Deletion & Cleanup UpdatesDelete a Resource Using the YAML File Directly
kubectl delete -f {config-file.yaml}

# Force Delete a Pod Immediately (Skip Grace Period)
kubectl delete pod {pod-name} -n {namespace} --force --grace-period=0

# Context & Configuration ManagementView Current Kubeconfig Context (Where are you connected?)kubectl config current-context

# Switch to a Different Cluster Context
kubectl config use-context {context-name}

# Permanently Set a Default Namespace for Current Context
kubectl config set-context --current --namespace={namespace}

# Quick Syntax Generator (Dry-Run)Generate YAML Configuration Without Creating the Resource
kubectl create deployment {name} --image={image} --dry-run=client -o yaml > deploy.yaml