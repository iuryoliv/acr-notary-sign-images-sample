terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.19.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.28.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.4.3"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "random_id" "main" {
  byte_length = 4
  prefix      = "notary-"
}

# southcentralus is the only region that supports signatures at this time.
resource "azurerm_resource_group" "example" {
  name     = "${random_id.main.hex}-rg"
  location = "southcentralus"
}

resource "azurerm_key_vault" "kv" {
  name                        = "${random_id.main.hex}-kv"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}

resource "azurerm_key_vault_access_policy" "currentUserAccesPolicy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id

  key_permissions = [
    "Get", "Sign"
  ]

  secret_permissions = [
    "Get", "Set", "List", "Delete", "Purge"
  ]

  certificate_permissions = [
    "Get", "Create", "Delete", "Purge", "List"
  ]
}

resource "azurerm_container_registry" "acr" {
  name                    = replace("${random_id.main.hex}acr","-","")
  resource_group_name     = azurerm_resource_group.example.name
  location                = azurerm_resource_group.example.location
  sku                     = "Premium"
  admin_enabled           = true
  zone_redundancy_enabled = true
}

resource "azurerm_key_vault_certificate" "signingCert" {
  name         = "example"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.3"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=example.com"
      validity_in_months = 12
    }
  }
    depends_on = [
    azurerm_key_vault_access_policy.currentUserAccesPolicy
  ]
}

