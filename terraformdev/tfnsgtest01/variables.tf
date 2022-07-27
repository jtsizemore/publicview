variable "nsg_name" {
    type = string
}

# variable "nsg_rule" {
#     type = list(object({
#         name = string
#         description = string
#         priority = number
#         direction = string
#         access = string
#         protocol = string
#         source_port_range = string
#         # source_port_ranges = list(string)
#         destination_port_range = string
#         # destination_port_ranges = list(string)
#         source_address_prefix = string
#         # source_address_prefixes = list(string)
#         destination_address_prefix = string
#         # destination_address_prefixes = list(string)
#     }))
# }

variable "nsg_rules" {
    type = map(any)
}

variable "nsg_association" {
  type = map(string)
}