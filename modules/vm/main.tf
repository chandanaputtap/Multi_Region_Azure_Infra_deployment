resource "azurerm_public_ip" "pip" {
  name = "${var.name}-pip"
  location = var.location
  resource_group_name = var.resource_group_name
  allocation_method = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name = "${var.name}-nic"
  location = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "ipconfig"
    subnet_id = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}



resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


data "azurerm_key_vault" "kv" {
  name                = "keyvault2-multiregion"             # your manually created Key Vault name
  resource_group_name = "keyvault-rg"                   # Key Vault's resource group
}

data "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"                # secret name in Key Vault
  key_vault_id = data.azurerm_key_vault.kv.id
}


resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.name}-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"
  
  # This deletes the OS disk when VM is deleted
  delete_os_disk_on_termination = true

  # This deletes all attached data disks when VM is deleted
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-${var.name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname-${var.name}"
    admin_username = "azureuser"
    admin_password = data.azurerm_key_vault_secret.vmpassword.value
    custom_data    = base64encode(<<EOF
#!/bin/bash
# Install Nginx
apt-get update
apt-get install -y nginx

# Create basic HTML page
echo "<html><head><title>Welcome</title></head><body><h1>Hello from Azure VM with Nginx!</h1></body></html>" > /var/www/html/index.html

# Restart Nginx
systemctl restart nginx
EOF
    )
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "QA"
  }
}
  
