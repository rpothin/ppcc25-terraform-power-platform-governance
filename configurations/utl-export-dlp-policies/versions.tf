# Provider and version constraints for utl-export-dlp-policies utility
#
# Utility modules operate standalone and include backend blocks for independent execution.
#
# Baseline Requirements:
# - Terraform: >= 1.5.0 (consistent with repository baseline)
# - Provider: microsoft/power-platform ~> 3.8 (centralized version standard)
# - Backend: Azure Storage with OIDC (keyless authentication)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }

  # Azure backend with OIDC for secure state management
  backend "azurerm" {
    use_oidc = true
  }
}

# Provider configuration using OIDC authentication
provider "powerplatform" {
  use_oidc = true
}
