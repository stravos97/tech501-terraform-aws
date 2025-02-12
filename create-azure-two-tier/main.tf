provider "azurerm" {
  features {}

  subscription_id                 = var.subscription_id
  resource_provider_registrations = var.resource_provider_registrations
}

# Reference the existing resource group
data "azurerm_resource_group" "tech501" {
  name = var.resource_group_name

}

# Create a virtual network
resource "azurerm_virtual_network" "tech501" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.tech501.name
  location            = data.azurerm_resource_group.tech501.location
  address_space       = [var.vnet_address_space]
}

# Subnet
resource "azurerm_subnet" "tech501" {
  name                 = var.app_subnet_name
  resource_group_name  = data.azurerm_resource_group.tech501.name
  virtual_network_name = azurerm_virtual_network.tech501.name
  address_prefixes     = [var.app_subnet_address_prefix]
}

# Public IP
resource "azurerm_public_ip" "tech501" {
  name                = var.app_public_ip_name
  resource_group_name = data.azurerm_resource_group.tech501.name
  location            = data.azurerm_resource_group.tech501.location
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "tech501" {
  name                = var.app_nic_name
  resource_group_name = data.azurerm_resource_group.tech501.name
  location            = data.azurerm_resource_group.tech501.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tech501.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tech501.id
  }
}

# Associate NSG with Network Interface
resource "azurerm_network_interface_security_group_association" "tech501" {
  network_interface_id      = azurerm_network_interface.tech501.id
  network_security_group_id = azurerm_network_security_group.tech501.id
}

# Virtual Machine from Custom Image
resource "azurerm_linux_virtual_machine" "tech501" {
  name                  = var.app_vm_name
  resource_group_name   = data.azurerm_resource_group.tech501.name
  location              = data.azurerm_resource_group.tech501.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.tech501.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path) # Update with your actual SSH key file path
  }

  os_disk {
    caching              = var.disk_caching
    storage_account_type = var.disk_storage_account_type
  }

  # Reference the existing custom image for deployment
  source_image_id = var.app_source_image_id

  disable_password_authentication = true

  custom_data = base64encode(<<-EOF
  #!/bin/bash
  pm2 status
  cd /repo/app
  pm2 start app.js
  EOF
  )
}

# Output VM Public IP
output "vm_public_ip" {
  value       = azurerm_public_ip.tech501.ip_address
  description = "Public IP address of the VM"
}
