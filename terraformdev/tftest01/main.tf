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
    depends_on = [
      azurerm_resource_group.resource_group
    ]
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

resource "azurerm_network_interface" "virtual_machine_nic" {
    count = var.vm_nic_count
    # name = var.virtual_machine_nic_name
    name = format("${var.virtual_machine_nic_name_prefix}%03s", count.index + 1)
    location = var.resource_group_location
    resource_group_name = var.resource_group_name
    ip_configuration {
        name = format("${var.ip_configuration_prefix}%02s", count.index + 1)
        subnet_id = var.subnet_id
        private_ip_address_allocation = var.private_ip_address_allocation
        private_ip_address = (
            lower(var.private_ip_address_allocation) == "static" ?
            cidrhost(resource.azurerm_subnet.vm_subnet.address_prefixes[0], count.index + 4) : null
        )
    }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
    count = var.vm_cluster_size
    name = format("${var.virtual_machine_name_prefix}%02s", count.index + 1)
    resource_group_name = var.resource_group_name
    location = var.resource_group_location
    size = var.virtual_machine_size
    network_interface_ids = [azurerm_network_interface.vm_nics[count.index].id]
    admin_ssh_key {}
    os_disk {
        caching = var.virtual_machine_disk_caching
        storage_account_type = var.virtual_machine_storage_account_type
    }
    source_image_reference {
        publisher = var.virtual_machine_image_reference_publisher
        offer = var.virtual_machine_image_reference_offer
        sku = var.virtual_machine_image_reference_sku
        version = var.virtual_machine_image_reference_version
    }
}
