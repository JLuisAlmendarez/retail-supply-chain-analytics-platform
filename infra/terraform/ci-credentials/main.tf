data "azurerm_subscription" "current" {}

locals {
  github_repo = "JLuisAlmendarez/retail-supply-chain-analytics-platform"
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
