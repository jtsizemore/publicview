nsg_name = "nsg-jtsizemore-test-nsg01"
nsg_rules = {
    rule01 = {
        name = "http-80"
        description = "http port 80"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        source_port_ranges = ["null"]
        destination_port_range = "80"
        destination_port_ranges = ["null"]
        source_address_prefix = "*"
        source_address_prefixes = ["null"]
        destination_address_prefix = "*"
        destination_address_prefixes = ["null"]
    }
    rule02 = {
        name = "https-443"
        description = "http port 443"
        priority = 110
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        source_port_ranges = ["null"]
        destination_port_range = "443"
        destination_port_ranges = ["null"]
        source_address_prefix = "*"
        source_address_prefixes = ["null"]
        destination_address_prefix = "*"
        destination_address_prefixes = ["null"]
    }
}

nsg_association = {
  association_type = "nic"
}