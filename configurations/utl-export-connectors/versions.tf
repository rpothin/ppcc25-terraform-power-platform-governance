# Terraform Version and Provider Requirements for Export Power Platform Connectors Utility
#
# This file enforces version constraints and provider requirements for AVM compliance.

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
