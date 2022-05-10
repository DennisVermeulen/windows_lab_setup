
 resource "azurerm_resource_group" "rg" {
   name     = "rg-dv-mosadex"
   location = "westeurope"
 }
 resource "azurerm_virtual_network" "rg" {
   name                = "rg-mosadex-cursus"
   address_space       = ["10.0.0.0/16"]
   location            = azurerm_resource_group.rg.location
   resource_group_name = azurerm_resource_group.rg.name
 }
 resource "azurerm_subnet" "rg" {
   name                 = "internal"
   resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.rg.name
   address_prefixes     = ["10.0.2.0/24"]
 }
 resource "azurerm_public_ip" "rg" {
  count               = 1  
  name                = "mosadex-publicip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
 resource "azurerm_network_interface" "rg"{
   count               = 1  
   name                = "az-mosadex-nic-${count.index}"
   location            = azurerm_resource_group.rg.location
   resource_group_name = azurerm_resource_group.rg.name
 ip_configuration {
     name                          = "internal"
     subnet_id                     = azurerm_subnet.rg.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = azurerm_public_ip.rg["${count.index}"].id
   }
 }
 resource "azurerm_windows_virtual_machine" "virtualmachine" {
   count               = 1  
   name                = "az-mosadex-${count.index}"
   resource_group_name = azurerm_resource_group.rg.name
   location            = azurerm_resource_group.rg.location
   size                = "Standard_D8s_v3"
   admin_username      = "mosadex"
   admin_password      = "NPENA%+bb%Zp*v8c"
   network_interface_ids = [
     azurerm_network_interface.rg.*.id[count.index],
   ]
 os_disk {
     caching              = "ReadWrite"
     storage_account_type = "Standard_LRS"
   }
 source_image_reference {
     publisher = "MicrosoftWindowsDesktop"
     offer     = "Windows-10"
     sku       = "win10-21h2-entn-ltsc-g2"
     version   = "19044.1586.220303"
   }  
 }

resource "azurerm_virtual_machine_extension" "initvirtualmachine" {
  count               = 1  
  name                       = "initvirtualmachine"
  virtual_machine_id         = azurerm_windows_virtual_machine.virtualmachine["${count.index}"].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "fileUris": [
        "https://raw.githubusercontent.com/DennisVermeulen/windows_lab_setup/main/scripts/installs.ps1" \"master\"
      ]
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File installs.ps1"
    }
  PROTECTED_SETTINGS

}