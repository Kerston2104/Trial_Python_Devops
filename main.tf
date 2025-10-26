provider "azurerm" {
  features {}
}

resource "random_id" "id" { byte_length = 6 }

# 1. A Resource Group (a folder for all our stuff)
resource "azurerm_resource_group" "rg" {
  name     = "DemoDevOps-RG"
  location = "East US"
}

# 2. The Azure Container Registry (to store our Docker image)
resource "azurerm_container_registry" "acr" {
  name                = "demoacr${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 3. The App Service Plan (the "hardware" to run our app)
resource "azurerm_service_plan" "plan" {
  name                = "demo-devops-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 4. The App Service (the "server" that runs the container)
resource "azurerm_linux_web_app" "webapp" {
  name                = "demo-webapp-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id
  
  site_config {
    app_settings = {
      "WEBSITES_PORT" = "8080" # Tell Azure our app uses port 8080
    }
  }
}