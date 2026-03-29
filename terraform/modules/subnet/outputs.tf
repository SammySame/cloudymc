output "subnet_id" {
  description = "Subnet OCID."
  value       = oci_core_subnet.this.id
}

output "route_table_id" {
  description = "Route table OCID."
  value       = oci_core_route_table.this.id
}

output "security_list_id" {
  description = "Security List OCID."
  value       = oci_core_security_list.this.id
}

output "subnet_cidr" {
  description = "CIDR block of the Subnet."
  value       = oci_core_subnet.this.cidr_block
}
