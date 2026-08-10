/**
 * ==============================================================================
 * ARCHITECTURAL NOTICE: GITOPS MIGRATION
 * ==============================================================================
 *
 * This workspace was previously used to bootstrap internal Kubernetes resources
 * such as Namespaces, ResourceQuotas, and LimitRanges.
 *
 * To eliminate split-brain state management and adhere to strict GitOps 
 * principles, all internal cluster configurations have been migrated to ArgoCD.
 * 
 * Boundary of Responsibility:
 * -> Terraform manages external infrastructure (VMs, Cloud, Networks).
 * -> ArgoCD manages in-cluster declarative state.
 *
 * Please see the `gitops/` directory for all Kubernetes cluster configurations.
 * ==============================================================================
 */