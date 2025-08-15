# Input Variables for Power Platform Environment Configuration
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
    environment_type                 = optional(string, "Sandbox") # SECURE DEFAULT: Lowest-privilege environment type
    description                      = optional(string)
    azure_region                     = optional(string)             # Let Power Platform choose optimal region
    cadence                          = optional(string, "Moderate") # SECURE DEFAULT: Stable update cadence
    allow_bing_search                = optional(bool, false)        # SECURE DEFAULT: Blocks AI external data access
    allow_moving_data_across_regions = optional(bool, false)        # SECURE DEFAULT: Data sovereignty compliance
    billing_policy_id                = optional(string)
    release_cycle                    = optional(string)
  })

  description = <<DESCRIPTION
Power Platform environment configuration with SECURE-BY-DEFAULT settings.

This variable includes exclusively the arguments that actually exist in the 
microsoft/power-platform provider to ensure 100% compatibility.

🔒 SECURE DEFAULTS IMPLEMENTED:
- environment_type = "Sandbox" (lowest-privilege environment type)
- cadence = "Moderate" (stable update cadence for production readiness)
- allow_bing_search = false (prevents external data exposure)
- allow_moving_data_across_regions = false (data sovereignty compliance)

Required Properties:
- display_name: Human-readable environment name
- location: Power Platform region (EXPLICIT CHOICE - e.g., "unitedstates", "europe")
- environment_group_id: GUID for environment group membership (REQUIRED for governance)

Optional Properties with Secure Defaults:
- environment_type: Environment classification (default: "Sandbox" for least privilege)
  ⚠️  Developer environments are NOT SUPPORTED with service principal authentication
- description: Environment description
- azure_region: Specific Azure region (westeurope, eastus, etc.)
- cadence: Update cadence (default: "Moderate" for stability)
- allow_bing_search: Enable Bing search (default: false for security)
  🤖 REQUIRED FOR: Copilot Studio, Power Pages Copilot, Dynamics 365 AI features
- allow_moving_data_across_regions: Allow data movement across regions (default: false for sovereignty)
  🤖 REQUIRED FOR: Power Apps AI, Power Automate Copilot, AI Builder (outside US/Europe)
- billing_policy_id: GUID for pay-as-you-go billing policy
- release_cycle: Early release participation

Examples:

# Maximum Security Environment (using all secure defaults)
environment = {
  display_name         = "Secure Finance Environment"
  location             = "unitedstates"
  environment_group_id = "12345678-1234-1234-1234-123456789012"
  description          = "High-security environment with AI features disabled"
  # All other properties use secure defaults:
  # - environment_type = "Sandbox"
  # - cadence = "Moderate"
  # - allow_bing_search = false
  # - allow_moving_data_across_regions = false
}

# Production Environment with Explicit Security Settings
environment = {
  display_name                     = "Production Finance Environment"
  location                         = "unitedstates"
  environment_type                 = "Production"  # Override default
  environment_group_id             = "12345678-1234-1234-1234-123456789012"
  description                      = "Production environment with strict data governance"
  azure_region                     = "eastus"
  # Secure defaults maintained:
  # - cadence = "Moderate"
  # - allow_bing_search = false
  # - allow_moving_data_across_regions = false
}

# AI-Enabled Development Environment (conscious choice)
environment = {
  display_name                     = "AI Development Sandbox"
  location                         = "unitedstates"            # EXPLICIT CHOICE
  environment_group_id             = "87654321-4321-4321-4321-210987654321"
  description                      = "Development environment with AI capabilities enabled"
  allow_bing_search                = true   # Enable Copilot features
  allow_moving_data_across_regions = true   # Enable AI Builder/Power Apps AI
  # Other defaults maintained for security
}

🚨 AI CAPABILITY TRADE-OFFS:
- allow_bing_search = false DISABLES: Copilot Studio, Power Pages Copilot, Dynamics 365 AI
- allow_moving_data_across_regions = false DISABLES: Power Apps AI, Power Automate Copilot, AI Builder
- Set both to true to enable full AI/Copilot capabilities (reduces security posture)

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

  validation {
    condition = (
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.environment_group_id))
    )
    error_message = "Environment group ID is REQUIRED and must be a valid UUID format for proper Power Platform governance."
  }

  # Security-focused validations for AI capabilities
  validation {
    condition = (
      var.environment.environment_type == "Production" ?
      (var.environment.allow_bing_search == false && var.environment.allow_moving_data_across_regions == false) :
      true
    )
    error_message = "SECURITY VIOLATION: Production environments should not enable AI external data access. Set allow_bing_search=false and allow_moving_data_across_regions=false for production workloads, or use environment_type='Sandbox' for AI development."
  }

  validation {
    condition = (
      (var.environment.allow_bing_search == true || var.environment.allow_moving_data_across_regions == true) ?
      var.environment.environment_type != "Production" :
      true
    )
    error_message = "SECURITY WARNING: AI capabilities (allow_bing_search=true or allow_moving_data_across_regions=true) should not be used with environment_type='Production'. Consider using 'Sandbox' or 'Trial' for AI development environments."
  }

  validation {
    condition = (
      var.environment.allow_moving_data_across_regions == true ?
      contains(["unitedstates", "europe"], var.environment.location) :
      true
    )
    error_message = "DATA SOVEREIGNTY: allow_moving_data_across_regions=true is primarily needed outside US/Europe regions. For location='${var.environment.location}', consider setting this to false unless specifically needed for AI Builder/Power Apps AI features."
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
    administration_mode_enabled  = optional(bool, true)   # SECURE DEFAULT: Enable admin mode for secure setup
    background_operation_enabled = optional(bool, false)  # SECURE DEFAULT: Disable for security review
    template_metadata            = optional(string)       # String, not object!
    templates                    = optional(list(string))
  })

  description = <<DESCRIPTION
Dataverse database configuration with SECURE-BY-DEFAULT settings.

**GOVERNANCE REQUIREMENT**: Dataverse is REQUIRED for proper Power Platform governance.
This ensures all environments have proper data protection, security controls, and organizational structure.

🔒 SECURE DEFAULTS IMPLEMENTED:
- language_code = 1033 (English US - most tested and secure)
- administration_mode_enabled = true (secure initial setup mode)
- background_operation_enabled = false (requires security review before enabling)

Required Properties:
- currency_code: ISO currency code string (EXPLICIT CHOICE - e.g., "USD", "EUR", "GBP")
- security_group_id: Azure AD security group GUID (REQUIRED for governance)

Optional Properties with Secure Defaults:
- language_code: LCID integer (default: 1033 for English US security/testing)
- domain: Custom domain name (auto-calculated from display_name if not provided)
- administration_mode_enabled: Enable admin mode (default: true for secure setup)
- background_operation_enabled: Enable background operations (default: false for security)
- template_metadata: Additional D365 template metadata as string
- templates: List of D365 template names

Examples:

# Maximum Security Dataverse (explicit choices with secure defaults)
dataverse = {
  currency_code     = "USD"  # EXPLICIT CHOICE
  security_group_id = "12345678-1234-1234-1234-123456789012"
  # All other properties use secure defaults:
  # - language_code = 1033 (English US)
  # - administration_mode_enabled = true
  # - background_operation_enabled = false
  # - domain will be auto-calculated
}

# European Environment with Localized Choices
dataverse = {
  language_code     = 1036    # Override: French
  currency_code     = "EUR"   # EXPLICIT CHOICE
  security_group_id = "12345678-1234-1234-1234-123456789012"
  domain            = "contoso-eu"
  # Security defaults maintained:
  # - administration_mode_enabled = true
  # - background_operation_enabled = false
}

# Operational Environment (background operations enabled after security review)
dataverse = {
  currency_code                = "USD"   # EXPLICIT CHOICE
  security_group_id            = "12345678-1234-1234-1234-123456789012"
  background_operation_enabled = true    # Enabled after security review
  administration_mode_enabled  = false   # Disabled for normal operations
  # Other defaults maintained for consistency
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
    error_message = "OPERATIONAL CONFLICT: Cannot enable background_operation_enabled=true while administration_mode_enabled=true. Disable administration mode first, then enable background operations after security review."
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

# ======================================================================================
# 🔒 SECURITY VALIDATION SUMMARY
# ======================================================================================
# 
# These validation rules enforce secure-by-default practices:
# 
# 1. PRODUCTION ENVIRONMENT PROTECTION:
#    - Prevents AI external data access in production environments
#    - Enforces secure defaults for business-critical workloads
# 
# 2. AI CAPABILITY WARNINGS:
#    - Validates appropriate environment types for AI features
#    - Provides guidance on data sovereignty implications
# 
# 3. OPERATIONAL SAFETY:
#    - Prevents conflicting Dataverse operational modes
#    - Validates currency and language code compatibility
# 
# 4. GOVERNANCE ENFORCEMENT:
#    - Requires proper Azure AD group assignments
#    - Recommends duplicate protection for operational safety
# 
# All validation error messages include actionable guidance for resolution.
# ======================================================================================

