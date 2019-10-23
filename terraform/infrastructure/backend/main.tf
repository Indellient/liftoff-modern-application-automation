resource "azurerm_resource_group" "resource_group" {
  name     = "liftoff-modern-application-delivery"
  location = var.resource_group_location

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                     = substr(replace(azurerm_resource_group.resource_group.name, "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}
