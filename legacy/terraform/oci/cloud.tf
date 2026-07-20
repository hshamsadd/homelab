# cloud.tf
terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "On-Premises"
      name    = "oci-local-prod"
    }
  }
}