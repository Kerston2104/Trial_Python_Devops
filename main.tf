terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.111.0"
    }
  }
}
provider "azurerm"{
features{}
subscription_id = "04af6da8-93f0-4e3f-8823-10577bf91c60"
}
resource "azurerm_resource_group" "example" {
  name     = "DemoDevOps-RG"
  location = "eastus"
}
resource "azurerm_service_plan" "example" {
  name                = "examplejah"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}
resource "azurerm_container_registry" "example" {
  name                = "ahRegistry1j"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Premium"
  admin_enabled       = true
}
resource "azurerm_app_service" "backend" {
  name                = "jahservice12new"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_service_plan.example.id
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = azurerm_container_registry.example.login_server
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.example.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.example.admin_password
  }

  site_config {
    always_on = "true"
    # define the images to used for you application
    linux_fx_version = "DOCKER|${azurerm_container_registry.example.login_server}"
  }

  identity {
    type = "SystemAssigned"
  }
}
