data "azurerm_subscription" "current" {}

locals {

  delegable_roles = {
    "Storage Blob Data Contributor"  = "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
    "Storage Blob Data Reader"       = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
    "AcrPull"                        = "7f951dda-4ed3-4680-a7ca-43fe172d538d"
    "AcrPush"                        = "8311e382-0749-4cb8-b61a-304f252e45ec"
    "Azure Event Hubs Data Sender"   = "2b629674-e913-4c01-ae53-ef4638d8f975"
    "Azure Event Hubs Data Receiver" = "a638d3c7-ab3a-418d-83e6-5f17a39d4fde"
    "Key Vault Secrets User"         = "4633458b-17de-408a-b874-0445c86b69e6"
  }
  delegable_role_ids = join(", ", values(local.delegable_roles))

  github_repo = "JLuisAlmendarez@82072947/retail-supply-chain-analytics-platform@1440189210"
  github_oidc = "https://token.actions.githubusercontent.com"

  tags = {
    project    = "supply-chain"
    component  = "ci-credentials"
    managed_by = "terraform"
    owner      = "jose-luis"
  }
}

resource "azurerm_resource_group" "ci" {
  name     = "rg-supplychain-ci-eus2"
  location = var.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-supplychain-github"
  location            = azurerm_resource_group.ci.location
  resource_group_name = azurerm_resource_group.ci.name
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_federated_identity_credential" "main_branch" {
  name                      = "github-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.github.id
  issuer                    = local.github_oidc
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "repo:${local.github_repo}:ref:refs/heads/main"
}

resource "azurerm_federated_identity_credential" "pull_request" {
  name                      = "github-pull-request"
  user_assigned_identity_id = azurerm_user_assigned_identity.github.id
  issuer                    = local.github_oidc
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "repo:${local.github_repo}:pull_request"

  # Azure no permite crear dos credenciales en la misma identidad al mismo tiempo
  depends_on = [azurerm_federated_identity_credential.main_branch]
}

resource "azurerm_role_assignment" "github_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_rbac_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"

  condition_version = "2.0"
  condition         = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
      )
      OR
      (
        @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.delegable_role_ids}}
      )
    )
    AND
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
      )
      OR
      (
        @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.delegable_role_ids}}
      )
    )
  EOT
}
