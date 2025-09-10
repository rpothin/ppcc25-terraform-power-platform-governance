# Example Environment Configuration for Power Platform Environment
#
# This file demonstrates the opinionated default values approach with multiple configuration patterns.
# Choose the example that best matches your use case and customize accordingly.
#
# ⚙️ OPINIONATED DEFAULT VALUES PHILOSOPHY:
# - Minimal explicit configuration required
# - Defaults align with Power Platform's actual behavior
# - Explicit choices for geographic/financial decisions
# - AI capabilities controlled by environment group governance

# ======================================================================================
# Example 1: MINIMAL CONFIGURATION (Recommended Starting Point)
# ======================================================================================
# This example uses opinionated default values - only requires explicit geographic choices

environment = {
  display_name         = "Secure Development Environment"       # Descriptive name
  location             = "unitedstates"                         # EXPLICIT CHOICE: Your geographic region
  environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED: Azure AD group for governance

  # ⚙️ DEFAULT VALUES AUTOMATICALLY APPLIED:
  # environment_type = "Sandbox"        (lowest-privilege environment)
  # cadence = "Moderate"                (stable update cadence)
  # AI settings controlled by environment group rules
}

dataverse = {
  currency_code     = "USD"                                  # EXPLICIT CHOICE: Your organizational currency
  security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED: Azure AD group for data access

  # ⚙️ DEFAULT VALUES AUTOMATICALLY APPLIED:
  # language_code = 1033                (English US - most tested)
  # administration_mode_enabled = false (operational environments)
  # background_operation_enabled = true (enabled for initialization)
  # domain = auto-calculated from display_name
}

enable_duplicate_protection = true # Recommended for all environments

# ======================================================================================
# Example 2: ENVIRONMENT GROUP AI GOVERNANCE INFORMATION
# ======================================================================================
# AI capabilities are now controlled through environment group rules, not individual 
# environment settings. Configure AI settings through your environment group's 
# ai_generative_settings rules:

# Environment Group AI Rules (configured separately):
# - bing_search_enabled: Controls Copilot Studio, Power Pages Copilot, Dynamics 365 AI
# - move_data_across_regions_enabled: Controls Power Apps AI, Power Automate Copilot, AI Builder

# environment = {
#   display_name         = "AI Development Sandbox"
#   location             = "unitedstates"            # EXPLICIT CHOICE
#   environment_group_id = "12345678-1234-1234-1234-123456789012"
#   description          = "Development environment with AI via group governance"
#   
#   # 🤖 AI CAPABILITIES CONTROLLED BY ENVIRONMENT GROUP:
#   # Individual environments inherit AI settings from their environment group
#   # Configure ai_generative_settings in the environment group resource
#   
#   # Other default values maintained:
#   # environment_type = "Sandbox"
#   # cadence = "Moderate"
# }
# 
# dataverse = {
#   currency_code     = "USD"                                  # EXPLICIT CHOICE
#   security_group_id = "87654321-4321-4321-4321-210987654321"
#   # Default values maintained for data protection
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
#   # 🔒 EXPLICIT SECURITY SETTINGS (Overriding platform defaults for enhanced security):
#   cadence                          = "Moderate"               # Stable updates for production
#   # AI settings controlled by environment group governance
# }
# 
# dataverse = {
#   currency_code                = "USD"                        # EXPLICIT CHOICE
#   security_group_id            = "87654321-4321-4321-4321-210987654321"
#   domain                       = "contoso-prod"               # Custom domain for branding
#   administration_mode_enabled  = false                       # Using Power Platform default (operational)
#   background_operation_enabled = true                        # Using Power Platform default (enabled)
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
#   # Default values maintained for European compliance:
#   # environment_type = "Sandbox"
#   # cadence = "Moderate"
#   # AI settings controlled by environment group governance (GDPR-compliant)
# }
# 
# dataverse = {
#   language_code     = 1031                                  # German (override default)
#   currency_code     = "EUR"                                 # EXPLICIT CHOICE: Euro currency
#   security_group_id = "87654321-4321-4321-4321-210987654321"
#   domain            = "contoso-eu"                          # European domain naming
#   
#   # Default values maintained:
#   # administration_mode_enabled = false
#   # background_operation_enabled = true
# }
# 
# enable_duplicate_protection = true

# ======================================================================================
# 🚨 AI GOVERNANCE THROUGH ENVIRONMENT GROUPS
# ======================================================================================
#
# AI capabilities are controlled through environment group rules, not individual settings.
# Configure these through your environment group's ai_generative_settings:
#
# AI Feature Requirements (Environment Group Rules):
# ┌─────────────────────────────────┬─────────────────────┬──────────────────────────────────┐
# │ AI Feature                      │ bing_search_enabled │ move_data_across_regions_enabled │
# ├─────────────────────────────────┼─────────────────────┼──────────────────────────────────┤
# │ Copilot Studio                  │ ✅ REQUIRED         │ ❌ Not Required                  │
# │ Power Pages Copilot             │ ✅ REQUIRED         │ ❌ Not Required                  │
# │ Dynamics 365 AI features        │ ✅ REQUIRED         │ ❌ Not Required                  │
# │ Power Apps AI (outside US/EU)   │ ❌ Not Required     │ ✅ REQUIRED                      │
# │ Power Automate Copilot          │ ❌ Not Required     │ ✅ REQUIRED                      │
# │ AI Builder (outside US/EU)      │ ❌ Not Required     │ ✅ REQUIRED                      │
# └─────────────────────────────────┴─────────────────────┴──────────────────────────────────┘
#
# Security Impact:
# - Environment groups provide centralized governance for AI capabilities
# - Individual environments inherit settings from their environment group
# - Eliminates conflicts between individual and group policies
# - Ensures consistent AI governance across organizational environments
#
# 📚 Microsoft Documentation:
# https://learn.microsoft.com/en-us/power-platform/admin/environment-groups
# https://learn.microsoft.com/en-us/power-platform/admin/geographical-availability-copilot
