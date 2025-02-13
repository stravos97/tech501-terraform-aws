output "vm_public_ip" {
  description = "Public IP address of the created virtual machine"
  value       = azurerm_linux_virtual_machine.vm.public_ip_address
}
