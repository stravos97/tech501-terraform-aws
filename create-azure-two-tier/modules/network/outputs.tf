output "nic_id" {
  description = "Network interface ID to be used by other modules"
  value       = azurerm_network_interface.nic.id
}

