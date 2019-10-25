terraform {
  backend "azurerm" {
    # Variables are not allowed in "backend" blocks
    resource_group_name  = "liftoff-modern-application-delivery"
    storage_account_name = "liftoffmodernapplication"
    container_name       = "tfstate"
    key                  = "networking.tfstate"
  }
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = format("%s-network", data.azurerm_resource_group.resource_group.name)
  address_space       = ["10.10.0.0/16"]
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = data.azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.10.0.0/24"
}

resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = data.azurerm_resource_group.resource_group.name

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}
