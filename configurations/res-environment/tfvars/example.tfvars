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
  environment_group_id = "0675a2e2-dd4d-4ab6-8b9f-0d5048f62214" # REQUIRED: Azure AD group for governance

  # ⚙️ DEFAULT VALUES AUTOMATICALLY APPLIED:
  # environment_type = "Sandbox"        (lowest-privilege environment)
  # cadence = "Moderate"                (stable update cadence)
  # AI settings controlled by environment group rules
}

dataverse = {
  currency_code     = "USD"                                  # EXPLICIT CHOICE: Your organizational currency
  security_group_id = "6a199811-5433-4076-81e8-1ca7ad8ffb67" # REQUIRED: Azure AD group for data access

  # ⚙️ DEFAULT VALUES AUTOMATICALLY APPLIED:
  # language_code = 1033                (English US - most tested)
  # administration_mode_enabled = false (operational environments)
  # background_operation_enabled = true (enabled for initialization)
  # domain = auto-calculated from display_name
}

enable_duplicate_protection = false # Recommended for all environments

# ⚙️ MANAGED ENVIRONMENT GOVERNANCE (DEFAULT: ENABLED)
enable_managed_environment = true # Default: Enables governance features
# Managed environment configuration (optional: defaults provide secure governance)
# SIMPLIFIED PATTERN: Module uses battle-tested defaults
# Advanced configuration available in variables.tf for future enhancement
# managed_environment_settings = {} # Current approach - uses module defaults

# ======================================================================================
# Example 2: MANAGED ENVIRONMENT GOVERNANCE CONFIGURATION
# ======================================================================================
# Managed environments provide enhanced governance and control for Power Platform.
# This configuration enables solution validation, sharing controls, and maker guidance.

# environment = {
#   display_name         = "Governed Development Environment"
#   location             = "unitedstates"                         # EXPLICIT CHOICE
#   environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED for governance
#   description          = "Development environment with enhanced governance controls"
# }
# 
# dataverse = {
#   currency_code     = "USD"                                  # EXPLICIT CHOICE
#   security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED for data access
# }
# 
# enable_duplicate_protection = true
# enable_managed_environment  = true # Enable governance features
# 
# # Advanced managed environment configuration
# managed_environment_settings = {
#   sharing_settings = {
#     is_group_sharing_disabled = false    # Allow security group sharing
#     limit_sharing_mode        = "NoLimit" # Flexible sharing for development
#     max_limit_user_sharing    = -1       # Unlimited when group sharing enabled
#   }
#   usage_insights_disabled = true         # Reduce email notifications
#   solution_checker = {
#     mode                       = "Warn"    # Validate but don't block
#     suppress_validation_emails = true     # Reduce noise for developers
#   }
#   maker_onboarding = {
#     markdown_content = "Welcome to our governed environment. Please follow organizational guidelines."
#     learn_more_url   = "https://learn.microsoft.com/power-platform/"
#   }
# }

# ======================================================================================
# Example 3: ENVIRONMENT GROUP AI GOVERNANCE INFORMATION
# ======================================================================================
# AI capabilities are controlled through environment group rules, not individual 
# environment settings. This is handled at the environment group level:

# AI Settings (configured at environment group level):
# - bing_search_enabled: Controls Copilot Studio, Power Pages Copilot, Dynamics 365 AI
# - move_data_across_regions_enabled: Controls Power Apps AI, Power Automate Copilot, AI Builder
# - Individual environments inherit AI settings from their environment group

# environment = {
#   display_name         = "AI Development Sandbox"
#   location             = "unitedstates"                         # EXPLICIT CHOICE
#   environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED for governance
#   description          = "Development environment with AI via group governance"
# }
# 
# dataverse = {
#   currency_code     = "USD"                                  # EXPLICIT CHOICE
#   security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED for data access
# }
# 
# enable_duplicate_protection = true
# enable_managed_environment  = true # AI capabilities require managed environment
# managed_environment_settings = {}  # Simplified: Uses module defaults

# ======================================================================================
# Example 4: PRODUCTION ENVIRONMENT (Explicit Security Configuration)
# Use this pattern for production workloads with strict governance settings

# environment = {
#   display_name         = "Production Finance Environment"
#   location             = "unitedstates"                         # EXPLICIT CHOICE
#   environment_type     = "Production"                          # Override: Production environment
#   environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED for governance
#   description          = "Production environment with strict governance"
#   azure_region         = "eastus"                             # Specific Azure region for compliance
#   cadence              = "Moderate"                           # Stable updates for production
# }
# 
# dataverse = {
#   currency_code     = "USD"                                  # EXPLICIT CHOICE
#   security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED for data access
#   domain            = "contoso-prod"                         # Custom domain for branding
# }
# 
# enable_duplicate_protection = true  # Critical for production environments
# enable_managed_environment  = true  # REQUIRED for production governance
# 
# # Strict production governance settings
# managed_environment_settings = {
#   sharing_settings = {
#     is_group_sharing_disabled = true                  # Restrict sharing to security groups only
#     limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
#     max_limit_user_sharing    = 5                     # Limit individual user sharing
#   }
#   usage_insights_disabled = false                     # Enable monitoring for production
#   solution_checker = {
#     mode                       = "Block"               # Block invalid solutions
#     suppress_validation_emails = false                # Important notifications for production
#   }
#   maker_onboarding = {
#     markdown_content = "Welcome to Production! Please review development standards before creating solutions."
#     learn_more_url   = "https://contoso.com/powerplatform-guidelines"
#   }
# }

# ======================================================================================
# Example 5: EUROPEAN ENVIRONMENT (Localized Configuration)
# ======================================================================================
# Use this pattern for European organizations with localized requirements

# environment = {
#   display_name         = "European Development Environment"
#   location             = "europe"                            # EXPLICIT CHOICE: European region
#   environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED for governance
#   description          = "European environment with GDPR compliance"
#   azure_region         = "westeurope"                       # Specific European region
# }
# 
# dataverse = {
#   language_code     = 1031                                  # German (override default)
#   currency_code     = "EUR"                                 # EXPLICIT CHOICE: Euro currency
#   security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED for data access
#   domain            = "contoso-eu"                          # European domain naming
# }
# 
# enable_duplicate_protection = true
# enable_managed_environment  = true # GDPR compliance requires managed environment
# managed_environment_settings = {}  # Simplified: Uses module defaults for GDPR compliance

# ======================================================================================
# 🚨 IMPORTANT GOVERNANCE AND LIMITATIONS
# ======================================================================================
#
# ENVIRONMENT GROUP REQUIREMENT:
# - environment_group_id is now REQUIRED for proper Power Platform governance
# - Environment groups provide centralized governance for AI capabilities
# - Individual environments inherit AI settings from their environment group
# - Configure ai_generative_settings in the environment group resource
#
# MANAGED ENVIRONMENT GOVERNANCE:
# - enable_managed_environment defaults to true (recommended best practice)
# - Provides solution validation, sharing controls, and maker guidance
# - Required for enterprise governance and compliance scenarios
# - Automatically disabled for Developer environment types
#
# PROVIDER LIMITATIONS:
# - Developer environments are NOT SUPPORTED with service principal authentication
# - Only Sandbox, Production, and Trial environment types are supported
# - environment_group_id requires Dataverse configuration (provider constraint)
# - Managed environment features require proper resource module integration
#
# AI GOVERNANCE:
# AI capabilities are controlled through environment group rules:
# - bing_search_enabled: Controls Copilot Studio, Power Pages Copilot, Dynamics 365 AI
# - move_data_across_regions_enabled: Controls Power Apps AI, Power Automate Copilot, AI Builder
#
# 📚 Microsoft Documentation:
# - Environment Groups: https://learn.microsoft.com/power-platform/admin/environment-groups
# - Managed Environments: https://learn.microsoft.com/power-platform/admin/managed-environment-overview
# - AI Governance: https://learn.microsoft.com/power-platform/admin/geographical-availability-copilot
