# Provider and version constraints for utl-generate-dlp-tfvars utility
#
# Utility modules operate standalone and include backend blocks for independent execution.
#
# Baseline Requirements:
# - Terraform: >= 1.5.0 (consistent with repository baseline)
# - Provider: microsoft/power-platform ~> 3.8 (centralized version standard)
# - Provider: hashicorp/local ~> 2.4 (for file generation)
# - Backend: Azure Storage with OIDC (keyless authentication)

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

  # Azure backend with OIDC for secure state management
  backend "azurerm" {
    use_oidc = true
  }
}

# Provider configuration using OIDC authentication
provider "powerplatform" {
  use_oidc = true
}