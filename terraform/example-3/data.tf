data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = "liftoff-modern-application-delivery"
    storage_account_name = "liftoffmodernapplication"
    container_name       = "tfstate"
    key                  = "networking.tfstate"
  }
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_dns_zone" "dns_zone" {
  name                = data.terraform_remote_state.networking.outputs.dns_zone_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_image" "image" {
  name                = var.image_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}
