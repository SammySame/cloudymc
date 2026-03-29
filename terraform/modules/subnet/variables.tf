locals {
  protocol_map = {
    tcp = 6
    udp = 17
  }
  allowed_protocols = keys(local.protocol_map)
}

variable "ingress_ports" {
  description = <<EOT
    [{         : List of ports that will be open to the internet.
      protocol : Port protocol name. Only "UDP" or "TCP" supported.
      number   : Port number.
    }]
EOT
  type = list(object({
    protocol = string
    number   = number
  }))
  validation {
    condition = alltrue(flatten([
      for port in var.ingress_ports :
      contains(local.allowed_protocols, lower(port.protocol))
    ]))
    error_message = "Port protocol must be either TCP or UDP."
  }
}

variable "subnet_netnum" {
  description = "Number used in the subnet host identifier part of the CIDR."
  type        = number
  nullable    = false
  validation {
    condition     = var.subnet_netnum >= 0 && var.subnet_netnum % 1 == 0
    error_message = "Subnet netnum must be a positive whole number."
  }
}

variable "vcn_cidr" {
  description = "CIDR block used in the virtual cloud network."
  type        = string
  nullable    = false
}

variable "name_prefix" {
  description = "Resource display names prefix."
  type        = string
  nullable    = false
}

variable "vcn_id" {
  description = "OCID of the VCN that the resources will belong to."
  type        = string
  nullable    = false
}

variable "network_entity_id" {
  description = "OCID of the network entity used in the route table."
  type        = string
  nullable    = false
}

variable "compartment_id" {
  description = "OCID of the compartment that the resources will belong to."
  type        = string
  nullable    = false
}
