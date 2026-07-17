terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "Cloud"
      name    = "k3s-node-prod"
    }
  }
}