variable "workspace_name" {
  type = string
}

variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}

variable "vm_ids" {
  type        = map(string)
  description = "Map of VM names to VM IDs"
}


variable "frontdoor_id" {
  type    = string
  default = null
}


variable "log_analytics_workspace_name" {
  type    = string
  default = null
}

variable "frontdoor_resources" {
  type    = map(string)
  default = {}
  description = "Map of frontdoor resource names to their IDs. Empty map means no Front Door diagnostic settings."
}



