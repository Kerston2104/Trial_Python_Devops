output "acr_login_server" {
  description = "The login server for the Azure Container Registry."
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin username for the ACR."
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for the ACR."
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "app_service_name" {
  description = "The name of the App Service."
  value       = azurerm_linux_web_app.webapp.name
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.rg.name
}

output "website_url" {
  description = "The URL of the deployed website."
  value       = "https://${azurerm_linux_web_app.webapp.default_hostname}"
}

