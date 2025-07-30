terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatefastapi001"
    container_name       = "tfstate"
    key                  = "fastapi-aci.tfstate"
  }
}