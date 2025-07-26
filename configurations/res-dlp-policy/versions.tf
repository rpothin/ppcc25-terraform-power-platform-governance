# Version and Provider Requirements for res-dlp-policy
#
# This file pins the Terraform and provider versions for reproducibility and AVM compliance.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "powerplatform" {
  use_oidc = true
}
