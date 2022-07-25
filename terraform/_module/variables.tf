variable "resource_group_name" {
    type = string
}

variable "vm_cluster_size" {
    type = number
    description = "number of vms to deploy"
}

variable "vnet_name" {
    type = string
}

variable "vnet_rg_name" {
    type = string
}

variable "vm_subnet_name" {
    type = string
}

variable "ilb_subnet_name" {
    type = string
}

variable "vm_boot_diagnostic_prefix" {
    type = string
    description = "prefix for vm boot diagnostic storage account"
}

variable "vm_boot_diagnostics_storage_tier" {
    type = string
}

variable "vm_boot_diagnostics_storage_replication_type" {
    type = string
}

variable "nic_prefix" {
    type = string
}

variable "nic_suffix" {
    type = string
}

variable "nic_ip_configuration_name" {
    type = string
}

variable "nic_private_ip_address_allocation" {
    type = string
    description = "private ip allocation method for nic"
}

variable "vm_host_name" {
    type = string
    description = "name of azure vm host machine"
}

variable "azure_vm_size" {
    type = string
    description = "azure vm sizing"
}

variable "vm_guest_name" {
    type = string
    description = "name of the guest system"
}

variable "admin_username" {
    type = string
    sensitive = true
}

variable "admin_password" {
    type = string
    sensitive = true
}

variable "cluster_vm_os_disk_prefix" {
    type = string
}

variable "storage_os_disk_create_option" {
    type = string
}

variable "storage_os_disk_caching" {
    type = string
}

variable "storage_os_disk_managed_disk_type" {
    type = string
}

variable "os_profile_linux_config_disable_password_auth" {
    type = bool
}

variable "publisher" {
    type = string
    description = "vm plan publisher name"
}

variable "product" {
    type = string
    description = "vm plan product man"
}

variable "plan_name" {
    type = string
    description = "vm plan name"
}

variable "offer" {
    type = string
    description = "vm storage image reference offer name"
}

variable "storage_image_reference_sku" {
    type = string
    description = "vm storage image reference sku"
}

variable "storage_image_reference_version" {
    type = string
    description = "vm storage image reference version"
}

variable "azure_ilb_name" {
    type = string
    description = "azure ilb name"
}

variable "azure_ilb_sku" {
    type = string
}

variable "azure_ilb_frontend_ip_config_name" {
    type = string
}

variable "azure_ilb_private_ip_address_allocation" {
    type = string
}

variable "azure_ilb_vip_address" {
    type = string
}

variable "azure_ilb_backend_pool_name" {
    type = string
}

variable "azure_ilb_probe" {
    type = list(map(any))
    # default = [ {
    #   "name"        = "tcp-probe-8443"
    #   "port"        = 8443
    #   "protocol"    = "tcp"
    # } ]
}

variable "azure_ilb_rule" {
    type = list(map(any))
    # default = [ {
    #   "name"        = "tcp-rule-8443"
    #   "port"        = 8443
    #   "protocol"    = "tcp"
    # } ]
}

variable "deploy01_tags" {
    type = map(string)
    default = null
}