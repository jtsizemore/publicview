variable "resource_group_name" {
    type = string
}

variable "resource_group_location" {
    type = string
}

variable "virtual_network_name" {
    type = string
}

variable "virtual_network_address_space" {
    type = list(string)
}

variable "subnet_name" {
    type = string
}

variable "subnet_address_prefixes" {
    type = list(string)
}

variable "vm_nic_count" {
    type = number
    description = "number of nics for each vm"
}

# variable "virtual_machine_nic_name" {
#     type = string
# }

variable "virtual_machine_nic_name_prefix" {
    type = string
}

# variable "ip_configuration_name" {
#     type = string
# }

variable "ip_configuration_prefix" {
    type = string
}

variable "private_ip_address_allocation" {
    type = string
}

variable "network_interface_ids" {
    type = list(string)
}

variable "vm_cluster_size" {
    type = number
}

variable "virtual_machine_disk_caching" {
    type = string
}

variable "virtual_machine_storage_account_type" {
    type = string
}

variable "virtual_machine_image_reference_publisher" {
    type = string
}

variable "virtual_machine_image_reference_offer" {
    type = string
}

variable "virtual_machine_image_reference_sku" {
    type = string
}

variable "virtual_machine_image_reference_version" {
    type = string
}
