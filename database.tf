

module "ml_label_pgsql" {
  source              = "git@github.com:melanin-luxe/ml-terraform-modules.git//pgsql?ref=v0.0.2"
  pg_server_name      = var.pg_server_name
  resource_group_name = azurerm_resource_group.rg.name
  rg_location         = azurerm_resource_group.rg.location
  pg_version          = var.pg_version
  pg_admin_username   = var.pg_admin_username
  pg_admin_password   = var.pg_admin_password
  pg_sku              = var.pg_sku
}


# Output database connection details
output "postgresql_server" {
  description = "PostgreSQL server hostname"
  value       = ml_label_pgsql.postgresql_server
}

output "database_name" {
  description = "Database name"
  value       = ml_label_pgsql.database_name
}
