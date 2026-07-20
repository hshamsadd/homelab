# cloud.tf
terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "Cloud"
      name    = "oci-remote-compute-prod"
    }
  }
}