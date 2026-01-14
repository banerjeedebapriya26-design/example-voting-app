# 1. Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

#### commenting out storage account creation as tfstate backend is already created
# 2. Creation of storage account to store tfstate
module "storage_account" {
  source = "./module/storage_account"
  prefix = var.prefix
  env = var.env
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# # 2. Create the AKS Cluster
# resource "azurerm_kubernetes_cluster" "aks" {
#   name                = "${var.prefix}-aks"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   dns_prefix          = "myakscluster"

#   default_node_pool {
#     name       = "default"
#     node_count = 1
#     vm_size    = var.vm_size
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   tags = {
#     Environment = var.env
#   }
# }

# # 4. Output the Cluster Name
# output "kubernetes_cluster_name" {
#   value = azurerm_kubernetes_cluster.aks.name
# }