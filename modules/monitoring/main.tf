
resource "random_string" "rand" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name != null ? var.log_analytics_workspace_name : "law-${random_string.rand.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_monitor_data_collection_rule" "linux_dcr" {
  name                = "linux-dcr-${substr(replace(var.workspace_name, "-", ""), 0, 10)}"
  location            = var.location
  resource_group_name = var.resource_group_name

   data_sources {
    syslog {
      name           = "syslogDataSource"
      facility_names = ["auth", "authpriv", "daemon", "user"]
      log_levels     = ["Emergency", "Alert", "Critical", "Error", "Warning", "Notice", "Info", "Debug"]
      streams        = ["Microsoft-Syslog"]
    }
  }

  destinations {
    log_analytics {
      name                  = "laDestination"
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["laDestination"]
  }
}
resource "azurerm_monitor_data_collection_rule_association" "vm_association" {
  for_each               = var.vm_ids

  name                   = "dcr-association-${each.key}"
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux_dcr.id
  target_resource_id      = each.value
}

resource "azurerm_virtual_machine_extension" "monitor_agent" {
  for_each                  = var.vm_ids
  name                      = "AzureMonitorLinuxAgent-${each.key}"
  virtual_machine_id        = each.value
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorLinuxAgent"
  type_handler_version      = "1.13"
  auto_upgrade_minor_version = true
}


resource "azurerm_monitor_diagnostic_setting" "frontdoor_diagnostics" {
  
  for_each = var.frontdoor_resources

  name                       = "frontdoor-diagnostics-${each.key}"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
  }

  enabled_log {
    category = "FrontdoorAccessLog"
  }
  
  
}
