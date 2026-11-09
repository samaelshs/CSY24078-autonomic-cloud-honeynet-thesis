terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate90e12837"
    container_name       = "tfstate"
    key                  = "honeynet.terraform.tfstate"
    use_azuread_auth     = true
  }
}