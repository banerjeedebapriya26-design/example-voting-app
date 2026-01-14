terraform {
  backend "azurerm" {
    resource_group_name  = "docker-demoapp-rg"
    storage_account_name = "dockerdemoappstorage123"
    container_name       = "docker-demoapp-tfstate-container"
    key                  = "tf/terraform.dockersampleapp"
  }
}