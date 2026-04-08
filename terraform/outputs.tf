locals {
  ansible_inv = templatefile("hosts.yml.tftpl", {
    identifier           = var.identifier
    public_ip            = module.instance.public_ip
    private_ssh_key_path = trimsuffix(var.public_ssh_key_path, ".pub")
  })
}

output "instance_address" {
  description = "Instance public IP address."
  value       = module.instance.public_ip
  sensitive   = true
}

output "ansible_inventory" {
  description = "Inventory file used by Ansible."
  value       = local.ansible_inv
  sensitive   = true
}

output "is_instance_running" {
  description = "Checks and returns if instance is running."
  value       = data.oci_core_instance.this.state == "RUNNING"
}
