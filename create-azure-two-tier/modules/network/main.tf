# Create a subnet in the existing VNet
resource "azurerm_subnet" "subnet" {
  name                 = var.app_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.app_subnet_prefix]
}

# Create a public IP if this is a public subnet
resource "azurerm_public_ip" "public_ip" {
  count               = var.is_public_subnet ? 1 : 0
  name                = var.app_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
}

# Create a network interface
resource "azurerm_network_interface" "nic" {
  name                = var.app_nic_name
  resource_group_name = var.resource_group_name
  location            = var.location

  depends_on = [azurerm_network_security_group.nsg]

  lifecycle {
    create_before_destroy = true
  }

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.is_public_subnet ? azurerm_public_ip.public_ip[0].id : null
  }
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
  location            = var.location

  lifecycle {
    create_before_destroy = true
  }

  dynamic "security_rule" {
    for_each = var.is_public_subnet ? [1] : []
    content {
      name                       = "AllowSSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.is_public_subnet ? [1] : []
    content {
      name                       = "AllowHTTP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.is_public_subnet ? [] : [1]
    content {
      name                       = "AllowPort3000"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000"
      source_address_prefix      = var.app_subnet_prefix
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.is_public_subnet ? [] : [1]
    content {
      name                       = "AllowSSHFromAppSubnet"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.app_subnet_prefix
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.is_public_subnet ? [] : [1]
    content {
      name                       = "AllowMongoDBInbound"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "27017"
      source_address_prefix      = var.app_subnet_prefix
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.is_public_subnet ? [] : [1]
    content {
      name                       = "AllowMongoDBOutbound"
      priority                   = 1003
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "27017"
      source_address_prefix      = "*"
      destination_address_prefix = var.app_subnet_prefix
    }
  }
}

# Associate NSG with the network interface
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    azurerm_network_interface.nic,
    azurerm_network_security_group.nsg
  ]
}

# Add a null_resource to handle NSG disassociation
resource "null_resource" "nsg_cleanup" {
  triggers = {
    nic_id = azurerm_network_interface.nic.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az network nic update --ids ${self.triggers.nic_id} --remove networkSecurityGroup || true"
  }

  depends_on = [
    azurerm_network_interface_security_group_association.nic_nsg_association
  ]
}
