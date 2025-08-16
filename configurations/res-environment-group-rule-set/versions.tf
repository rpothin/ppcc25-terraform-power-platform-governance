# Provider and version constraints for res-environment-group-rule-set
#
# This file defines the required Terraform and provider versions for the configuration
# following AVM standards with Power Platform provider adaptations.
#
# Key Requirements:
# - Provider Version: Using centralized standard ~> 3.8 for microsoft/power-platform
# - OIDC Authentication: Secure, keyless authentication for both provider and backend
# - State Backend: Azure Storage with OIDC for secure, centralized state management

terraform {
  # Version constraints ensure consistent behavior across environments
  required_version = ">= 1.5.0"

  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }

  # Azure backend with OIDC for secure, keyless authentication
  backend "azurerm" {
    use_oidc = true
  }
}

# Provider configuration using OIDC for enhanced security
provider "powerplatform" {
  use_oidc = true
}