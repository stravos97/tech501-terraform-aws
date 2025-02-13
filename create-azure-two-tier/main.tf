provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = var.resource_provider_registrations
}

# Look up the existing resource group
data "azurerm_resource_group" "tech501" {
  name = var.resource_group_name
}

module "network" {
  source = "./modules/network"

  # Pass in values from the root module or data sources
  resource_group_name      = data.azurerm_resource_group.tech501.name
  location                 = data.azurerm_resource_group.tech501.location
  vnet_name                = var.vnet_name
  vnet_address_space       = var.vnet_address_space
  app_subnet_name          = var.app_subnet_name
  app_subnet_prefix        = var.app_subnet_address_prefix
  app_public_ip_name       = var.app_public_ip_name
  app_nic_name             = var.app_nic_name
  nsg_name                 = var.nsg_name
}

module "compute" {
  source = "./modules/compute"

  resource_group_name   = data.azurerm_resource_group.tech501.name
  location              = data.azurerm_resource_group.tech501.location
  vm_name               = var.app_vm_name
  vm_size               = var.vm_size
  admin_username        = var.admin_username
  ssh_key_path          = var.ssh_key_path
  app_source_image_id   = var.app_source_image_id
  disk_caching          = var.disk_caching
  disk_storage_type     = var.disk_storage_account_type
  network_interface_id  = module.network.nic_id  # From the network module
}
