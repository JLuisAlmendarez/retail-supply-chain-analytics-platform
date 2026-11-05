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

resource "azurerm_storage_account" "lake" {
  name                     = "stsupplychaindevjla"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # ADLS Gen2

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
