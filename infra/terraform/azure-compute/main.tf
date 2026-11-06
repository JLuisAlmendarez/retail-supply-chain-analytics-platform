locals {
  tags = {
    project     = "supply-chain"
    environment = var.environment
    managed_by  = "terraform"
    owner       = "jose-luis"
    lifetime    = "ephemeral"
  }
}

# ---------- Lo que ya existe en el módulo persistente "azure" ----------

data "azurerm_resource_group" "main" {
  name = "rg-supplychain-${var.environment}-eus2"
}

data "azurerm_subnet" "dbw" {
  for_each = toset(["host", "container"])

  name                 = "snet-dbw-${each.key}"
  virtual_network_name = "vnet-supplychain-${var.environment}-eus2"
  resource_group_name  = data.azurerm_resource_group.main.name
}

# ---------- NAT Gateway (cobra por hora) ----------

resource "azurerm_public_ip" "nat" {
  name                = "pip-ng-supplychain-${var.environment}-eus2"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "main" {
  name                    = "ng-supplychain-${var.environment}-eus2"
  resource_group_name     = data.azurerm_resource_group.main.name
  location                = data.azurerm_resource_group.main.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "dbw" {
  for_each = data.azurerm_subnet.dbw

  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.main.id

  # Sin la IP asociada el NAT no da salida; que exista antes de enganchar las subredes.
  depends_on = [azurerm_nat_gateway_public_ip_association.main]
}
