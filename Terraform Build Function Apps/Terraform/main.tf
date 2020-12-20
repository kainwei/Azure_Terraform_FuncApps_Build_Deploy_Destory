variable MAILPW {}

terraform {
  backend "azurerm" {
    resource_group_name   = "pysendmailtfstate"
    storage_account_name  = "pysendmailtfstateeit"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

locals {
  tags = {
    "terraform managed"   = "true"
    "terraform workspace" = terraform.workspace
  }
}


resource "azurerm_resource_group" "funcapp-pysendmail" {
  name     = "funcapp-pysendmail"
  location = "australiaeast"
  tags     = local.tags

}

resource "azurerm_storage_account" "storage_account" {
  name                      = substr(format("%ssa", lower(replace("${azurerm_resource_group.funcapp-pysendmail.name}${lookup(var.function_app_spec, "name", "function-app")}", "/[[:^alnum:]]/", ""))), 0, 24)
  resource_group_name       = azurerm_resource_group.funcapp-pysendmail.name
  location                  = azurerm_resource_group.funcapp-pysendmail.location
  account_tier              = lookup(var.storage_account_spec, "account_tier", "Standard")
  account_replication_type  = lookup(var.storage_account_spec, "account_replication_type", "LRS")
  enable_https_traffic_only = lookup(var.storage_account_spec, "enable_https_traffic_only", false)
  tags                      = local.tags
}

resource "azurerm_app_service_plan" "plan" {
  name                = "${azurerm_resource_group.funcapp-pysendmail.name}-${lookup(var.function_app_spec, "name", "function-app")}-plan"
  location            = azurerm_resource_group.funcapp-pysendmail.location
  resource_group_name = azurerm_resource_group.funcapp-pysendmail.name
  #kind                = lookup(var.service_plan_spec, "kind", "FunctionApp")
  kind                = "Linux"
  reserved            = true
  tags                = local.tags

  sku {
    tier     = lookup(var.service_plan_spec, "tier", "Dynamic")
    size     = lookup(var.service_plan_spec, "size", "Y1")
    capacity = lookup(var.service_plan_spec, "capacity", 0)
  }
}

resource "azurerm_function_app" "funcapp-pysendmail-app" {
  name = "funcapp-pysendmail-app"
  location                  = azurerm_resource_group.funcapp-pysendmail.location
  resource_group_name       = azurerm_resource_group.funcapp-pysendmail.name
  app_service_plan_id       = azurerm_app_service_plan.plan.id
  storage_connection_string = azurerm_storage_account.storage_account.primary_connection_string


  version = "~3"


  app_settings = {
     #mail_pass = azurerm_key_vault_secret.sendmail-kv-sec.value
     mail_pass_sec = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sendmail-kv-sec.id})"
     WEBSITE_RUN_FROM_PACKAGE = "1"
     FUNCTIONS_WORKER_RUNTIME = "python"
  }

  site_config {
    #linux_fx_version = "Python|3.8"
    ftps_state = "Disabled"
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_key_vault" "pysend-keyvault" {
  name = "sendmail-vault"
  location = azurerm_resource_group.funcapp-pysendmail.location
  resource_group_name = azurerm_resource_group.funcapp-pysendmail.name

  tenant_id = var.tenant_id
  sku_name = "standard"

  enabled_for_disk_encryption = true

}

resource "azurerm_key_vault_secret" "sendmail-kv-sec" {
  name      = "emailpass"
  value     = var.MAILPW
  key_vault_id = azurerm_key_vault.pysend-keyvault.id
  depends_on = [azurerm_key_vault_access_policy.kv-access-policy]
}

data "azurerm_client_config" "pysendmail" {}

resource "azurerm_key_vault_access_policy" "kv-access-policy" {
  key_vault_id = azurerm_key_vault.pysend-keyvault.id

  tenant_id = data.azurerm_client_config.pysendmail.tenant_id
  object_id = data.azurerm_client_config.pysendmail.object_id

  key_permissions = [
    "get",
    "update",
    "create",
    "delete",
    "list",
    "decrypt",
    "sign",
    "unwrapKey",
  ]

  secret_permissions = [
    "get",
    "set",
    "delete",
    "list",
    "purge",

  ]
}

resource "azurerm_key_vault_access_policy" "app-kv-access-policy" {
  key_vault_id = azurerm_key_vault.pysend-keyvault.id

  tenant_id = azurerm_function_app.funcapp-pysendmail-app.identity[0].tenant_id
  object_id = azurerm_function_app.funcapp-pysendmail-app.identity[0].principal_id

  key_permissions = [
    "get",
    "update",
    "create",
    "delete",
    "list",
    "decrypt",
    "sign",
    "unwrapKey",
  ]

  secret_permissions = [
    "get",
    "set",
    "delete",
    "list",
    "purge",

  ]

  certificate_permissions = [
    "get",
    "list",
  ]
}

provider "azurerm" {
  version = "=2.0.0"
  features {}
}