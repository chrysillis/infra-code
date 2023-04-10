output "public_ip_address" {
  value = azurerm_windows_virtual_machine.vm.public_ip_address
}

output "domain_name_label" {
  value = azurerm_public_ip.publicip.domain_name_label
}

output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.vm.admin_password
}