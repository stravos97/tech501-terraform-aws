output "nic_id" {
  description = "Network interface ID to be used by compute modules"
  value       = azurerm_network_interface.nic.id
}

output "public_ip" {
  description = "Public IP address (if public subnet)"
  value       = var.is_public_subnet ? azurerm_public_ip.public_ip[0].ip_address : null
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.subnet.id
}
