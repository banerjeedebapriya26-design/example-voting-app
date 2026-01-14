terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.47.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}
provider "azurerm" {
  # Configuration options
  features {
  }
}