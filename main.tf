provider "azurerm" {
  features {}
}

# Generates a random 6-byte hex string to ensure global uniqueness for resource names
resource "random_id" "id" { byte_length = 6 }

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  # CRITICAL FIX: Appending the random ID to ensure the Resource Group name is unique.
  # This prevents the "group already exists" error.
  name     = "DemoDevOps-RG-${random_id.id.hex}"
  location = "malaysiawest"
}

# 2. App Service Plan (The host hardware)
resource "azurerm_service_plan" "plan" {
  # FIX: The App Service Plan name also needs to be unique for reliable re-runs.
  name                = "demo-devops-plan-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier for cost-effectiveness
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "demoacr${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  # OPTIMIZATION: Set to false, as we are now using Managed Identity (SystemAssigned) which is more secure.
  admin_enabled       = false 
}

# 4. Azure Linux Web App (The container host)
resource "azurerm_linux_web_app" "webapp" {
  name                = "demo-webapp-${random_id.id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  app_settings = {
    "WEBSITES_PORT"                  = "8080"
    "PORT"                           = "8080"
    "DOCKER_REGISTRY_SERVER_ENABLED" = "true"
    # OPTIMIZATION: This setting is required when using Managed Identity to specify the registry URL.
    "DOCKER_REGISTRY_SERVER_URL"     = azurerm_container_registry.acr.login_server 
  }

  site_config {
    always_on = true
  }

  # This block enables the System-Assigned Managed Identity
  identity {
    type = "SystemAssigned"
  }
  
  # CRITICAL: This tells the Web App to use its Managed Identity instead of credentials to pull the image.
  container_registry_use_managed_identity = true
}

# 5. Grant the Web App (via its Managed Identity) permission to pull from ACR
# This block is essential for the secure, credential-less pull process.
resource "azurerm_role_assignment" "app_service_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}
