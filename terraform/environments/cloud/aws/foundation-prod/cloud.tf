terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "Cloud"
      name    = "aws-foundation-prod"
    }
  }
}
