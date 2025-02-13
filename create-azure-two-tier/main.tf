provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = var.resource_provider_registrations
}

# Look up the existing resource group
data "azurerm_resource_group" "tech501" {
  name = var.resource_group_name
}

# Create the shared VNet
module "vnet" {
  source              = "./modules/vnet"
  resource_group_name = data.azurerm_resource_group.tech501.name
  location            = data.azurerm_resource_group.tech501.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
}

### Application (App) Resources

module "network_app" {
  source              = "./modules/network"
  resource_group_name = data.azurerm_resource_group.tech501.name
  location            = data.azurerm_resource_group.tech501.location
  vnet_name           = module.vnet.vnet_name

  app_subnet_name    = var.app_subnet_name
  app_subnet_prefix  = var.app_subnet_address_prefix
  app_public_ip_name = var.app_public_ip_name
  app_nic_name       = var.app_nic_name
  nsg_name           = var.nsg_name
  is_public_subnet   = true
}

module "compute_app" {
  source               = "./modules/compute"
  resource_group_name  = data.azurerm_resource_group.tech501.name
  location             = data.azurerm_resource_group.tech501.location
  vm_name              = var.app_vm_name
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  ssh_key_path         = var.ssh_key_path
  app_source_image_id  = var.app_source_image_id
  disk_caching         = var.disk_caching
  disk_storage_type    = var.disk_storage_account_type
  network_interface_id = module.network_app.nic_id
  db_ip               = module.network_db.private_ip

  # Make it depend on the DB module
  depends_on = [
    module.compute_db
  ]
}

### Database (DB) Resources
# For any missing DB-specific compute variable (e.g., VM size, username), we reference the app variable.

module "network_db" {
  source              = "./modules/network"
  resource_group_name = data.azurerm_resource_group.tech501.name
  location            = data.azurerm_resource_group.tech501.location
  vnet_name           = module.vnet.vnet_name # Using the same VNet as app

  app_subnet_name    = var.db_subnet
  app_subnet_prefix  = var.db_subnet_address_prefix_db
  app_public_ip_name = var.db_public_ip
  app_nic_name       = var.db_nic
  nsg_name           = var.db_nsg
  is_public_subnet   = false
}

module "compute_db" {
  source               = "./modules/compute"
  resource_group_name  = data.azurerm_resource_group.tech501.name
  location             = data.azurerm_resource_group.tech501.location
  vm_name              = var.db_vm
  vm_size              = var.vm_size        # Referencing app vm size (no separate db_vm_size)
  admin_username       = var.admin_username # Referencing app admin_username
  ssh_key_path         = var.ssh_key_path   # Referencing app ssh_key_path
  app_source_image_id  = var.db_source_image_id
  disk_caching         = var.disk_caching              # Referencing app disk_caching
  disk_storage_type    = var.disk_storage_account_type # Referencing app disk_storage_account_type
  network_interface_id = module.network_db.nic_id
}
