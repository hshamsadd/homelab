terraform {
  cloud {
    organization = "zshamsadd-devops"
    workspaces {
      name = "k3s-core-cluster"
    }
  }
}

# terraform {

#   cloud {
#     organization = "zshamsadd-devops"
#     workspaces {
#       name = "k3s-core-cluster"
#     }
#   }
  
#   required_providers {
#     aws = { source = "hashicorp/aws" }
#   }

# }

# provider "aws" {} # Leaving this blank forces it to use the OIDC variables!