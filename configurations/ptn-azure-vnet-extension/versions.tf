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
      # WHY: Balanced approach - use stable 3.x series with proven AVM compatibility
      # CONTEXT: AVM modules require 3.116+ but azurerm 4.x introduces breaking changes
      # IMPACT: Provides latest stable features while ensuring AVM module compatibility
      # STRATEGY: Pin to latest 3.x minor version for stability with security updates
      version = "~> 3.117"
      # WHY: Configuration aliases required for multi-subscription deployment
      # CONTEXT: AVM specification TFNFR27 compliant provider alias handling
      # IMPACT: Enables production/non-production subscription routing
      configuration_aliases = [azurerm.production]
    }
    azapi = {
      source = "azure/azapi"
      # WHY: Use latest stable 2.x series - mature API with active development
      # CONTEXT: Version 2.x is stable, 3.x is preview with potential breaking changes
      # IMPACT: Access to latest Azure preview APIs while maintaining stability
      # STRATEGY: Pin to latest 2.x minor version for new features with stability
      version = "~> 2.6"
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
# CONTEXT: Default provider for non-production environments (Dev, Test, Staging)
# IMPACT: Enables secure Azure resource provisioning for non-production workloads
provider "azurerm" {
  use_oidc        = true
  subscription_id = var.non_production_subscription_id
  features {}
}

# WHY: Production environments require dedicated subscription for governance
# CONTEXT: Production workloads deployed to separate subscription for isolation
# IMPACT: Enables proper subscription-level governance and cost management
provider "azurerm" {
  alias           = "production"
  use_oidc        = true
  subscription_id = var.production_subscription_id
  features {}
}

# WHY: azapi provider required for res-enterprise-policy module integration
# CONTEXT: Enterprise policy creation uses preview APIs requiring azapi resources
# IMPACT: Enables Microsoft.PowerPlatform/enterprisePolicies deployment
provider "azapi" {
  use_oidc = true
}