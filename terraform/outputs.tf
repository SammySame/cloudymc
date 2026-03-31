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

output "instance_public_ssh_key_contents" {
  description = "Instance public SSH key contents."
  value       = data.oci_core_instance.this.metadata["ssh_authorized_keys"]
}

output "ansible_inventory" {
  description = "Inventory file used by Ansible"
  value       = local.ansible_inv
  sensitive   = true
}
