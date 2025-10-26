provider "azurerm" {
  features {}
}

resource "random_id" "id" { byte_length = 6 }

# main.tf
resource "azurerm_resource_group" "rg" {
  name     = "DemoDevOps-RG"
  location = "westeurope" # <--- CHANGED AGAIN TO MATCH LIST
}
# ... rest of the file stays the same ...

# 2. The Azure Container Registry (to store our Docker image)
resource "azurerm_container_registry" "acr" {
  name                = "demoacr${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location # Inherits location from RG
  sku                 = "Basic"
  admin_enabled       = true
}

# 3. The App Service Plan (the "hardware" to run our app)
resource "azurerm_service_plan" "plan" {
  name                = "demo-devops-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location # Inherits location from RG
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier, should be free or cheap
}

# 4. The App Service (the "server" that runs the container)
resource "azurerm_linux_web_app" "webapp" {
  name                = "demo-webapp-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location # Inherits location from Plan
  service_plan_id     = azurerm_service_plan.plan.id
  
  # Correct placement for app_settings
  app_settings = {
    "WEBSITES_PORT" = "8080" # Tell Azure our app uses port 8080
  }

  site_config {
    # This block can be empty or have other settings, but NOT app_settings
  }
}

