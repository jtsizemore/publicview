resource "azurerm_network_security_group" "network_security_group" {
    depends_on = [
      azurerm_network_interface.virtual_machine_nic
    ]
    count = var.vm_nic_count
    name = var.nsg_name
    resource_group_name = var.resource_group_name
    location = var.resource_group_location
}

resource "azurerm_network_security_rule" "nsg_rule" {
    depends_on = [
      azurerm_network_security_group.network_security_group
    ]
    for_each = var.nsg_rules
    resource_group_name = var.resource_group_name
    network_security_group_name = var.nsg_name
    name = each.key
    priority = each.value.priority
    direction = each.value.direction
    access = each.value.access
    protocol = each.value.protocol
    source_port_range = each.value.source_port_range == "*" ? each.value.source_port_range : null
    source_port_ranges = each.value.source_port_range == "*" ? null : each.value.source_port_ranges
    destination_port_range = each.value.destination_port_range == "*" ? each.value.destination_port_range : null
    destination_port_ranges = each.value.destination_port_range == "*" ? null : each.value.destination_port_ranges
    source_address_prefix = each.value.source_address_prefix == "*" ? each.value.source_address_prefix : null
    source_address_prefixes = each.value.source_address_prefix == "*" ? null : each.value.source_address_prefixes
    destination_address_prefix = each.value.destination_address_prefix == "*" ? each.value.destination_address_prefix : null
    destination_address_prefixes = each.value.destination_address_prefix == "*" ? null : each.value.destination_address_prefixes
}

resource "azurerm_network_interface_security_group_association" "nsg_nic" {
    depends_on = [
      azurerm_network_security_group.network_security_group
    ]
    count = var.nsg_association.association_type == "nic" ? 1 : 0
    network_interface_id = var.nsg_association.association_type == "nic" ? var.nsg_association.association_id : null
    network_security_group_id = azurerm_network_security_group.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
    depends_on = [
      azurerm_network_security_group.network_security_group
    ]
    count = var.nsg_association.association_type == "subnet" ? 1 : 0
    subnet_id = var.nsg_association.association_type == "subnet" ? var.nsg_association.association_id : null
    network_security_group_id = azurerm_network_security_group.network_security_group.id
}