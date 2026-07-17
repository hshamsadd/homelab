terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "On-Premises"
      name    = "libvirt-rhel10-prod"
    }
  }
}