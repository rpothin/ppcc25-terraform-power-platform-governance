# Provider and version constraints for ptn-azure-vnet-extension pattern
#
# Pattern modules orchestrate multiple resource modules and include provider/backend blocks
# as root modules following AVM specification PMNFR2.
#
# Baseline Requirements:
# - Terraform: >= 1.5.0 (consistent with repository baseline)
# - Provider: microsoft/power-platform ~> 3.8 (centralized version standard)
# - Provider: hashicorp/azurerm ~> 4.0 (AVM-compatible version)
# - Provider: azure/azapi ~> 2.6 (for enterprise policies)
# - Backend: Azure Storage with OIDC (keyless authentication)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
      # Configuration aliases for multi-subscription deployment
      configuration_aliases = [azurerm.production]
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.6"
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

# Default provider for non-production environments
provider "azurerm" {
  use_oidc        = true
  subscription_id = var.non_production_subscription_id
  features {}
}

# Production provider for production workloads
provider "azurerm" {
  alias           = "production"
  use_oidc        = true
  subscription_id = var.production_subscription_id
  features {}
}

# Azure API provider for enterprise policies
provider "azapi" {
  use_oidc = true
}