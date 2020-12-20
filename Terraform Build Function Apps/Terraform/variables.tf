variable "storage_account_spec" {
  description = "map of key-values for the storage account object. See main.tf for valid keys"
  type        = map
  default     = {}
}

variable "service_plan_spec" {
  description = "map of key-values for the service plan object. See main.tf for valid keys"
  type        = map
  default     = {}
}

variable "function_app_spec" {
  description = "map of key-values for the function app object. See main.tf for valid keys"
  type        = map
  default     = {}
}

variable "tenant_id" {
  default = "55a2cce8-d900-42d4-b6d9-0f7acfaae386"
}