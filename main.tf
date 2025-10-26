provider "azurerm" {
  features {}
  # Terraform automatically uses ARM_... environment variables exported by Jenkins
}

resource "random_id" "id" { byte_length = 6 }

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "DemoDevOps-RG"
  # FIX: Changing from 'westeurope' to 'eastus' to bypass the Azure Policy Restriction (403 Forbidden)
  location = "eastus" 
}

# 2. Azure Container Registry (ACR) - To store our Docker image
resource "azurerm_container_registry" "acr" {
  # Globally unique name using random hex suffix
  name                = "demoacr${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  # Admin enabled is required for Jenkins to log in and push the image
  admin_enabled       = true 
}

# 3. App Service Plan (The host hardware for the app)
resource "azurerm_service_plan" "plan" {
  name                = "demo-devops-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" 
}

# 4. Azure Linux Web App (The container host)
resource "azurerm_linux_web_app" "webapp" {
  name                = "demo-webapp-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = true
  }

  # Essential settings for running a container on App Service
  app_settings = {
    # CRITICAL: This tells App Service which internal port the container exposes (must match Dockerfile)
    "WEBSITES_PORT" = "8080" 
    # Standard environment variable also used by your app.py/gunicorn
    "PORT"          = "8080"
    # Enable deployment from the private registry (ACR)
    "DOCKER_REGISTRY_SERVER_ENABLED" = "true" 
  }
  
  # Enable System Assigned Identity for ACR pull permission
  identity {
    type = "SystemAssigned"
  }
}

# 5. Grant the Web App (via its System-Assigned Identity) permission to pull from ACR
resource "azurerm_role_assignment" "app_service_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}
