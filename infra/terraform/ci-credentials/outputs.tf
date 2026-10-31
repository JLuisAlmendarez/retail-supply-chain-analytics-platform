output "client_id" {
  description = "Client ID de la identidad que usa GitHub Actions."
  value       = azurerm_user_assigned_identity.github.client_id
}

output "tenant_id" {
  description = "Tenant de Entra ID."
  value       = azurerm_user_assigned_identity.github.tenant_id
}

output "subscription_id" {
  description = "Suscripción donde opera GitHub Actions."
  value       = data.azurerm_subscription.current.subscription_id
}
