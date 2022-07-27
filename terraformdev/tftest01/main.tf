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
    # tenant_id = null
    # subscription_id = null
    # client_id = null
    # client_secret = null
    skip_provider_registration = false
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

resource "azurerm_public_ip" "public_ip_address" {
    depends_on = [
      azurerm_resource_group.resource_group
    ]
    count = var.vm_nic_count
    # name = var.public_ip_address_name
    name = format("${var.public_ip_address_name_prefix}%03s", count.index + 1)
    resource_group_name = var.resource_group_name
    location = var.resource_group_location
    allocation_method = var.public_ip_address_allocation
    domain_name_label = var.public_ip_address_dns
}

resource "azurerm_network_interface" "virtual_machine_nic" {
    depends_on = [
      azurerm_subnet.subnet,
    ]
    count = var.vm_nic_count
    # name = var.virtual_machine_nic_name
    name = format("${var.virtual_machine_nic_name_prefix}%03s", count.index + 1)
    location = var.resource_group_location
    resource_group_name = var.resource_group_name
    ip_configuration {
        name = format("${var.ip_configuration_prefix}%03s", count.index + 1)
        subnet_id = resource.azurerm_subnet.subnet.id
        private_ip_address_allocation = var.private_ip_address_allocation
        private_ip_address = (
            lower(var.private_ip_address_allocation) == "static" ?
            cidrhost(resource.azurerm_subnet.subnet.address_prefixes[0], count.index + 4) : null
        )
        public_ip_address_id = azurerm_public_ip.public_ip_address[count.index].id
    }
}

resource "azurerm_linux_virtual_machine" "linux_vm_ubuntu" {
    depends_on = [
      azurerm_network_interface.virtual_machine_nic
    ]
    count = var.vm_cluster_size
    name = format("${var.virtual_machine_name_prefix}%02s", count.index + 1)
    resource_group_name = var.resource_group_name
    location = var.resource_group_location
    size = var.virtual_machine_size
    admin_username = var.linux_vm_admin_username
    disable_password_authentication = var.disable_password_authentication
    admin_password = var.linux_vm_admin_password
    network_interface_ids = [resource.azurerm_network_interface.virtual_machine_nic[count.index].id]
    # admin_ssh_key {}
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
