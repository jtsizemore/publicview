terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = ">= 3.11.0"
        }
    }
    required_version = ">=2.64.0"
    experiments = [module_variable_optional_attrs]
}

data "azurerm_resource_group" "resource_group" {
    name = var.resource_group
}

locals {
  location = data.azurerm_resource_group.resource_group.location
  rg_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_virtual_network" "vnet" {
    resource_group_name = var.vnet_rg_name
    name = var.vnet_name
}

data "azurerm_subnet" "vm_subnet" {
    resource_group_name = var.vnet_rg_name
    virtual_network_name = var.vnet_name
    name = var.vm_subnet_name
}

data "azurerm_subnet" "ilb_subnet" {
    resource_group_name = var.vnet_rg_name
    virtual_network_name = var.vnet_name
    name = var.ilb_subnet_name
}

resource "azurerm_storage_account" "vm_boot_diagnostics" {
    count = var.vm_cluster_size
    name = format("${var.vm_boot_diagnostic_prefix}%02s", count.index + 1)
    resource_group_name = local.rg_name
    location = local.location
    access_tier = var.vm_boot_diagnostics_storage_tier
    account_replication_type = var.vm_boot_diagnostics_storage_replication_type
    tags = var.deploy01_tags
}

resource "azurerm_network_interface" "vm_nics" {
    count = var.vm_cluster_size
    resource_group_name = local.rg_name
    location = local.location
    name = format("${var.nic_prefix}-${var.vm_host_name}%03s-${var.nic_suffix}", count.index + 1)
    ip_configuration {
        name = var.nic_ip_configuration_name
        subnet_id = data.azurerm_subnet.vm_subnet.id
        private_ip_address_allocation = var.nic_private_ip_address_allocation
        private_ip_address = (
            lower(var.nic_private_ip_address_allocation) == "static" ?
            cidrhost(data.azurerm_subnet.vm_subnet.address_prefixes[0], count.index + 1) : null
        )
    }
    tags = var.deploy01_tags
}

locals {
    az_redundancy_zone_mapping = tomap({"1"="1", "2"="2", "0"="3"})
}

resource "azurerm_virtual_machine" "cluster_vms" {
    count = var.vm_cluster_size
    depends_on = [
        azurerm_storage_account.vm_boot_diagnostics,
        azurerm_network_interface.vm_nics
    ]
    resource_group_name = local.rg_name
    location = local.location
    name = format("${var.vm_host_name}%03s", count.index + 1)
    vm_size = var.azure_vm_size
    network_interface_ids = [azurerm_network_interface.vm_nics[count.index].id]
    os_profile {
        computer_name = format("${var.vm_guest_name}%s", count.index + 1)
        admin_username = var.admin_username
        admin_password = var.admin_password
    }
    storage_os_disk {
        name = format("${var.cluster_vm_os_disk_prefix}%02s", count.index + 1)
        create_option = var.storage_os_disk_create_option
        caching = var.storage_os_disk_caching
        managed_disk_type = var.storage_os_disk_managed_disk_type
    }
    os_profile_linux_config {
        disable_password_authentication = var.os_profile_linux_config_disable_password_auth
    }
    boot_diagnostics {
        enabled = true
        storage_uri = azurerm_storage_account.vm_boot_diagnostics[count.index].primary_blob_endpoint
    }
    plan {
        publisher = var.publisher
        product = var.product
        name = var.plan_name
    }
    storage_image_reference {
        publisher = var.publisher
        offer = var.offer
        sku = var.storage_image_reference_sku
        version = var.storage_image_reference_version
    }
    availability_zones = [lookup( local.az_redundancy_zone_mapping, (count.index + 1) % 3)]
    tags = var.deploy01_tags
}

resource "azurerm_lb" "azure_ilb" {
    depends_on = [
      azurerm_virtual_machine.cluster_vms
    ]
    resource_group_name = local.rg_name
    location = local.location
    name = var.azure_ilb_name
    sku = var.azure_ilb_sku
    frontend_ip_configuration {
        name = var.azure_ilb_frontend_ip_config_name
        subnet_id = data.azurerm_subnet.ilb_subnet.id
        private_ip_address_allocation = var.azure_ilb_private_ip_address_allocation
        private_ip_address = var.azure_ilb_vip_address
    }
    tags = var.deploy01_tags
}

resource "azurerm_lb_backend_address_pool" "azure_ilb_backend_pool" {
    depends_on = [
      azurerm_lb.azure_ilb
    ]
    name = var.azure_ilb_backend_pool_name
    loadbalancer_id = azurerm_lb.azure_ilb.id
}

resource "azurerm_network_interface_backend_address_pool_association" "azure_ilb_backend_association" {
    depends_on = [
      azurerm_network_interface.vm_nics,
      azurerm_lb_backend_address_pool.azure_ilb_backend_pool
    ]
    count = var.vm_cluster_size
    network_interface_id = azurerm_network_interface.vm_nics[count.index].id
    ip_configuration_name = var.nic_ip_configuration_name
    backend_address_pool_id = azurerm_lb_backend_address_pool.azure_ilb_backend_pool.id
}

resource "azurerm_lb_probe" "azure_ilb_probe" {
    depends_on = [
      azurerm_network_interface_backend_address_pool_association.azure_ilb_backend_association.azure_ilb_backend_association
    ]
    count = length(var.azure_ilb_probe)
    loadbalancer_id = azurerm_lb.azure_ilb.id
    name = var.azure_ilb_probe[count.index].name
    port = var.azure_ilb_probe[count.index].port
    protocol = var.azure_ilb_probe[count.index].protocol
}

resource "azurerm_lb_rule" "azure_ilb_rule" {
    depends_on = [
      azurerm_lb_probe.azure_ilb_probe
    ]
    count = length(var.azure_ilb_rule)
    loadbalancer_id = azurerm_lb.azure_ilb.id
    name = var.azure_ilb_rule[count.index].name
    protocol = var.azure_ilb_rule[count.index].protocol
    frontend_port = var.azure_ilb_rule[count.index].frontend_port
    backend_port = var.azure_ilb_rule[count.index].backend_port
    frontend_ip_configuration_name = var.azure_ilb_frontend_ip_config_name
    backend_address_pool_ids = [azurerm_lb_backend_address_pool.azure_ilb_backend_pool.id]
    load_distribution = var.azure_ilb_rule[count.index].load_distribution
    probe_id = azurerm_lb_probe.azure_ilb_probe.azure_ilb_probe[count.index].id
}