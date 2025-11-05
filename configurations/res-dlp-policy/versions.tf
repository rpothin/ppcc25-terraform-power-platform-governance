# Provider and version constraints for res-dlp-policy configuration
#
# === ARCHITECTURAL EXCEPTION: STANDALONE DEPLOYMENT PATTERN ===
# This res-* configuration includes backend and provider blocks to support direct deployment
# for PPCC25 demonstration purposes while maintaining child module compatibility.
#
# WHY: Demo scenarios require standalone res-dlp-policy deployment without pattern wrapper
# USAGE: Standalone deployment (with backend) OR as child module (backend overridden by parent)
# COMPLIANCE: Pragmatic approach balances AVM principles with demonstration requirements
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
# When used as child module, parent provider configuration takes precedence
provider "powerplatform" {
  use_oidc = true
}