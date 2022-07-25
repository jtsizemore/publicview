terraform {
    required_providers {
      azurerm = {
        version = ">=3.10.0"
        source = "hashicorp/azurerm"
      }
    }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "resource_group" {
    name = var.resource_group_name
    location = var.resource_group_location
}

resource "azurerm_virtual_network" "virtual_network" {
    name = var.virtual_network_name
    location = var.resource_group_location
    resource_group_name = var.resource_group_name
    address_space = var.virtual_network_address_space
}

resource "azurerm_subnet" "subnet" {
    depends_on = [
      azurerm_virtual_network.virtual_network
    ]
    name = var.subnet_name
    resource_group_name = var.resource_group_name
    virtual_network_name = var.virtual_network_name
    address_prefixes = var.subnet_address_prefixes
}