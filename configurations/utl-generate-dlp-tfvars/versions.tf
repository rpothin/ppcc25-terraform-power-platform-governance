# Version and Provider Requirements (AVM Standard)
#
# Pins Terraform and provider versions for reproducibility and AVM compliance.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  backend "azurerm" {}
}

# OIDC authentication is enforced for all provider operations (security best practice)
provider "powerplatform" {
  use_oidc = true
}