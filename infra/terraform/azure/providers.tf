provider "azurerm" {

  features {}
  resource_providers_to_register = [
    "Microsoft.EventGrid",               # Databricks (cómputo clásico)
    "Microsoft.EventHub",                # Fase 1: pedidos en vivo
    "Microsoft.ContainerService",        # Fase 1: AKS
    "Microsoft.DataFactory",             # Fase 1: copias en lote
    "Microsoft.DBforPostgreSQL",         # Fase 1: estado de pedidos
    "Microsoft.MachineLearningServices", # Fase 4: Azure ML
    "Microsoft.ServiceBus",              # Fase 5: avisos
    "Microsoft.Logic",                   # Fase 5: avisos
    "Microsoft.Web",                     # Fase 5: Functions
    "Microsoft.KeyVault",                # Fase 5: secretos
  ]
}
