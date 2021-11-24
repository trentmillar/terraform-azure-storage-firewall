terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 2.1"
    }
  }
}

provider "azurerm" {
  features {}
}
