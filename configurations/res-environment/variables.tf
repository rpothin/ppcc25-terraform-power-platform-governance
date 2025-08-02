# Input Variables for Power Platform Environment Configuration
#
# This file defines input parameters that align with the ACTUAL Power Platform provider schema.
# All fictional arguments have been removed to ensure 100% compatibility.
#
# Provider Documentation: https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment

variable "environment" {
  type = object({
    # Required Arguments - ✅ REAL
    display_name     = string
    location         = string
    environment_type = string

    # Optional Arguments - ✅ REAL
    owner_id                         = optional(string)
    description                      = optional(string)
    azure_region                     = optional(string)
    cadence                          = optional(string) # "Frequent" or "Moderate" only
    allow_bing_search                = optional(bool)
    allow_moving_data_across_regions = optional(bool)
    billing_policy_id                = optional(string)
    environment_group_id             = optional(string)
    release_cycle                    = optional(string)
  })

  description = <<DESCRIPTION
Power Platform environment configuration using ONLY real provider arguments.

This variable includes exclusively the arguments that actually exist in the 
microsoft/power-platform provider to ensure 100% compatibility.

Required Properties:
- display_name: Human-readable environment name
- location: Power Platform region (e.g., "unitedstates", "europe")
- environment_type: Environment classification (Sandbox, Production, Trial, Developer)

Optional Properties:
- owner_id: Entra ID user GUID (REQUIRED for Developer environments)
- description: Environment description
- azure_region: Specific Azure region (westeurope, eastus, etc.)
- cadence: Update cadence ("Frequent" or "Moderate")
- allow_bing_search: Enable Bing search in the environment
- allow_moving_data_across_regions: Allow data movement across regions
- billing_policy_id: GUID for pay-as-you-go billing policy
- environment_group_id: GUID for environment group membership
- release_cycle: Early release participation

Examples:

# Production Environment
environment = {
  display_name                     = "Production Finance Environment"
  location                        = "unitedstates"
  environment_type               = "Production"
  description                    = "Production environment for Finance applications"
  azure_region                   = "eastus"
  cadence                        = "Moderate"
  allow_bing_search              = false
  allow_moving_data_across_regions = false
}

# Developer Environment (owner_id required)
environment = {
  display_name     = "John's Development Environment"
  location         = "unitedstates"
  environment_type = "Developer"
  owner_id         = "12345678-1234-1234-1234-123456789012"
  cadence          = "Frequent"
}
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
    condition     = contains(["Sandbox", "Production", "Trial", "Developer"], var.environment.environment_type)
    error_message = "Environment type must be one of: Sandbox, Production, Trial, Developer."
  }

  validation {
    condition = (
      var.environment.owner_id == null ? true :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.owner_id))
    )
    error_message = "Owner ID must be a valid UUID format when provided."
  }

  validation {
    condition = (
      var.environment.environment_type == "Developer" ?
      var.environment.owner_id != null :
      true
    )
    error_message = "Developer environment type requires owner_id to be specified."
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
      var.environment.environment_group_id == null ? true :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment.environment_group_id))
    )
    error_message = "Environment group ID must be a valid UUID format when provided."
  }
}

variable "dataverse" {
  type = object({
    # Required Arguments - ✅ REAL
    language_code = number # LCID integer, not string!
    currency_code = string

    # Optional Arguments - ✅ REAL
    security_group_id            = optional(string)
    domain                       = optional(string)
    administration_mode_enabled  = optional(bool)
    background_operation_enabled = optional(bool)
    template_metadata            = optional(string) # String, not object!
    templates                    = optional(list(string))
  })

  description = <<DESCRIPTION
Dataverse database configuration using ONLY real provider arguments.

Required Properties:
- language_code: LCID integer (e.g., 1033 for English US) - NOTE: NUMBER not string!
- currency_code: ISO currency code string (e.g., "USD", "EUR", "GBP")

Optional Properties:
- security_group_id: Azure AD security group GUID
- domain: Custom domain name for the Dataverse instance
- administration_mode_enabled: Enable admin mode for the environment
- background_operation_enabled: Enable background operations
- template_metadata: Additional D365 template metadata as string
- templates: List of D365 template names

Examples:

# Production Dataverse
dataverse = {
  language_code                = 1033  # English (United States) - INTEGER!
  currency_code               = "USD"
  security_group_id           = "12345678-1234-1234-1234-123456789012"
  domain                      = "contoso-prod"
  administration_mode_enabled = false
  background_operation_enabled = true
}

# No Dataverse
dataverse = null
DESCRIPTION
  default     = null

  validation {
    condition     = var.dataverse == null ? true : (var.dataverse.language_code >= 1 && var.dataverse.language_code <= 9999)
    error_message = "Language code must be a valid LCID integer (1-9999). Common values: 1033 (English US), 1036 (French), 1031 (German)."
  }

  validation {
    condition     = var.dataverse == null ? true : can(regex("^[A-Z]{3}$", var.dataverse.currency_code))
    error_message = "Currency code must be a 3-letter ISO currency code (e.g., 'USD', 'EUR', 'GBP')."
  }

  validation {
    condition = var.dataverse == null ? true : (
      var.dataverse.security_group_id == null ? true :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.dataverse.security_group_id))
    )
    error_message = "Security group ID must be a valid UUID format if provided."
  }

  validation {
    condition = var.dataverse == null ? true : (
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

variable "tags" {
  type        = map(string)
  description = "Optional tags for Terraform state organization and governance."
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.tags : length(k) > 0 && length(v) > 0])
    error_message = "All tag keys and values must be non-empty strings."
  }
}