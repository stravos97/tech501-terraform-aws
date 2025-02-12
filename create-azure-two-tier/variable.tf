# Resource Group and Subscription Variables
variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
  default     = "tech501"
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
  default     = "cd36dfff-6e85-4164-b64e-b4078a773259"
}

# Network Variables
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "tech501-haashim-subnet-vnet"
}

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "tech501-haashim-subnet"
}

variable "app_subnet_address_prefix" {
  description = "Address prefix for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_public_ip_name" {
  description = "Name of the public IP"
  type        = string
  default     = "tech501-haashim-vm-public-ip"
}

variable "app_nic_name" {
  description = "Name of the network interface"
  type        = string
  default     = "tech501-haashim-vm-nic"
}

# Virtual Machine Variables
variable "app_vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "tech501-haashim-first-deploy-app-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "app_source_image_id" {
  description = "ID of the custom image"
  type        = string
  default     = "/subscriptions/cd36dfff-6e85-4164-b64e-b4078a773259/resourceGroups/tech501/providers/Microsoft.Compute/images/tech501-haashim-ready-to-run-app-vm-img"
}

# Storage and Disk Variables
variable "disk_caching" {
  description = "Caching for the managed disk"
  type        = string
  default     = "ReadWrite"
}

variable "disk_storage_account_type" {
  description = "Type of storage account"
  type        = string
  default     = "Standard_LRS"
}

# Authentication Variables
variable "ssh_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Provider Variables
variable "resource_provider_registrations" {
  description = "Resource provider registrations"
  type        = string
  default     = "none"
}
