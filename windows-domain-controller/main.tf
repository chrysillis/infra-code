terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
# Define the provider
provider "azurerm" {
  features {}
}
# Set the Azure region
resource "azurerm_resource_group" "rsg" {
  name     = var.resource_group_name
  location = var.resource_region
}
# Create a new virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${azurerm_resource_group.rsg.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rsg.location
  resource_group_name = azurerm_resource_group.rsg.name
}
# Create a new subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${azurerm_resource_group.rsg.name}-subnet"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rsg.name
}
# Create a new public IP address
resource "azurerm_public_ip" "publicip" {
  name                = "${azurerm_resource_group.rsg.name}-publicip"
  location            = azurerm_resource_group.rsg.location
  resource_group_name = azurerm_resource_group.rsg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${azurerm_resource_group.rsg.name}-dns"
}
# Create a new network interface
resource "azurerm_network_interface" "nic" {
  name                = "${azurerm_resource_group.rsg.name}-nic"
  location            = azurerm_resource_group.rsg.location
  resource_group_name = azurerm_resource_group.rsg.name

  ip_configuration {
    name                          = "ipconfig-default"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}
# Create a new network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "${azurerm_resource_group.rsg.name}-nsg"
  location            = azurerm_resource_group.rsg.location
  resource_group_name = azurerm_resource_group.rsg.name
  #Open port 3389 for RDP traffic
  security_rule {
    name                       = "allow-rdp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage" {
  name                     = "bootdiag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rsg.location
  resource_group_name      = azurerm_resource_group.rsg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
# Create a new virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.name}-DC-01"
  resource_group_name   = azurerm_resource_group.rsg.name
  location              = azurerm_resource_group.rsg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = random_password.password.result
  network_interface_ids = [azurerm_network_interface.nic.id]
  # Define the virtual machine boot settings
  os_disk {
    name                 = "${azurerm_resource_group.rsg.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 128
  }
  # Define the OS image to be used
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "windowsserver"
    sku       = var.os_image
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
  }
}
# Install the AD DS and DNS roles to the virtual machine
resource "azurerm_virtual_machine_extension" "roles_install" {
  name                       = "powershell"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name AD-Domain-Services, DNS –IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}
# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rsg.name
  }

  byte_length = 8
}
resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}
