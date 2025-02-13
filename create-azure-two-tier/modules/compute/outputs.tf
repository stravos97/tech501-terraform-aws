output "vm_public_ip" {
  description = "Public IP address of the created virtual machine"
  value       = azurerm_linux_virtual_machine.vm.public_ip_address
}
output "db_private_ip" {
  description = "Private IP address of the DB VM"
  value       = azurerm_linux_virtual_machine.vm.private_ip_address
}