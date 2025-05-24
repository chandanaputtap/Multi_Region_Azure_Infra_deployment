output "frontdoor_endpoint_host" {
  value = azurerm_cdn_frontdoor_endpoint.frontdoorendpoint.host_name
}

output "frontdoor_id" {
  value = azurerm_cdn_frontdoor_profile.frontdoorprofile.id
}