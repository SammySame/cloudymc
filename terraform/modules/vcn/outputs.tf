output "vcn_id" {
  description = "Vritual Cloud Network (VCN) OCID."
  value       = oci_core_vcn.this.id
}

output "internet_gateway_id" {
  description = "Internet Gateway OCID."
  value       = oci_core_internet_gateway.this.id
}

output "vcn_cidr" {
  description = "Virtual Cloud Network (VCN) CIDR block."
  value       = oci_core_vcn.this.cidr_block
}
