
terraform {
  backend "azurerm" {
    resource_group_name   = "pysendmailtfstate"
    storage_account_name  = "pysendmailtfstateeit"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

provider "azurerm" {
  version = "=2.0.0"
  features {}
}