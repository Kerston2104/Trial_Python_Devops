provider "azurerm" {
  features {}
  # Removed subscription_id = "xxxx". Jenkins handles authentication securely.
}

# Used to ensure globally unique names for ACR and Web App
resource "random_id" "id" { byte_length = 6 }

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  # Renamed to 'rg' for Jenkinsfile compatibility
  name     = "DemoDevOps-RG"
  # CRITICAL FIX: Changed from 'West Europe' to 'eastus' to satisfy Azure Policy.
  location = "eastus" 
}

# 2. App Service Plan (The host hardware)
resource "azurerm_service_plan" "plan" {
  # Renamed to 'plan' for Jenkinsfile compatibility
  name                = "demo-devops-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  # FIX: Changed from 'P1v2' (Premium) to 'B1' (Basic) for cost saving.
  sku_name            = "B1" 
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  # Renamed to 'acr' for Jenkinsfile compatibility
  name                = "demoacr${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  # FIX: Changed from 'Premium' to 'Basic' for cost saving.
  sku                 = "Basic" 
  admin_enabled       = true
}

# 4. Azure Linux Web App (The container host)
# NOTE: Using azurerm_linux_web_app, required for container deployments.
resource "azurerm_linux_web_app" "webapp" {
  # Renamed to 'webapp' for Jenkinsfile compatibility
  name                = "demo-webapp-${random_id.id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_service_plan.plan.id
  
  # FIX: Replaced insecure DOCKER_REGISTRY_SERVER_USERNAME/PASSWORD
  # with the required App Service settings for successful container runtime.
  app_settings = {
    # CRITICAL: This tells App Service which internal port the container exposes (must match Dockerfile)
    "WEBSITES_PORT" = "8080" 
    # Standard environment variable also used by your app.py/gunicorn
    "PORT"          = "8080"
    # Enable deployment from the private registry (ACR)
    "DOCKER_REGISTRY_SERVER_ENABLED" = "true" 
  }

  site_config {
    always_on = true
    # FIX: This configuration is no longer needed when using System-Assigned Identity.
    # The Jenkins pipeline will set the final image name.
  }

  identity {
    type = "SystemAssigned"
  }
}

# 5. Grant the Web App (via its System-Assigned Identity) permission to pull from ACR
# This is the modern, secure way to grant ACR access, replacing admin credentials.
resource "azurerm_role_assignment" "app_service_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}
