# Provider and version constraints for ptn-azure-vnet-extension
#
# This file defines the required Terraform and provider versions for the dual VNet extension pattern
# following AVM standards with multi-cloud provider integration.
#
# Key Requirements:
# - Provider Versions: Using centralized standards (~> 3.8 Power Platform, ~> 4.0 Azure RM)
# - OIDC Authentication: Secure, keyless authentication for all providers and backend
# - State Backend: Azure Storage with OIDC for secure, centralized state management
# - Dual Provider Support: Both Power Platform and Azure for VNet integration scenarios
#
# Pattern Context:
# - Root Module: Contains provider and backend blocks for pattern orchestration
# - Multi-Subscription: Supports production/non-production subscription deployment
# - Enterprise Policy: Enables Microsoft.PowerPlatform/enterprisePolicies deployment

terraform {
  # WHY: Terraform 1.9+ required for advanced validation and lifecycle features
  # CONTEXT: Pattern uses complex validation logic and sensitive variable handling
  # IMPACT: Ensures reliable dual VNet configuration validation and deployment
  required_version = ">= 1.5.0"

  required_providers {
    powerplatform = {
      source = "microsoft/power-platform"
      # WHY: Version ~> 3.8 provides stable Power Platform resource management
      # CONTEXT: Centralized version standard across all PPCC25 configurations
      # IMPACT: Enables consistent enterprise policy and environment integration
      version = "~> 3.8"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      # WHY: Version ~> 4.0 supports latest Azure VNet and enterprise policy features
      # CONTEXT: Required for dual region VNet deployment and private endpoint support
      # IMPACT: Enables production-ready network infrastructure provisioning
      version = "~> 4.0"
    }
  }

  # WHY: Azure backend with OIDC eliminates stored credentials security risk
  # CONTEXT: Enterprise environments require Zero Trust authentication patterns
  # IMPACT: Enables secure, auditable state management for sensitive infrastructure
  backend "azurerm" {
    use_oidc = true
  }
}

# WHY: OIDC authentication eliminates client secret management overhead
# CONTEXT: Power Platform governance requires secure, auditable API access
# IMPACT: Enables keyless authentication aligned with enterprise security standards
provider "powerplatform" {
  use_oidc = true
}

# WHY: OIDC authentication with features block enables secure Azure resource management
# CONTEXT: Dual VNet deployment requires Azure RM provider for network infrastructure
# IMPACT: Enables secure, multi-subscription Azure resource provisioning
provider "azurerm" {
  use_oidc = true
  features {}
}