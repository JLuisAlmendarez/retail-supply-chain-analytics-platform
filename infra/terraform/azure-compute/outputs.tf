output "nat_public_ip" {
  description = "IP de salida de los clústeres clásicos (allowlists, p. ej. network policy de Snowflake)."
  value       = azurerm_public_ip.nat.ip_address
}
