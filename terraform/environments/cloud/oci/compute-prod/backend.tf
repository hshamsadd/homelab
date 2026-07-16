# backend.tf

terraform {
  backend "http" {
    address       = "https://objectstorage.eu-amsterdam-1.oraclecloud.com/p/6zSPnQNb3Mhf3y8u9uldo58yNi3fxkHApsR0z0HRiY_cMxApFke7ngA5UjtQm1Z3/n/axc00uy8zwuh/b/worker-02-terraform-state/o/terraform.tfstate"
    update_method = "PUT"
  }
}