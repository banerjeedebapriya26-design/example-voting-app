# Testing PR check 2
# 1. Create a Resource Group 
data "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
}


# 2. Create the AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "myakscluster"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.env
  }
}

# 4. Output the Cluster Name
output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

# 5. Create the Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "dockerdemoacrname123" # Must be globally unique
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Standard" # Cheapest option for free tier/testing
  admin_enabled       = true
}

# 6. ATTACH ACR TO AKS (The "AcrPull" Role)
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
}

# 2. Assign "Contributor" to the Service Principal
resource "azurerm_role_assignment" "sp_acr_contributor" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
  principal_id         = "bef7f77c-681e-4be7-a4b4-16b89f53c9eb" 
}

# 3. Assign "AcrPush" to the Service Principal (For GitHub Actions Build)
resource "azurerm_role_assignment" "sp_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = "bef7f77c-681e-4be7-a4b4-16b89f53c9eb"
}