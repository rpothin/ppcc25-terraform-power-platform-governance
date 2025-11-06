# Provider and version constraints for ptn-environment-group pattern
#
# Pattern modules orchestrate multiple resource modules and include provider/backend blocks
# as root modules following AVM specification PMNFR2.
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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
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