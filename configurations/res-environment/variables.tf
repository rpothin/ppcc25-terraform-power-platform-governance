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
    location             = string
    environment_type     = string
    environment_group_id = string # ✅ NOW REQUIRED for proper governance

    # Optional Arguments - ✅ REAL
    description                      = optional(string)
    azure_region                     = optional(string)
    cadence                          = optional(string) # "Frequent" or "Moderate" only
    allow_bing_search                = optional(bool)
    allow_moving_data_across_regions = optional(bool)
    billing_policy_id                = optional(string)
    release_cycle                    = optional(string)
  })

  description = <<DESCRIPTION
Power Platform environment configuration using ONLY real provider arguments.

This variable includes exclusively the arguments that actually exist in the 
microsoft/power-platform provider to ensure 100% compatibility.

Required Properties:
- display_name: Human-readable environment name
- location: Power Platform region (e.g., "unitedstates", "europe")
- environment_type: Environment classification (Sandbox, Production, Trial)
  ⚠️  Developer environments are NOT SUPPORTED with service principal authentication
- environment_group_id: GUID for environment group membership (REQUIRED for governance)

Optional Properties:
- description: Environment description
- azure_region: Specific Azure region (westeurope, eastus, etc.)
- cadence: Update cadence ("Frequent" or "Moderate")
- allow_bing_search: Enable Bing search in the environment
- allow_moving_data_across_regions: Allow data movement across regions
- billing_policy_id: GUID for pay-as-you-go billing policy
- release_cycle: Early release participation

Examples:

# Production Environment
environment = {
  display_name                     = "Production Finance Environment"
  location                        = "unitedstates"
  environment_type               = "Production"
  environment_group_id           = "12345678-1234-1234-1234-123456789012"
  description                    = "Production environment for Finance applications"
  azure_region                   = "eastus"
  cadence                        = "Moderate"
  allow_bing_search              = false
  allow_moving_data_across_regions = false
}

# Sandbox Environment
environment = {
  display_name         = "Development Sandbox"
  location             = "unitedstates"
  environment_type     = "Sandbox"
  environment_group_id = "87654321-4321-4321-4321-210987654321"
  cadence              = "Frequent"
}

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
}

variable "dataverse" {
  type = object({
    # Required Arguments when Dataverse is enabled - ✅ REAL
    language_code     = number # LCID integer, not string!
    currency_code     = string
    security_group_id = string # ✅ NOW REQUIRED when dataverse is provided

    # Optional Arguments - ✅ REAL
    domain                       = optional(string) # Auto-calculated from display_name if null
    administration_mode_enabled  = optional(bool)
    background_operation_enabled = optional(bool)
    template_metadata            = optional(string) # String, not object!
    templates                    = optional(list(string))
  })

  description = <<DESCRIPTION
Dataverse database configuration for the Power Platform environment.

**GOVERNANCE REQUIREMENT**: Dataverse is REQUIRED for proper Power Platform governance.
This ensures all environments have proper data protection, security controls, and organizational structure.

Required Properties:
- language_code: LCID integer (e.g., 1033 for English US) 
- currency_code: ISO currency code string (e.g., "USD", "EUR", "GBP")
- security_group_id: Azure AD security group GUID (REQUIRED for governance)

Optional Properties:
- domain: Custom domain name for the Dataverse instance (auto-calculated from display_name if not provided)
- administration_mode_enabled: Enable admin mode for the environment
- background_operation_enabled: Enable background operations
- template_metadata: Additional D365 template metadata as string
- templates: List of D365 template names

Examples:

# Production Environment with Dataverse (REQUIRED)
dataverse = {
  language_code     = 1033
  currency_code     = "USD"
  security_group_id = "12345678-1234-1234-1234-123456789012"
  domain            = "contoso-prod" # Optional: Will auto-calculate if not provided
}

# Auto-calculated domain (recommended for consistency)
dataverse = {
  language_code     = 1033
  currency_code     = "USD"
  security_group_id = "12345678-1234-1234-1234-123456789012"
  # domain will be auto-calculated from environment.display_name
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
  description = "Enable duplicate environment detection and prevention."
  default     = true
}

