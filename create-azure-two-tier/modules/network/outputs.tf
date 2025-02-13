output "nic_id" {
  description = "Network interface ID to be used by compute modules"
  value       = azurerm_network_interface.nic.id
}
