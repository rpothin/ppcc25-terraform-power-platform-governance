# ═══════════════════════════════════════════════════════════════════════════
# PROVIDER CONFIGURATION FOR DLP POLICY MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════
#
# 🎯 PURPOSE:
# This configuration is deployed STANDALONE (not as a child module) via
# GitHub Actions workflows, so it requires explicit provider configuration.
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
# 📚 EDUCATIONAL NOTE:
# This demonstrates the transition from ClickOps (manual portal configuration
# with stored credentials) to Infrastructure as Code (automated deployment
# with OIDC authentication following Zero Trust security principles).
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
}
