locals {
  ip_rules = concat([
    for k, v in local.cidrs : k if v != 0
    ], [
    // Adding TFC IPs
    "75.2.98.97", "99.83.150.238"
  ])
}

resource "azurerm_storage_account" "files" {
  name                     = "stgpackerfilesfw"
  resource_group_name      = azurerm_resource_group.files.name
  location                 = azurerm_resource_group.files.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = local.ip_rules
    virtual_network_subnet_ids = []
  }
}

resource "azurerm_storage_container" "files" {
  name                  = "stgcontainer-packer-files"
  storage_account_name  = azurerm_storage_account.files.name
  container_access_type = "private"
}
