variable "environment" {
  type        = string
  description = "Entorno del módulo persistente al que se le da salida."
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment debe ser \"dev\" o \"prod\"."
  }
}

variable "location" {
  type        = string
  description = "Región del módulo persistente (ver ADR-003)."
  default     = "westcentralus"
}
