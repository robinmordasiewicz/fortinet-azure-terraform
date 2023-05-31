resource "random_id" "resource_group" {
  count       = var.apply ? 1 : 0
  byte_length = 1
  prefix      = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  count    = var.apply ? 1 : 0
  location = var.resource_group_location
  name     = random_id.resource_group[count.index].id
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  count               = var.apply ? 1 : 0
  name                = "${random_id.resource_group[count.index].id}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  count                = var.apply ? 1 : 0
  name                 = "${random_id.resource_group[count.index].id}-subnet"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  count               = var.apply ? 1 : 0
  name                = "${random_id.resource_group[count.index].id}-publicip"
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  count               = var.apply ? 1 : 0
  name                = "${random_id.resource_group[count.index].id}-nsg"
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name

  security_rule {
    name                       = "SSH"
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

# Create network interface
resource "azurerm_network_interface" "nic" {
  count               = var.apply ? 1 : 0
  name                = "${random_id.resource_group[count.index].id}-nic"
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name

  ip_configuration {
    name                          = "network_configuration"
    subnet_id                     = azurerm_subnet.subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic_host_association" {
  count                     = var.apply ? 1 : 0
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
}

# Generate random text for a unique storage account name
resource "random_id" "storage_account" {
  count = var.apply ? 1 : 0
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg[count.index].name
  }
  prefix      = var.resource_group_name_prefix
  byte_length = 1
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage_account" {
  count                    = var.apply ? 1 : 0
  name                     = "${random_id.storage_account[count.index].hex}"
  location                 = azurerm_resource_group.rg[count.index].location
  resource_group_name      = azurerm_resource_group.rg[count.index].name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_private_key" {
  count     = var.apply ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  count                 = var.apply ? 1 : 0
  name                  = "${random_id.resource_group[count.index].id}-vm"
  location              = azurerm_resource_group.rg[count.index].location
  resource_group_name   = azurerm_resource_group.rg[count.index].name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${random_id.resource_group[count.index].id}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "${random_id.resource_group[count.index].id}-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_private_key[count.index].public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account[count.index].primary_blob_endpoint
  }
}
