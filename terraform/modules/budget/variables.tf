variable "budget_amount" {
  description = "Budget limit for the provided compartments."
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.budget_amount >= 1
    error_message = "Budget amount must be equal or greater than 1."
  }
}

variable "alert_threshold" {
  description = "Threshold for the invoiced money, after which an alert is triggered."
  type        = number
  default     = 0.01
  nullable    = false
  validation {
    condition     = var.alert_threshold > 0
    error_message = "Alert threshold must be greater than 0."
  }
}

variable "alert_email_addresses" {
  description = "Email addresses that will recieve budget alerts."
  type        = list(string)
  nullable    = false
}

variable "target_compartment_ids" {
  description = "OCIDs of the compartments that should have combined budget monitoring."
  type        = list(string)
  nullable    = false
  validation {
    condition     = length(var.target_compartment_ids) > 0
    error_message = "Target compartment IDs list must not be empty."
  }
}

variable "name_prefix" {
  description = "Unique prefix used in the resource display names."
  type        = string
  nullable    = false
}

variable "compartment_id" {
  description = "OCID of the compartment that the resources will belong to."
  type        = string
  nullable    = false
}
