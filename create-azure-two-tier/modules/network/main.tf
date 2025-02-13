# Create a subnet in the existing VNet
resource "azurerm_subnet" "subnet" {
  name                 = var.app_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.app_subnet_prefix]
}

# Create a public IP
resource "azurerm_public_ip" "public_ip" {
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
    public_ip_address_id          = azurerm_public_ip.public_ip.id
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

  security_rule {
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

  security_rule {
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
