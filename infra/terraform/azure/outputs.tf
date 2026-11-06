output "databricks_workspace_url" {
  description = "URL del workspace de Databricks."
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}"
}
