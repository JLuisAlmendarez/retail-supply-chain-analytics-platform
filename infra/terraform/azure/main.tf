locals {
  tags = {
    project     = "supply-chain"
    environment = var.environment
    managed_by  = "terraform"
    owner       = "jose-luis"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-supplychain-${var.environment}-eus2"
  location = var.location
  tags     = local.tags
}
