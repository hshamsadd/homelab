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







