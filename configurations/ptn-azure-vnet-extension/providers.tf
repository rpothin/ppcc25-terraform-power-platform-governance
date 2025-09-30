# ═══════════════════════════════════════════════════════════════════════════
# PROVIDER CONFIGURATION FOR AZURE VNET EXTENSION PATTERN
# ═══════════════════════════════════════════════════════════════════════════
#
# 🎯 PURPOSE:
# This pattern module creates Azure networking infrastructure for Power Platform
# managed environments and is deployed STANDALONE via GitHub Actions workflows,
# requiring explicit provider configuration.
#
# 🔒 DUAL AUTHENTICATION (Azure + Power Platform):
# This pattern requires BOTH Azure and Power Platform providers with OIDC.
#
# ⚙️ REQUIRED ENVIRONMENT VARIABLES:
# Set by GitHub Actions workflows (see .github/workflows/terraform-plan-apply.yml):
#
# Azure Provider:
#   - ARM_USE_OIDC=true
#   - ARM_CLIENT_ID (from GitHub secrets)
#   - ARM_TENANT_ID (from GitHub secrets)
#   - ARM_SUBSCRIPTION_ID (from GitHub secrets)
#
# Power Platform Provider:
#   - POWER_PLATFORM_USE_OIDC=true
#   - POWER_PLATFORM_CLIENT_ID (from GitHub secrets)
#   - POWER_PLATFORM_TENANT_ID (from GitHub secrets)
#
# 📚 EDUCATIONAL NOTE:
# This demonstrates hybrid governance scenarios where both Azure infrastructure
# and Power Platform resources must be managed together, using OIDC authentication
# for both providers following Zero Trust principles.
#
# ═══════════════════════════════════════════════════════════════════════════

provider "azurerm" {
  # WHY: Required for Azure networking resources (VNets, subnets, NSGs)
  features {}
  
  # OIDC authentication via environment variables:
  # - ARM_USE_OIDC=true
  # - ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}

provider "powerplatform" {
  # WHY: Required for Power Platform enterprise policy resources
  # OIDC authentication uses environment variables automatically
  
  # The provider detects OIDC configuration from environment variables:
  # - POWER_PLATFORM_USE_OIDC=true
  # - POWER_PLATFORM_CLIENT_ID
  # - POWER_PLATFORM_TENANT_ID
}
