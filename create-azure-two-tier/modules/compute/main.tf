resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [var.network_interface_id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path)
  }

  os_disk {
    caching              = var.disk_caching
    storage_account_type = var.disk_storage_type
  }

  source_image_id = var.app_source_image_id

  disable_password_authentication = true

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Add your custom initialization script here
    EOF
  )
}
