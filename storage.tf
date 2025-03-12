
resource "azurerm_storage_account" "training_storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type

  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

output "storage_account_name" {
  value = azurerm_storage_account.training_storage.name
}

output "storage_account_primary_location" {
  value = azurerm_storage_account.training_storage.primary_location
}

output "storage_account_primary_endpoint" {
  value = azurerm_storage_account.training_storage.primary_blob_endpoint
}


//ML LabelUI

module "ml_label_ui" {
  source                           = "git@github.com:melanin-luxe/ml-terraform-modules.git//blob-storage?ref=v0.0.3"
  storage_account_name             = var.ml_label_ui_storage_account_name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  storage_account_tier             = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
}
