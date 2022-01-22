##############################################################
# This module allows the creation of a Virtual Network
##############################################################

terraform {
  required_version = ">= 1.1.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.90.0"
    }
  }
}
