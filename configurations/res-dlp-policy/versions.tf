# Provider and version constraints for res-dlp-policy module
#
# This file defines the required Terraform and provider versions for the DLP policy configuration
# following AVM standards with Power Platform provider adaptations.
#
# === ARCHITECTURAL EXCEPTION: DUAL-PURPOSE RESOURCE MODULE ===
# This res-* module includes backend and provider blocks to support standalone deployment
# for PPCC25 demonstration purposes while maintaining compatibility as a child module.
#
# WHY: Demo scenarios require direct deployment of res-dlp-policy without pattern wrapper
# USAGE: Can be used standalone (with backend) OR as child module (backend overridden by parent)
# COMPLIANCE: Pragmatic approach balances AVM principles with demonstration requirements
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
  # WHY: Prevents duplicate resource creation by maintaining state across deployments
  # SECURITY: Uses OIDC to eliminate stored credentials vulnerability
  # DEMO: Enables standalone deployment for PPCC25 live demonstrations
  backend "azurerm" {
    use_oidc = true
  }
}

# Provider configuration using OIDC for enhanced security
# WHY: Required for standalone deployment scenarios
# COMPATIBILITY: When used as child module, parent configuration takes precedence
provider "powerplatform" {
  use_oidc = true
}