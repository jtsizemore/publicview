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