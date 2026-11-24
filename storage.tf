
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
  blob_properties {
    cors_rule {
      allowed_origins    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
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
  source                           = "git::https://github.com/tbrunoh/ml-terraform-modules.git//blob-storage?ref=v0.0.3"
  storage_account_name             = var.ml_label_ui_storage_account_name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  storage_account_tier             = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
}



module "ml_container_registry" {
  source      = "git::https://github.com/tbrunoh/ml-terraform-modules.git//container-registry?ref=v0.0.6"
  acr_name    = var.acr_name
  rg_name     = var.resource_group_name
  rg_location = var.location
  sku         = var.acr_sku
}

