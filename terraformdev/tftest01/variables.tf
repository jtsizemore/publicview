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
    default = "Dynamic"
}

variable "vm_cluster_size" {
    type = number
}

variable "virtual_machine_name_prefix" {
    type = string
}

variable "virtual_machine_size" {
    type = string
    default = "Standard_B1ls"
    description = "azure vm sizing"
}

variable "linux_vm_admin_username" {
    type = string
    sensitive = true
    default = "user01"
}

variable "disable_password_authentication" {
    type = bool
    default = true
    description = "false is use password. true if use admin_ssh_key"
}

variable "linux_vm_admin_password" {
    type = string
    sensitive = true
}

# variable "network_interface_ids" {
#     type = list(string)
# }

variable "virtual_machine_disk_caching" {
    type = string
    default = "None"
    description = "disk caching values: None, ReadOnly, ReadWrite"
}

variable "virtual_machine_storage_account_type" {
    type = string
    default = "Standard_LRS"
    description = "azure storage types: standard_lrs, standardssd_lrs, premium_lrs, standardssd_zrs, premium_zrs"
}

variable "virtual_machine_image_reference_publisher" {
    type = string
    default = "Canonical"
}

variable "virtual_machine_image_reference_offer" {
    type = string
    default = "0001-com-ubuntu-server-focal"
}

variable "virtual_machine_image_reference_sku" {
    type = string
    default = "20_04-lts-gen2"
}

variable "virtual_machine_image_reference_version" {
    type = string
    default = "latest"
}
