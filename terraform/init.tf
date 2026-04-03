terraform {
  backend "local" {
    path = "/etc/cloudymc/data/terraform/terraform.tfstate"
  }
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.5.0"
    }
  }
  required_version = "~> 1.14"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_ssh_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}
