resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment}-foundation"
  location = var.location
}

module "network" {
  source              = "../../../../modules/azure/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = "vnet-${var.environment}-01"
  vnet_cidr           = "10.10.0.0/16"
  subnet_cidr         = "10.10.1.0/24"
}