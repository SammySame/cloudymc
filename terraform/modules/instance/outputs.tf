output "instance_id" {
  description = "Instance OCID."
  value       = oci_core_instance.this.id
}

output "boot_volume_id" {
  description = "Boot volume OCID."
  value       = oci_core_instance.this.boot_volume_id
}

output "instance_name" {
  description = "Instance display name."
  value       = oci_core_instance.this.display_name
}

output "boot_volume_name" {
  description = "Boot volume name."
  // Since boot volumes cannot be named at the creation, we do a little hack...
  value = "${oci_core_instance.this.display_name} (Boot Volume)"
}

output "public_ip" {
  description = "Instance public IP."
  value       = oci_core_instance.this.public_ip
  sensitive   = true
}
