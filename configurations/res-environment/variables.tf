# Input Variables for Power Platform Environment Configuration
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Primary environment settings
# - Dataverse Settings: Optional Dataverse database configuration
# - Security Settings: Authentication and access controls
# - Feature Flags: Optional functionality toggles
#
# CRITICAL: All complex variables use explicit object types with property-level validation.
# The `any` type is forbidden in all production modules.

variable "environment_config" {
  type = object({
    display_name     = string
    location         = string
    environment_type = string
    owner_id         = optional(string)
  })
  description = <<DESCRIPTION
Comprehensive configuration object for Power Platform environment.

This variable consolidates core environment settings to reduce complexity while
ensuring all requirements are validated at plan time.

Properties:
- display_name: Human-readable name for the environment (3-64 chars, alphanumeric with spaces/hyphens/underscores)
- location: Azure region where the environment will be created (e.g., "unitedstates", "europe", "asia")
- environment_type: Type of environment determining capabilities ("Sandbox", "Production", "Trial", "Developer")
- owner_id: Entra ID user GUID - REQUIRED for Developer environments, optional for others

Examples:
# Developer environment (owner_id required)
environment_config = {
  display_name     = "John's Development Environment"
  location         = "unitedstates"
  environment_type = "Developer"
  owner_id         = "12345678-1234-1234-1234-123456789012"
}

# Other environment types (owner_id optional)
environment_config = {
  display_name     = "Production Environment"
  location         = "unitedstates"
  environment_type = "Production"
}

Validation Rules:
- Display name must be unique within tenant and follow organizational standards
- Location must be supported by Power Platform for environment creation
- Environment type determines available features and capacity limits
- Owner ID must be valid UUID format when provided (required for Developer environments)
DESCRIPTION

  validation {
    condition = (
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment_config.display_name)) &&
      length(var.environment_config.display_name) >= 3 &&
      length(var.environment_config.display_name) <= 64
    )
    error_message = "Display name must be 3-64 characters, start/end with alphanumeric, and contain only letters, numbers, spaces, hyphens, underscores. Current: '${var.environment_config.display_name}'"
  }

  validation {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "india", "japan", "canada",
      "southamerica", "unitedkingdom", "france", "germany", "unitedarabemirates",
      "switzerland", "korea", "norway", "southafrica"
    ], var.environment_config.location)
    error_message = "Location must be a valid Power Platform region. Received: '${var.environment_config.location}'. See Power Platform admin center for supported regions."
  }

  validation {
    condition     = contains(["Sandbox", "Production", "Trial", "Developer"], var.environment_config.environment_type)
    error_message = "Environment type must be one of: Sandbox, Production, Trial, Developer. Received: '${var.environment_config.environment_type}'. Check Power Platform licensing for availability."
  }

  validation {
    condition = (
      var.environment_config.owner_id == null ? true :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_config.owner_id))
    )
    error_message = "Owner ID must be a valid UUID format when provided. Example: '12345678-1234-1234-1234-123456789012'"
  }

  validation {
    condition = (
      var.environment_config.environment_type == "Developer" ?
      var.environment_config.owner_id != null :
      true
    )
    error_message = "Developer environment type requires owner_id to be specified. Please provide a valid Entra ID user GUID. Environment type: '${var.environment_config.environment_type}'"
  }
}

variable "dataverse_config" {
  type = object({
    language_code     = string
    currency_code     = string
    security_group_id = optional(string)
    domain            = optional(string)
    organization_name = optional(string)
  })
  description = <<DESCRIPTION
Optional Dataverse database configuration for the environment.

When provided, creates a Dataverse database with the specified settings.
Leave as null to create an environment without Dataverse.

Properties:
- language_code: LCID code for the default language (e.g., "1033" for English US)
- currency_code: ISO currency code for the default currency (e.g., "USD", "EUR", "GBP")
- security_group_id: Optional Azure AD security group ID for database access control
- domain: Optional custom domain name for the Dataverse instance (auto-generated if not provided)
- organization_name: Optional organization name for the Dataverse instance (defaults to display_name if not provided)

Example:
dataverse_config = {
  language_code     = "1033"  # English (United States)
  currency_code     = "USD"   # US Dollar
  security_group_id = "12345678-1234-1234-1234-123456789012"
  domain            = "contoso-dev"
  organization_name = "Contoso Development"
}

Set to null to create environment without Dataverse:
dataverse_config = null

Validation Rules:
- Language code must be valid LCID (see Microsoft documentation)
- Currency code must be supported by Power Platform  
- Security group ID must be valid Azure AD object ID format if provided
- Domain must be unique within tenant and follow naming conventions
DESCRIPTION
  default     = null

  validation {
    condition     = var.dataverse_config == null ? true : can(regex("^[0-9]{4}$", var.dataverse_config.language_code))
    error_message = "Language code must be a 4-digit LCID code (e.g., '1033' for English US). Check Microsoft LCID documentation for valid codes."
  }

  validation {
    condition     = var.dataverse_config == null ? true : can(regex("^[A-Z]{3}$", var.dataverse_config.currency_code))
    error_message = "Currency code must be a 3-letter ISO currency code (e.g., 'USD', 'EUR', 'GBP'). Check Power Platform supported currencies."
  }

  validation {
    condition = var.dataverse_config == null ? true : (
      var.dataverse_config.security_group_id == null ? true :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.dataverse_config.security_group_id))
    )
    error_message = "Security group ID must be a valid UUID format if provided. Example: '12345678-1234-1234-1234-123456789012'"
  }

  validation {
    condition = var.dataverse_config == null ? true : (
      var.dataverse_config.domain == null ? true :
      can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.dataverse_config.domain)) &&
      length(var.dataverse_config.domain) >= 3 &&
      length(var.dataverse_config.domain) <= 63
    )
    error_message = "Domain must be 3-63 characters, lowercase alphanumeric with hyphens, cannot start/end with hyphen if provided."
  }

  validation {
    condition = var.dataverse_config == null ? true : (
      var.dataverse_config.organization_name == null ? true :
      length(var.dataverse_config.organization_name) >= 1 &&
      length(var.dataverse_config.organization_name) <= 100
    )
    error_message = "Organization name must be 1-100 characters if provided."
  }
}

variable "enable_duplicate_protection" {
  type        = bool
  description = <<DESCRIPTION
Enable duplicate environment detection and prevention.

When true, the module will query existing environments and fail the plan if a duplicate 
is detected (same display_name). This is recommended for production to prevent
accidental environment duplication.

Set to false to disable duplicate detection during environment import processes
or when creating environments with potentially conflicting names.

Default: true (recommended for production)

Usage scenarios:
- Production deployments: true (prevent duplicates)
- Environment import: false (temporarily during import process)
- Development/testing: true (maintain consistency)
DESCRIPTION
  default     = true
}

variable "tags" {
  type        = map(string)
  description = <<DESCRIPTION
Optional tags to apply to the environment for organization and cost tracking.

Note: Power Platform environments have limited native tagging support compared
to Azure resources. These tags are primarily used for Terraform state organization
and may be used by governance processes.

Example:
tags = {
  Environment = "Production"
  Department  = "Finance"
  CostCenter  = "CC-12345"
  Owner       = "finance-team@contoso.com"
}
DESCRIPTION
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.tags : length(k) > 0 && length(v) > 0])
    error_message = "All tag keys and values must be non-empty strings."
  }

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Maximum of 50 tags are supported to maintain performance."
  }
}