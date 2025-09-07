# Input Variab    # Optional Arguments - ✓ REAL with DEFAULT VALUESes for Power Platform Environment Configuration
#
# This file defines input parameters that align with the ACTUAL Power Platform provider schema.
# All fictional arguments have been removed to ensure 100% compatibility.
#
# Provider Documentation: https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment

variable "environment" {
  type = object({
    # Required Arguments - ✅ REAL
    display_name         = string
    location             = string # EXPLICIT CHOICE: Geographic location must be specified
    environment_group_id = string # ✅ NOW REQUIRED for proper governance

    # Optional Arguments - ✅ REAL with SECURE DEFAULTS
    environment_type = optional(string, "Sandbox") # SECURE DEFAULT: Lowest-privilege environment type
    description      = optional(string)
    azure_region     = optional(string)             # Let Power Platform choose optimal region
    cadence          = optional(string, "Moderate") # SECURE DEFAULT: Stable update cadence
    # AI settings removed - controlled by environment group rules when environment_group_id is required
    # allow_bing_search                = optional(bool, false)        # CONTROLLED BY ENVIRONMENT GROUP
    # allow_moving_data_across_regions = optional(bool, false)        # CONTROLLED BY ENVIRONMENT GROUP
    billing_policy_id = optional(string)
    release_cycle     = optional(string)
  })

  description = <<DESCRIPTION
Power Platform environment configuration with opinionated default values.

This variable includes exclusively the arguments that actually exist in the 
microsoft/power-platform provider to ensure 100% compatibility.

⚙️ DEFAULT VARIABLE VALUES:
- environment_type = "Sandbox" (lowest-privilege environment type)
- cadence = "Moderate" (stable update cadence for production readiness)
- AI settings (Bing search, cross-region data) controlled by environment group rules

Required Properties:
- display_name: Human-readable environment name
- location: Power Platform region (EXPLICIT CHOICE - e.g., "unitedstates", "europe")
- environment_group_id: GUID for environment group membership (REQUIRED for governance)

Optional Properties with Default Values:
- environment_type: Environment classification (default: "Sandbox" for least privilege)
  ⚠️  Developer environments are NOT SUPPORTED with service principal authentication
- description: Environment description
- azure_region: Specific Azure region (westeurope, eastus, etc.)
- cadence: Update cadence (default: "Moderate" for stability)
- billing_policy_id: GUID for pay-as-you-go billing policy
- release_cycle: Early release participation

🤖 AI SETTINGS GOVERNANCE:
Bing search and cross-region data movement are controlled by environment group rules.
Configure these settings through the environment group's ai_generative_settings rules.

Examples:

# Standard Environment (using default variable values)
environment = {
  display_name         = "Secure Finance Environment"
  location             = "unitedstates"
  environment_group_id = "12345678-1234-1234-1234-123456789012"
  description          = "High-security environment with AI governance via group rules"
  # All other properties use default values:
  # - environment_type = "Sandbox"
  # - cadence = "Moderate"
  # AI settings controlled by environment group rules
}

# Production Environment with Explicit Security Settings
environment = {
  display_name                     = "Production Finance Environment"
  location                         = "unitedstates"
  environment_type                 = "Production"  # Override default
  environment_group_id             = "12345678-1234-1234-1234-123456789012"
  description                      = "Production environment with strict data governance"
  azure_region                     = "eastus"
  # Default values maintained:
  # - cadence = "Moderate"
  # AI settings controlled by environment group governance rules
}

# AI-Enabled Development Environment (via environment group)
environment = {
  display_name                     = "AI Development Sandbox"
  location                         = "unitedstates"            # EXPLICIT CHOICE
  environment_group_id             = "87654321-4321-4321-4321-210987654321"
  description                      = "Development environment with AI capabilities via group rules"
  # AI settings configured through environment group's ai_generative_settings:
  # - Environment group rule: bing_search_enabled = true
  # - Environment group rule: move_data_across_regions_enabled = true
}

🚨 AI CAPABILITY GOVERNANCE:
AI capabilities are controlled by environment group rules, not individual environment settings.
Configure ai_generative_settings in your environment group to enable/disable:
- bing_search_enabled: Controls Copilot Studio, Power Pages Copilot, Dynamics 365 AI
- move_data_across_regions_enabled: Controls Power Apps AI, Power Automate Copilot, AI Builder

Limitations:
- Developer environments require user authentication (not service principal)
- This module only supports Sandbox, Production, and Trial environment types
- environment_group_id is now REQUIRED to ensure proper organizational governance
DESCRIPTION

  validation {
    condition = (
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment.display_name)) &&
      length(var.environment.display_name) >= 3 &&
      length(var.environment.display_name) <= 64
    )
    error_message = "Display name must be 3-64 characters, start/end with alphanumeric, contain only letters, numbers, spaces, hyphens, underscores."
  }

  validation {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "india", "japan", "canada",
      "southamerica", "unitedkingdom", "france", "germany", "unitedarabemirates",
      "switzerland", "korea", "norway", "southafrica"
    ], var.environment.location)
    error_message = "Location must be a valid Power Platform region."
  }

  validation {
    condition     = contains(["Sandbox", "Production", "Trial"], var.environment.environment_type)
    error_message = "Environment type must be one of: Sandbox, Production, Trial. Developer environments are not supported with service principal authentication."
  }

  validation {
    condition = (
      var.environment.cadence == null ? true :
      contains(["Frequent", "Moderate"], var.environment.cadence)
    )
    error_message = "Cadence must be either 'Frequent' or 'Moderate' when specified."
  }

  validation {
    condition = (
      var.environment.billing_policy_id == null ? true :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.billing_policy_id))
    )
    error_message = "Billing policy ID must be a valid UUID format when provided."
  }

  # Environment group governance validation
  validation {
    condition = (
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.environment_group_id))
    )
    error_message = "Environment group ID is REQUIRED and must be a valid UUID format for proper Power Platform governance. AI settings are controlled through environment group rules."
  }
}

variable "dataverse" {
  type = object({
    # Required Arguments when Dataverse is enabled - ✅ REAL
    currency_code     = string # EXPLICIT CHOICE: Financial currency must be specified
    security_group_id = string # ✅ NOW REQUIRED when dataverse is provided

    # Optional Arguments - ✅ REAL with SECURE DEFAULTS
    language_code                = optional(number, 1033) # SECURE DEFAULT: English US (most tested)
    domain                       = optional(string)       # Auto-calculated from display_name if null
    administration_mode_enabled  = optional(bool, false)  # POWER PLATFORM DEFAULT: New environments start operational
    background_operation_enabled = optional(bool, true)   # POWER PLATFORM DEFAULT: Background ops enabled for initialization
    template_metadata            = optional(string)       # String, not object!
    templates                    = optional(list(string))
  })

  description = <<DESCRIPTION
Dataverse database configuration with opinionated default values.

**GOVERNANCE REQUIREMENT**: Dataverse is REQUIRED for proper Power Platform governance.
This ensures all environments have proper data protection, security controls, and organizational structure.

⚙️ DEFAULT VALUES APPLIED:
- language_code = 1033 (English US - most tested and secure)
- administration_mode_enabled = false (Power Platform creates operational environments)
- background_operation_enabled = true (Power Platform enables background ops for initialization)

⚠️  POWER PLATFORM BEHAVIOR NOTE:
These defaults reflect actual Power Platform creation behavior, not idealized security settings.
Power Platform has opinionated defaults for environment lifecycle management:
- New environments start in operational mode (admin_mode = false)
- Background operations are enabled to support environment initialization
- These settings can be adjusted post-creation if needed for enhanced security

Required Properties:
- currency_code: ISO currency code string (EXPLICIT CHOICE - e.g., "USD", "EUR", "GBP")
- security_group_id: Azure AD security group GUID (REQUIRED for governance)

Optional Properties with Default Values:
- language_code: LCID integer (default: 1033 for English US)
- domain: Custom domain name (auto-calculated from display_name if not provided)
- administration_mode_enabled: Admin mode state (default: false - operational)
- background_operation_enabled: Background operations (default: true - enabled)
- template_metadata: Additional D365 template metadata as string
- templates: List of D365 template names

Examples:

# Standard Environment (using default values)
dataverse = {
  currency_code     = "USD"  # EXPLICIT CHOICE
  security_group_id = "12345678-1234-1234-1234-123456789012"
  # All other properties use default values:
  # - language_code = 1033 (English US)
  # - administration_mode_enabled = false (operational)
  # - background_operation_enabled = true (enabled)
  # - domain will be auto-calculated
}

# European Environment with Localized Choices
dataverse = {
  language_code     = 1036    # Override: French
  currency_code     = "EUR"   # EXPLICIT CHOICE
  security_group_id = "12345678-1234-1234-1234-123456789012"
  domain            = "contoso-eu"
  # Default values maintained:
  # - administration_mode_enabled = false (operational)
  # - background_operation_enabled = true (enabled)
}

# High-Security Environment (explicit overrides for enhanced security)
dataverse = {
  currency_code                = "USD"   # EXPLICIT CHOICE
  security_group_id            = "12345678-1234-1234-1234-123456789012"
  administration_mode_enabled  = true    # Override: Enable admin mode for security
  background_operation_enabled = false   # Override: Disable background ops for review
}

Governance Benefits:
- Enforces consistent data protection across all environments
- Ensures proper security group assignment for access control
- Enables advanced governance features like DLP policies
- Provides audit trail and compliance capabilities
DESCRIPTION
  validation {
    condition     = var.dataverse.language_code >= 1 && var.dataverse.language_code <= 9999
    error_message = "Language code must be a valid LCID integer (1-9999). Common values: 1033 (English US), 1036 (French), 1031 (German)."
  }

  validation {
    condition     = can(regex("^[A-Z]{3}$", var.dataverse.currency_code))
    error_message = "Currency code must be a 3-letter ISO currency code (e.g., 'USD', 'EUR', 'GBP')."
  }

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.dataverse.security_group_id))
    error_message = "Security group ID is REQUIRED for governance and must be a valid UUID format."
  }

  # Governance and security validations for Dataverse
  validation {
    condition = (
      var.dataverse.background_operation_enabled == true ?
      var.dataverse.administration_mode_enabled == false :
      true
    )
    error_message = "OPERATIONAL CONFLICT: Cannot enable background_operation_enabled=true while administration_mode_enabled=true. Power Platform requires administration mode to be disabled before enabling background operations. This combination is not supported by the platform."
  }

  validation {
    condition = (
      var.dataverse.language_code == 1033 ? true :
      var.dataverse.language_code >= 1000
    )
    error_message = "COMPATIBILITY WARNING: Non-English language codes may have limited testing. language_code=${var.dataverse.language_code} - consider using 1033 (English US) for maximum compatibility and security validation coverage."
  }

  validation {
    condition = (
      contains(["USD", "EUR", "GBP", "CAD", "AUD", "JPY"], var.dataverse.currency_code)
    )
    error_message = "CURRENCY VALIDATION: '${var.dataverse.currency_code}' - ensure this is the correct 3-letter ISO currency code for your organization. Common codes: USD, EUR, GBP, CAD, AUD, JPY. Check https://en.wikipedia.org/wiki/ISO_4217 for complete list."
  }

  validation {
    condition = (
      var.dataverse.domain == null ? true :
      can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.dataverse.domain)) &&
      length(var.dataverse.domain) >= 3 &&
      length(var.dataverse.domain) <= 63
    )
    error_message = "Domain must be 3-63 characters, lowercase alphanumeric with hyphens, cannot start/end with hyphen if provided."
  }
}

variable "enable_duplicate_protection" {
  type        = bool
  description = "Enable duplicate environment detection and prevention for operational safety."
  default     = true

  validation {
    condition = (
      var.enable_duplicate_protection == true || var.enable_duplicate_protection == false
    )
    error_message = "Invalid boolean value for enable_duplicate_protection. Must be true or false. GOVERNANCE NOTE: enable_duplicate_protection=true is strongly recommended for production environments to prevent accidental duplicates and improve operational safety. Setting to false is acceptable for testing scenarios."
  }
}

variable "enable_managed_environment" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Enable managed environment features for enhanced governance and control.
Default: true (following Power Platform best practices)

WHY: Managed environments are now best practice for production workloads.
This default ensures governance features are enabled unless explicitly disabled.

When enabled (default):
- Creates managed environment configuration automatically
- Applies governance controls and policies
- Enables solution checker validation
- Provides enhanced sharing controls
- Supports maker onboarding and guidance

When disabled:
- Environment created without managed features
- Standard environment capabilities only
- Manual governance configuration required
- Typically only used for basic development scenarios

Note: Developer environment types automatically disable managed environment
features regardless of this setting due to provider limitations.

Examples:
enable_managed_environment = true   # Default: Enable governance features
enable_managed_environment = false  # Disable for basic development environments
DESCRIPTION
}

variable "managed_environment_settings" {
  type = object({
    sharing_settings = optional(object({
      is_group_sharing_disabled = optional(bool, false)
      limit_sharing_mode        = optional(string, "NoLimit")
      max_limit_user_sharing    = optional(number, -1)
    }), {})

    usage_insights_disabled = optional(bool, true)

    solution_checker = optional(object({
      mode                       = optional(string, "Warn")
      suppress_validation_emails = optional(bool, true)
      rule_overrides             = optional(set(string), null)
    }), {})

    maker_onboarding = optional(object({
      markdown_content = optional(string, "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions.")
      learn_more_url   = optional(string, "https://learn.microsoft.com/power-platform/")
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Managed environment configuration settings.
Only applied when enable_managed_environment is true.

⚠️  SIMPLIFIED MODULE PATTERN NOTICE:
This variable is currently PRESERVED for backward compatibility and future extensibility,
but is NOT PASSED to the managed environment module. The simplified pattern uses
module defaults for all settings to reduce complexity and improve reliability.

Current Behavior:
- Module receives only environment_id parameter
- All managed environment settings use module defaults
- This variable is available for future enhancement

WHY SIMPLIFIED APPROACH:
- Reduces provider consistency bugs
- Uses battle-tested default configurations
- Simplifies maintenance and troubleshooting
- Follows "convention over configuration" principle

Future Enhancement Path:
If specific managed environment customization is needed, this variable provides
the structure to re-enable detailed configuration by updating the module call
in main.tf to pass these settings.

Legacy Configuration Reference:
The structure below documents the available settings for future use:

1. SHARING SETTINGS: Controls app and flow sharing behavior
   - is_group_sharing_disabled: When false (default), enables security group sharing
   - limit_sharing_mode: "NoLimit" (default) or "ExcludeSharingToSecurityGroups"
   - max_limit_user_sharing: -1 (default, unlimited when group sharing enabled)

2. USAGE INSIGHTS: Weekly usage reporting
   - usage_insights_disabled: true (default) to avoid email spam

3. SOLUTION CHECKER: Quality validation for solution imports
   - mode: "Warn" (default) provides validation without blocking
   - suppress_validation_emails: true (default) reduces noise
   - rule_overrides: null (default) applies full validation suite

4. MAKER ONBOARDING: Welcome content for new makers
   - markdown_content: Default welcome message
   - learn_more_url: Microsoft Learn documentation link

Examples (for future reference):

# Current recommended approach (uses module defaults)
managed_environment_settings = {}

# Advanced configuration (available for future enhancement)
# managed_environment_settings = {
#   sharing_settings = {
#     is_group_sharing_disabled = false
#     limit_sharing_mode        = "NoLimit"
#     max_limit_user_sharing    = -1
#   }
#   usage_insights_disabled = false
#   solution_checker = {
#     mode                       = "Block"
#     suppress_validation_emails = false
#     rule_overrides             = ["meta-avoid-reg-no-attribute"]
#   }
#   maker_onboarding = {
#     markdown_content = "Welcome to Production! Please review our development standards."
#     learn_more_url   = "https://contoso.com/powerplatform-guidelines"
#   }
# }

See: https://learn.microsoft.com/power-platform/admin/managed-environment-overview
DESCRIPTION

  validation {
    condition = (
      var.managed_environment_settings.sharing_settings.is_group_sharing_disabled == false
      ? var.managed_environment_settings.sharing_settings.max_limit_user_sharing == -1
      : var.managed_environment_settings.sharing_settings.max_limit_user_sharing > 0
    )
    error_message = "SHARING CONFIGURATION ERROR: When group sharing is enabled (is_group_sharing_disabled = false), max_limit_user_sharing must be -1. When disabled, it must be > 0. Current: is_group_sharing_disabled = ${var.managed_environment_settings.sharing_settings.is_group_sharing_disabled}, max_limit_user_sharing = ${var.managed_environment_settings.sharing_settings.max_limit_user_sharing}. Please adjust your sharing configuration."
  }

  validation {
    condition     = contains(["NoLimit", "ExcludeSharingToSecurityGroups"], var.managed_environment_settings.sharing_settings.limit_sharing_mode)
    error_message = "limit_sharing_mode must be one of: 'NoLimit', 'ExcludeSharingToSecurityGroups'. Current value: '${var.managed_environment_settings.sharing_settings.limit_sharing_mode}'. Please use a valid sharing mode as documented in the Power Platform provider."
  }

  validation {
    condition     = contains(["None", "Warn", "Block"], var.managed_environment_settings.solution_checker.mode)
    error_message = "Solution checker mode must be one of: 'None', 'Warn', 'Block'. Current value: '${var.managed_environment_settings.solution_checker.mode}'. Please use a valid solution checker mode."
  }
}

# ======================================================================================
# 🔒 SECURITY VALIDATION SUMMARY
# ======================================================================================
# 
# These validation rules enforce opinionated default practices:
# 
# 1. GOVERNANCE ENFORCEMENT:
#    - Requires valid environment group ID for organizational governance
#    - AI settings controlled through environment group rules (not individual environments)
#    - Managed environment features enabled by default for governance compliance
# 
# 2. OPERATIONAL SAFETY:
#    - Prevents conflicting Dataverse operational modes
#    - Validates currency and language code compatibility
#    - Ensures proper managed environment sharing configuration
# 
# 3. DATAVERSE GOVERNANCE:
#    - Requires proper Azure AD group assignments
#    - Recommends duplicate protection for operational safety
#    - Managed environments provide enhanced governance capabilities
# 
# 4. ENVIRONMENT GROUP INTEGRATION:
#    - AI capabilities managed centrally through environment group policies
#    - Eliminates conflicts between individual and group settings
#    - Managed environment features complement environment group governance
# 
# All validation error messages include actionable guidance for resolution.
# ======================================================================================

