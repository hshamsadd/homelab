terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "On-Premises"
      name    = "proxmox-infra-core"
    }
  }
}