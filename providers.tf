terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"

    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {

  }
  client_id       = "5c89092e-db2e-4c4e-a53e-676ccc751d02"
  client_secret   = "zFpSHVz-4Vq23q.jtL-0Li-xrpPpj_Q30_"
  subscription_id = "b59daaf5-a6ef-4435-8b81-a93b295f0565"
  tenant_id       = "81053e53-5440-4a33-bd01-b5ae1162c7db"
}