resource "azurerm_cdn_frontdoor_profile" "frontdoorprofile" {
  name                = var.frontend_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "frontdoorendpoint" {
  name                     = "${var.frontend_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoorprofile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = "origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoorprofile.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    interval_in_seconds = 120
    path                = "/"
    protocol            = "Http"
    request_type        = "GET"
  }
}

resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each = var.backend_ips


  name                          = "origin-${each.key}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                        = true
  host_name                     = each.value
  certificate_name_check_enabled = true
  http_port                     = 80
  https_port                    = 443
  
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "${var.frontend_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontdoorendpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids      = [for origin in azurerm_cdn_frontdoor_origin.origins : origin.id]
  cdn_frontdoor_rule_set_ids    = []

  supported_protocols           = ["Http"]  # Only HTTP
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpOnly"  # Use HTTP for forwarding
  https_redirect_enabled        = false       # Disable HTTPS redirect
  enabled                       = true
}


