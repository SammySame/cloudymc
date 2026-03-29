locals {
  ansible_inv = templatefile("hosts.yml.tftpl", {
    identifier           = var.identifier
    public_ip            = module.instance.public_ip
    private_ssh_key_path = var.private_ssh_key_path
  })
}

output "instance_address" {
  description = "Instance public IP address."
  value       = module.instance.public_ip
  sensitive   = true
}

output "ansible_inventory" {
  description = "Inventory file used by Ansible"
  value       = local.ansible_inv
  sensitive   = true
}
