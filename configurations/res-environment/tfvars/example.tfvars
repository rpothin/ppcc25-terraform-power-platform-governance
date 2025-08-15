# Example Environment Configuration for Power Platform Environment
#
# This file demonstrates the SECURE-BY-DEFAULT approach with multiple configuration patterns.
# Choose the example that best matches your use case and customize accordingly.
#
# 🔒 SECURE DEFAULTS PHILOSOPHY:
# - Minimal explicit configuration required
# - Security-focused defaults for production readiness
# - Explicit choices for geographic/financial decisions
# - AI capabilities disabled by default (explicit enable required)

# ======================================================================================
# Example 1: MINIMAL SECURE CONFIGURATION (Recommended Starting Point)
# ======================================================================================
# This example uses maximum secure defaults - only requires explicit geographic choices

environment = {
  display_name         = "Secure Development Environment"       # Descriptive name
  location             = "unitedstates"                         # EXPLICIT CHOICE: Your geographic region
  environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED: Azure AD group for governance

  # 🔒 SECURE DEFAULTS AUTOMATICALLY APPLIED:
  # environment_type = "Sandbox"        (lowest-privilege environment)
  # cadence = "Moderate"                (stable update cadence)
  # allow_bing_search = false           (blocks external AI data access)
  # allow_moving_data_across_regions = false (data sovereignty compliance)
}

dataverse = {
  currency_code     = "USD"                                  # EXPLICIT CHOICE: Your organizational currency
  security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED: Azure AD group for data access

  # 🔒 SECURE DEFAULTS AUTOMATICALLY APPLIED:
  # language_code = 1033                (English US - most tested)
  # administration_mode_enabled = true  (secure setup mode)
  # background_operation_enabled = false (requires security review)
  # domain = auto-calculated from display_name
}

enable_duplicate_protection = true # Recommended for all environments

# ======================================================================================
# Example 2: AI-ENABLED DEVELOPMENT ENVIRONMENT (Security Trade-offs)
# ======================================================================================
# Use this pattern when you need AI/Copilot features (reduces security posture)

# environment = {
#   display_name                     = "AI Development Sandbox"
#   location                         = "unitedstates"            # EXPLICIT CHOICE
#   environment_group_id             = "12345678-1234-1234-1234-123456789012"
#   description                      = "Development environment with AI capabilities"
#   
#   # 🤖 AI CAPABILITIES ENABLED (Security Trade-offs):
#   allow_bing_search                = true   # Enables: Copilot Studio, Power Pages Copilot, Dynamics 365 AI
#   allow_moving_data_across_regions = true   # Enables: Power Apps AI, Power Automate Copilot, AI Builder
#   
#   # Other secure defaults maintained:
#   # environment_type = "Sandbox"
#   # cadence = "Moderate"
# }
# 
# dataverse = {
#   currency_code     = "USD"                                  # EXPLICIT CHOICE
#   security_group_id = "87654321-4321-4321-4321-210987654321"
#   # Secure defaults maintained for data protection
# }
# 
# enable_duplicate_protection = true

# ======================================================================================
# Example 3: PRODUCTION ENVIRONMENT (Explicit Security Configuration)
# ======================================================================================
# Use this pattern for production workloads with explicit security settings

# environment = {
#   display_name                     = "Production Finance Environment"
#   location                         = "unitedstates"            # EXPLICIT CHOICE
#   environment_type                 = "Production"              # Override: Production environment
#   environment_group_id             = "12345678-1234-1234-1234-123456789012"
#   description                      = "Production environment with strict governance"
#   azure_region                     = "eastus"                 # Specific Azure region for compliance
#   
#   # 🔒 EXPLICIT SECURITY SETTINGS (Documenting secure choices):
#   cadence                          = "Moderate"               # Stable updates for production
#   allow_bing_search                = false                    # Explicit: No external AI data access
#   allow_moving_data_across_regions = false                    # Explicit: Data sovereignty compliance
# }
# 
# dataverse = {
#   currency_code                = "USD"                        # EXPLICIT CHOICE
#   security_group_id            = "87654321-4321-4321-4321-210987654321"
#   domain                       = "contoso-prod"               # Custom domain for branding
#   administration_mode_enabled  = false                       # Override: Normal operations mode
#   background_operation_enabled = true                        # Override: Enabled after security review
# }
# 
# enable_duplicate_protection = true  # Critical for production environments

# ======================================================================================
# Example 4: EUROPEAN ENVIRONMENT (Localized Configuration)
# ======================================================================================
# Use this pattern for European organizations with localized requirements

# environment = {
#   display_name         = "European Development Environment"
#   location             = "europe"                            # EXPLICIT CHOICE: European region
#   environment_group_id = "12345678-1234-1234-1234-123456789012"
#   description          = "European environment with GDPR compliance"
#   azure_region         = "westeurope"                       # Specific European region
#   
#   # Secure defaults maintained for European compliance:
#   # environment_type = "Sandbox"
#   # cadence = "Moderate"
#   # allow_bing_search = false (GDPR-friendly)
#   # allow_moving_data_across_regions = false (Data residency compliance)
# }
# 
# dataverse = {
#   language_code     = 1031                                  # German (override default)
#   currency_code     = "EUR"                                 # EXPLICIT CHOICE: Euro currency
#   security_group_id = "87654321-4321-4321-4321-210987654321"
#   domain            = "contoso-eu"                          # European domain naming
#   
#   # Secure defaults maintained:
#   # administration_mode_enabled = true
#   # background_operation_enabled = false
# }
# 
# enable_duplicate_protection = true

# ======================================================================================
# 🚨 SECURITY DECISION MATRIX
# ======================================================================================
#
# AI Capability Requirements:
# ┌─────────────────────────────────┬───────────────────┬────────────────────────────────┐
# │ AI Feature                      │ allow_bing_search │ allow_moving_data_across_regions │
# ├─────────────────────────────────┼───────────────────┼────────────────────────────────┤
# │ Copilot Studio                  │ ✅ REQUIRED       │ ❌ Not Required                │
# │ Power Pages Copilot             │ ✅ REQUIRED       │ ❌ Not Required                │
# │ Dynamics 365 AI features        │ ✅ REQUIRED       │ ❌ Not Required                │
# │ Power Apps AI (outside US/EU)   │ ❌ Not Required   │ ✅ REQUIRED                    │
# │ Power Automate Copilot          │ ❌ Not Required   │ ✅ REQUIRED                    │
# │ AI Builder (outside US/EU)      │ ❌ Not Required   │ ✅ REQUIRED                    │
# └─────────────────────────────────┴───────────────────┴────────────────────────────────┘
#
# Security Impact:
# - allow_bing_search = true: Enables external data access to Microsoft Bing
# - allow_moving_data_across_regions = true: Allows data to leave your geographic region
# - Both settings reduce security posture and may impact compliance requirements
#
# 📚 Microsoft Documentation:
# https://learn.microsoft.com/en-us/power-platform/admin/geographical-availability-copilot
# https://learn.microsoft.com/en-us/power-platform/admin/cross-region-operations
