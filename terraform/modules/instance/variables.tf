variable "shape" {
  description = "Type of underlying computer hardware ."
  type        = string
  nullable    = false
}

variable "image" {
  description = "OCID of the operating system."
  type        = string
  nullable    = false
}

variable "ocpus" {
  description = "Number of allocated CPU cores."
  type        = number
  nullable    = false
}

variable "ram" {
  description = "Number of allocated RAM memory in gigabytes."
  type        = number
  nullable    = false
}

variable "volume_size" {
  description = "Amount of allocated disk storage in gigabytes."
  type        = number
  nullable    = false
}

variable "preserve_boot_volume" {
  description = "Should the boot volume be preserved upon instance deletion."
  type        = bool
  default     = false
  nullable    = false
}

variable "subnet_cidr" {
  description = "CIDR block used in the subnet."
  type        = string
  nullable    = false
}

variable "public_ssh_key_paths" {
  description = "Path to the public SSH key/s used for the instance connection."
  type        = list(string)
  nullable    = false
}

variable "name_prefix" {
  description = "Resource display names prefix."
  type        = string
  nullable    = false
}

variable "availability_domain" {
  description = "Name of the availability domain that the resources will belong to."
  type        = string
  nullable    = false
}

variable "subnet_id" {
  description = "OCID of the subnet that the instance will belong to."
  type        = string
  nullable    = false
}

variable "compartment_id" {
  description = "OCID of the compartment that the resources will belong to."
  type        = string
  nullable    = false
}
