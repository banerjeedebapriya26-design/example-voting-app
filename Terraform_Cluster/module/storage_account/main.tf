# 1. Create the Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = replace(lower("${var.prefix}storage123"), "-", "") # Must be unique
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.env
  }
}

# 2. Create the Container inside the Storage Account
resource "azurerm_storage_container" "container" {
  name                  = "${var.prefix}-tfstate-container"
  storage_account_id  = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# 3. Fetch the existing Service Principal by its Display Name
data "azuread_service_principal" "existing_sp" {
  display_name = "az-login-connection" # Replace with your SP's actual name
}

# 4. Assign the Storage Blob Data Contributor role
resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.existing_sp.object_id
}

# # 3. Helper to generate a unique name (Storage names are global)
# resource "random_string" "suffix" {
#   length  = 6
#   special = false
#   upper   = false
# }