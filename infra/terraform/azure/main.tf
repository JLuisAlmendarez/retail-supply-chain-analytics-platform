locals {
  region_short = { eastus2 = "eus2", westus3 = "wus3", westcentralus = "wcus" }[var.location]
  suffix       = "${var.environment}-${local.region_short}"

  tags = {
    project     = "supply-chain"
    environment = var.environment
    managed_by  = "terraform"
    owner       = "jose-luis"
  }

  # Subredes del workspace de Databricks (VNet injection)
  dbw_subnets = {
    host      = "10.10.1.0/24"
    container = "10.10.2.0/24"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-supplychain-${local.suffix}"
  location = var.location
  tags     = local.tags
}

# ---------- Lakehouse ----------

resource "azurerm_storage_account" "lake" {
  name                     = "stsupplychaindevjla"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "zones" {
  for_each = toset(["dvc", "bronze", "silver", "gold"])

  name                  = each.key
  storage_account_id    = azurerm_storage_account.lake.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "data_admin_blob" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.data_admin_object_id
  principal_type       = "User"
}

# ---------- Red para Databricks ----------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-supplychain-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "dbw" {
  for_each = local.dbw_subnets

  name                            = "snet-dbw-${each.key}"
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = [each.value]
  default_outbound_access_enabled = false # la salida la dará el NAT del módulo efímero

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "dbw" {
  name                = "nsg-dbw-supplychain-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "dbw" {
  for_each = azurerm_subnet.dbw

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.dbw.id
}

# ---------- Workspace de Databricks ----------

resource "azurerm_databricks_workspace" "main" {
  name                        = "dbw-supplychain-${local.suffix}"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = "rg-supplychain-${var.environment}-dbw-managed-${local.region_short}"

  public_network_access_enabled         = true
  network_security_group_rules_required = "AllRules"

  custom_parameters {
    no_public_ip        = true # Secure Cluster Connectivity
    virtual_network_id  = azurerm_virtual_network.main.id
    public_subnet_name  = azurerm_subnet.dbw["host"].name
    private_subnet_name = azurerm_subnet.dbw["container"].name

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.dbw["host"].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.dbw["container"].id
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
