# ═══════════════════════════════════════════════════════════════════════════
# PROVIDER CONFIGURATION FOR ENVIRONMENT GROUP PATTERN
# ═══════════════════════════════════════════════════════════════════════════
#
# 🎯 PURPOSE:
# This pattern module orchestrates multiple child modules (res-environment-group,
# res-environment, res-environment-settings, res-environment-application-admin)
# and is deployed STANDALONE via GitHub Actions workflows, requiring explicit
# provider configuration that will be inherited by all child modules.
#
# 🔒 OIDC AUTHENTICATION (Zero Trust):
# - No stored credentials or client secrets
# - Token exchange via GitHub Actions OIDC
# - Temporary tokens with automatic expiration
#
# ⚙️ REQUIRED ENVIRONMENT VARIABLES:
# Set by GitHub Actions workflows (see .github/workflows/terraform-plan-apply.yml):
#   - POWER_PLATFORM_USE_OIDC=true
#   - POWER_PLATFORM_CLIENT_ID (from GitHub secrets)
#   - POWER_PLATFORM_TENANT_ID (from GitHub secrets)
#
# 🧩 CHILD MODULE INHERITANCE:
# All child modules called by this pattern (res-environment, res-environment-group,
# etc.) will automatically inherit this provider configuration. They do not need
# their own providers.tf files - that would violate AVM principles and prevent
# using for_each/count meta-arguments.
#
# 📚 EDUCATIONAL NOTE:
# This demonstrates:
# - Pattern module orchestration (calling multiple child modules)
# - Provider inheritance (parent provides, children inherit)
# - OIDC authentication (Zero Trust security model)
# - Infrastructure as Code governance patterns
#
# ═══════════════════════════════════════════════════════════════════════════

provider "powerplatform" {
  # WHY: No explicit configuration here
  # OIDC authentication uses environment variables automatically
  # This is the Zero Trust pattern: no secrets in code, only temporary tokens
  
  # The provider detects OIDC configuration from environment variables:
  # - POWER_PLATFORM_USE_OIDC triggers OIDC authentication
  # - POWER_PLATFORM_CLIENT_ID identifies the Azure AD application
  # - POWER_PLATFORM_TENANT_ID identifies the Azure AD tenant
  
  # Token exchange happens automatically with GitHub Actions
  
  # All child modules (res-environment, res-environment-group, etc.)
  # automatically inherit this provider configuration
}
