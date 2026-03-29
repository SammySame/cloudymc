terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=7.28.0"
    }
  }
  required_version = ">= 1.0.0"
}
