provider "azurerm" {
  features {}
}

resource "random_id" "id" { byte_length = 6 }

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "DemoDevOps-RG"
  # CRITICAL FIX: Changed the region again to 'westus'.
  location = "Central US"
}

# 2. App Service Plan (The host hardware)
resource "azurerm_service_plan" "plan" {
  name                = "demo-devops-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "demoacr${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
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
  }

  site_config {
    always_on = true
  }

  identity {
    type = "SystemAssigned"
  }
}

# 5. Grant the Web App permission to pull from ACR
resource "azurerm_role_assignment" "app_service_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}