variable "vcn_cidr" {
  description = "CIDR block used in the virtual cloud network."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "name_prefix" {
  description = "Resource display names prefix."
  type        = string
  nullable    = false
}

variable "compartment_id" {
  description = "OCID of the compartment that the resources will belong to."
  type        = string
  nullable    = false
}
