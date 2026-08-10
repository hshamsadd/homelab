# ☁️ Enterprise Hybrid Cloud GitOps Platform

[![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)](terraform/)
[![Configuration Management](https://img.shields.io/badge/Config-Ansible-EE0000?style=flat-square&logo=ansible)](ansible/)
[![Continuous Delivery](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=flat-square&logo=argo)](gitops/)
[![Zero Trust](https://img.shields.io/badge/Security-Vault-000000?style=flat-square&logo=hashicorp)](vault/)

A production-grade, multi-cloud Kubernetes (K3s) platform spanning on-premises (Libvirt/KVM) and public cloud (Oracle Cloud OCI / AWS) infrastructure. This repository contains the complete codebase to provision, configure, and manage a secure, highly available developer platform using strict GitOps methodologies and a Zero-Trust security model.

> **💡 Note to Recruiters & Engineering Managers:** 
> This repository demonstrates enterprise platform engineering patterns, including the **App-of-Apps GitOps pattern**, **OIDC-federated secret injection**, **stateful database disaster recovery**, and **multi-cloud mesh networking**. 

---

## 🏗️ High-Level Architecture

*   **Infrastructure (The Outside):** Immutable cloud and on-prem hardware provisioned via **Terraform**, configured via **Ansible**, and unified securely over a **Tailscale** VPN mesh.
*   **Platform (The Inside):** Declarative cluster state reconciled continuously by **ArgoCD**.
*   **Security:** Centralized secret management via **HashiCorp Vault**, utilizing the Vault Secrets Operator to dynamically inject credentials into workloads without plaintext secrets in Git.
*   **Data & Observability:** Highly available **PostgreSQL (CloudNativePG)** with automated S3 WAL archiving, monitored by a full **Prometheus/Grafana** stack.


![Platform Architecture](docs/architecture/diagram.png)

---

## 📂 Repository Structure

The codebase strictly enforces the boundary of responsibility between Infrastructure Provisioning, Configuration Management, and Continuous Delivery:

```text
.
├── ansible/      # OS-level configuration, K3s bootstrapping, and SSH CA setup
├── apps/         # Custom microservices (Go/Node.js) with Dockerfiles & tests
├── gitops/       # ArgoCD desired state (App-of-Apps, Overlays, Core Infrastructure)
├── terraform/    # Hardware provisioning (OCI Compute, AWS Networking, Libvirt VMs)
└── vault/        # HashiCorp Vault policies, OIDC roles, and GitHub Actions bindings
```

---

## 🚀 Core Engineering Features

### 1. Declarative GitOps (ArgoCD)
The cluster state is entirely managed by ArgoCD utilizing the **App of Apps** pattern. The `gitops/` directory is logically separated into:
*   **`infrastructure/`**: Core platform dependencies (Gateway API, Cert-Manager, Vault Secrets Operator, Prometheus Stack).
*   **`apps/environments/`**: Tenant workloads segmented by lifecycle (`dev`, `production`), utilizing **Kustomize** to patch environment-specific configurations (e.g., scaling up replicas and resource quotas in production).

### 2. Multi-Cloud Mesh Networking
The cluster spans local RHEL10 hypervisors and Oracle Cloud (OCI) compute instances.
*   **Terraform** provisions the distinct environments.
*   **Ansible** installs and configures a **Tailscale** overlay network.
*   K3s utilizes the internal Tailscale IPs (e.g., `100.x.x.x`) to form a secure, encrypted control plane and worker node pool across the public internet.
*   External legacy VMs are bridged into the Kubernetes Gateway via native `Service` and `Endpoints` manifests (`gitops/infrastructure/networking/external-docker-bridge.yaml`).

### 3. Zero-Trust Secrets Management
No plaintext secrets exist in this repository (verified via `gitleaks`).
*   **HashiCorp Vault** is the sole source of truth.
*   GitHub Actions authenticates to Vault via **OIDC (JWT)** to retrieve ephemeral deployment credentials.
*   Within the cluster, the **Vault Secrets Operator** synchronizes dynamic database credentials and API keys into Kubernetes `Secrets` just-in-time, governed by strict Vault policies mapped to Kubernetes ServiceAccounts.

### 4. Stateful Workloads & Disaster Recovery
Databases are treated as first-class citizens using the **CloudNativePG** operator.
*   **High Availability:** Production databases run in a multi-node cluster configuration.
*   **Offsite DR:** Continuous WAL (Write-Ahead Log) archiving is streamed to **MinIO (S3)** object storage.
*   **Verifiable Recovery:** The repository includes explicit GitOps paths (`gitops/recovery/`) containing runbooks and manifests for greenfield cluster restoration and routine disaster recovery drills.

---

## 🛠️ Technology Stack

| Domain | Tools Used |
| :--- | :--- |
| **Infrastructure as Code** | Terraform, Terraform Cloud (Remote State) |
| **Configuration Management** | Ansible, Cloud-Init |
| **Container Orchestration** | Kubernetes (K3s), Docker |
| **GitOps & Delivery** | ArgoCD, Kustomize, GitHub Actions |
| **Networking & Ingress** | Traefik (Gateway API), Tailscale, Cert-Manager |
| **Security & Secrets** | HashiCorp Vault, Vault Secrets Operator, SSH CA |
| **Observability** | Prometheus, Grafana, Alertmanager, Blackbox Exporter |
| **Data & Storage** | CloudNativePG (PostgreSQL), MinIO (S3 Object Storage) |
| **Software Engineering** | Go (Golang), Node.js, Express |

---

## 🧭 Navigating the Code (For Reviewers)

If you are reviewing this repository for a technical assessment, here are the key files that demonstrate architectural decision-making:

1.  **Avoiding Split-Brain State:** See `terraform/environments/hybrid/k3s/main.tf` for an architectural notice explaining why Kubernetes namespaces and quotas were removed from Terraform and delegated entirely to ArgoCD.
2.  **Kustomize Environment Parity:** Compare `gitops/apps/environments/dev/` vs `gitops/apps/environments/production/` to see how base manifests are patched for scale, limits, and storage classes depending on the environment.
3.  **Infrastructure Routing:** See `gitops/infrastructure/networking/` to view Gateway API and RBAC configurations completely isolated from application namespaces.
4.  **Custom Development:** Review `apps/health-ingester/` to see a custom Go microservice featuring SQL migrations, native Prometheus ServiceMonitor integration, and Docker optimization.

---
*Architected and maintained by [Hussein(Zain) Shams Addin]. Feel free to reach out on [LinkedIn](https://www.linkedin.com/in/hshamsadd) to discuss Cloud Native architectures, Platform Engineering, or this platform build.*