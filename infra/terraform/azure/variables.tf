variable "location" {
  type        = string
  description = "Region de azure donde se crean los recursos"
  default     = "eastus2"
}

variable "environment" {
  type        = string
  description = "entorno donde corre la infrestructura"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment debe ser \"dev\" o \"prod\"."
  }
}

variable "data_admin_object_id" {
  type        = string
  description = "Object ID en Entra ID de la persona que administra los datos (acceso de DVC)."
}
