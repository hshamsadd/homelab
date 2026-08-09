# 🚀 Enterprise Hybrid Cloud GitOps Platform

[![GitOps: ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-cb4b16?style=flat-square&logo=argo)](https://argoproj.github.io/cd/)
[![Infrastructure: Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)](#)
[![Configuration: Ansible](https://img.shields.io/badge/Config-Ansible-EE0000?style=flat-square&logo=ansible)](#)
[![Security: Vault](https://img.shields.io/badge/Security-HashiCorp_Vault-000000?style=flat-square&logo=vault)](#)
[![Data: CloudNativePG](https://img.shields.io/badge/Data-CloudNativePG-336791?style=flat-square&logo=postgresql)](#)

A production-grade, multi-node Kubernetes (K3s) platform spanning on-premises Libvirt VMs and Oracle Cloud Infrastructure (OCI). This repository demonstrates enterprise platform engineering patterns including **stateful workload resilience**, **zero-trust secrets management**, and **fully declarative GitOps delivery**.

Unlike standard homelabs, this project bridges the gap between infrastructure and software engineering, featuring a custom Go-based microservice alongside advanced infrastructure-as-code automation.

---

## 🏗️ Architecture Overview

The cluster operates across physical borders using a **Tailscale Mesh Network**, unifying local RHEL 10 virtual machines and cloud compute instances into a single, cohesive Kubernetes cluster.

```text
                        [ Tailscale Overlay Mesh Network ]
                                       │
     ┌─────────────────────────────────┼─────────────────────────────────┐
     │                                 │                                 │
┌────┴────────────────────┐   ┌────────┴────────────────┐   ┌────────────┴────────────┐
│  Server (Control Plane) │   │  Worker-1 (Compute VM)  │   │  Worker-2 (Storage Node)│
│  Libvirt / RHEL 10      │   │  Oracle Cloud (OCI)     │   │  Libvirt / RHEL 10      │
└─────────────────────────┘   └─────────────────────────┘   └─────────────────────────┘



# 🚀 Hybrid Cloud GitOps Platform

[![GitOps: ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-cb4b16?style=flat-square&logo=argo)](https://argoproj.github.io/cd/)
[![Secret Management: SealedSecrets](https://img.shields.io/badge/Security-SealedSecrets-blue?style=flat-square)](#)
[![Database: CloudNativePG](https://img.shields.io/badge/Data-CloudNativePG-336791?style=flat-square&logo=postgresql)](#)
[![Storage: MinIO](https://img.shields.io/badge/Storage-MinIO-C7202C?style=flat-square&logo=minio)](#)

An enterprise-grade, GitOps-driven Kubernetes platform focusing on **stateful workload resilience**, **automated disaster recovery**, and **environment parity**.

Unlike standard homelabs that stop at deploying stateless web servers, this repository demonstrates how to manage complex stateful data lifecycles, cross-environment database bootstrapping, and secure secret management in a fully declarative way.

-------

## 🏗️ Architecture & Core Philosophy

This cluster is managed 100% declaratively using the **App-of-Apps** pattern in ArgoCD. All infrastructure, applications, and configurations are defined in Git. 

*   **Infrastructure as Code (IaC):** Terraform and Ansible for foundational cluster provisioning.
*   **GitOps Delivery:** ArgoCD synchronized with Kustomize overlays.
*   **Zero-Trust Secrets:** Bitnami Sealed Secrets with asymmetric encryption, ensuring no plaintext secrets are ever pushed to Git.
*   **Base/Overlay Strategy:** DRY (Don't Repeat Yourself) manifests using Kustomize `base` for core application logic and `environments` (Production/Staging) for environment-specific patching.

---

## 🔥 Key Engineering Highlights

### 1. Automated Disaster Recovery & Staging Data Hydration
*The hardest part of Kubernetes isn't running pods; it's managing data.* 
This cluster utilizes **CloudNativePG (CNPG)** with Continuous Archiving (WAL) to an S3-compatible **MinIO** object store. 
*   **Production:** Automatically pushes Point-In-Time-Recovery (PITR) backups and WAL logs to MinIO.
*   **Staging Bootstrapping:** The staging environment is configured to bootstrap itself securely from the production MinIO backup using a scoped, read-only `SealedSecret`. This mimics enterprise workflows where developers need sanitized production data in staging environments without manual database dumps.

### 2. ArgoCD App-of-Apps Pattern
Located in `/gitops/bootstrap`, a single `root-application.yaml` dynamically discovers and deploys child applications (`app-infrastructure.yaml`, `app-production.yaml`, `app-staging.yaml`). Bootstrapping the entire cluster from scratch requires applying exactly one file.

### 3. Kustomize Overlay Architecture
Applications (MinIO, PgAdmin, Redis, Wallabag) are templated in `/gitops/apps/base`. Environment specific configurations (Ingress hostnames, PVC sizes, resource limits, and secrets) are injected via `/gitops/apps/environments/[prod|staging]/patches`, ensuring perfect environment parity with zero code duplication.

---

## 📂 Repository Navigation

```text
.
├── ansible/                  # Server configuration and prerequisites
├── terraform/                # Cluster initialization and cloud infrastructure
├── gitops/                   # The heart of the GitOps deployment
│   ├── bootstrap/            # ArgoCD App-of-Apps root manifests
│   ├── infrastructure/       # Cluster-wide controllers (cert-manager, sealed-secrets, networking)
│   └── apps/
│       ├── base/             # Base Kustomize configurations for all workloads
│       └── environments/
│           ├── production/   # Prod-specific overlays, patches, and SealedSecrets
│           └── staging/      # Staging overlays (includes Prod-DB cross-restore logic)
└── docs/                     # Architectural Decision Records (ADRs)