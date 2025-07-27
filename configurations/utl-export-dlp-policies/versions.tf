# Version and Provider Requirements for utl-export-dlp-policies
#
# This file pins the Terraform and provider versions for reproducibility and AVM compliance.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }

  backend "azurerm" {
    use_oidc = true
  }
}

provider "powerplatform" {
  use_oidc = true
}
