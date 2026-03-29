output "instance_address" {
  description = "Instance public IP address."
  value       = module.instance.public_ip
}
