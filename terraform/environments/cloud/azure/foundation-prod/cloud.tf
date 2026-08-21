terraform {
  cloud {
    organization = "zshamsadd-devops"
    workspaces {
      project = "Cloud"
      name    = "azure-foundation-prod"
    }
  }
}