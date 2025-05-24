resource "random_string" "rand" {
  length  = 6
  upper   = false
  special = false
}

module "eastus" {
  source = "./modules/region"
  region = "eastus"
  name   = "eastus"
}

module "canadacentral" {
  source = "./modules/region"
  region = "canadacentral"
  name   = "canadacentral"
}

module "frontdoor" {
  source              = "./modules/frontdoor"
 backend_ips = {
  "canadacentral" = module.canadacentral.public_ip
  "eastus"        = module.eastus.public_ip
}

  frontend_name       = "frontend-${random_string.rand.result}"
  resource_group_name = module.eastus.resource_group_name
  location            = module.eastus.location
}

module "monitoring" {
  source              = "./modules/monitoring"
  location            = module.eastus.location
  resource_group_name = module.eastus.resource_group_name
  vm_ids              = {
    "canadacentral" = module.canadacentral.vm_id
    "eastus" = module.eastus.vm_id
  }

  frontdoor_resources = {
    "frontdoor_id"       = module.frontdoor.frontdoor_id
  }

  workspace_name = "multiregionlaw-${random_string.rand.result}"
}
