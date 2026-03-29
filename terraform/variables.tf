variable "oci_free_tier_only" {
  description = "Ensure that the configuration stays within the OCI free tier limits."
  type        = bool
  nullable    = false
}

variable "tenancy_ocid" {
  description = "OCID of the tenancy used for OCI authentication"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "user_ocid" {
  description = "OCID of the user used for OCI authentication"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key used for OCI authentication."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint of the private SSH key used for OCI authentication"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "region" {
  description = "Region used for OCI authentication"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "alert_email_addresses" {
  description = <<EOT
  List of Email addresses that will get notified if the OCI free tier limit is exceeded.
  Leave empty string if you would rather not receive emails.
  EOT
  type        = list(string)
  default     = []
  nullable    = false
  sensitive   = true
}

variable "public_ssh_key_paths" {
  description = "Path to the public SSH key/s used for SSH access into the instance."
  type        = list(string)
  default     = []
  nullable    = false
  sensitive   = true
  validation {
    condition     = alltrue([for path in var.public_ssh_key_paths : fileexists(abspath(path))])
    error_message = "One or more public SSH keys doesn't exist at the provided path."
  }
}

variable "availability_domain_number" {
  description = "Number corresponding to a region's preferred availability domain."
  type        = number
  default     = 1
  nullable    = false
}

variable "identifier" {
  description = "Unique identifier used for naming resources."
  type        = string
  nullable    = false
  validation {
    condition     = var.identifier != ""
    error_message = "Unique identifier cannot be an empty string."
  }
}

variable "compartment_name" {
  description = "Name of the compartment that the resources will belong to"
  type        = string
  nullable    = false
}

variable "compartment_description" {
  description = "Description of the compartment that the resources will belong to."
  type        = string
  nullable    = false
}

variable "instance_image" {
  description = "OCID of the operating system."
  type        = string
  nullable    = false
}

variable "instance_shape" {
  description = "Type of the underlying computer hardware."
  type        = string
  default     = "VM.Standard.A1.Flex"
  nullable    = false
}

variable "instance_ocpus" {
  description = "Number of allocated CPU cores."
  type        = number
  default     = 4
  nullable    = false
}

variable "instance_ram" {
  description = "Number of allocated RAM memory in gigabytes."
  type        = number
  default     = 24
  nullable    = false
}

variable "instance_volume_size" {
  description = "Amount of allocated disk storage in gigabytes."
  type        = number
  default     = 200
  nullable    = false
}

variable "ingress_ports" {
  description = <<EOT
    custom_ports = [{ : Optional list of ports that will be open to the internet.
      protocol        : Port protocol name. Only "UDP" or "TCP" supported.
      number          : Port number.
    }]
EOT
  type = list(object({
    protocol = string
    number   = number
  }))
  default  = null
  nullable = true
}

variable "vcn_cidr" {
  description = "CIDR block used in the virtual cloud network."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "subnet_netnum" {
  description = "Number used in the subnet host identifier part of the CIDR."
  type        = number
  default     = 1
  nullable    = false
}
