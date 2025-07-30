output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_group_fqdn" {
  description = "FQDN of the container group"
  value       = azurerm_container_group.main.fqdn
}

output "container_group_ip" {
  description = "IP address of the container group"
  value       = azurerm_container_group.main.ip_address
}