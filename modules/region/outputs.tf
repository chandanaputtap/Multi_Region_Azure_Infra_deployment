output "public_ip" {
  value = module.vm.public_ip
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "vm_id" {
  value = module.vm.vm_id
}