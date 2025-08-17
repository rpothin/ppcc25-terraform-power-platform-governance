# Input Variables for Power Platform Environment Group Pattern Configuration
#
# This file defines all input parameters for the pattern following
# AVM variable standards with comprehensive validation and documentation.
# Pattern modules orchestrate multiple resources to implement governance scenarios.

variable "environment_group_config" {
  type = object({
    display_name = string
    description  = string
  })
  description = <<DESCRIPTION
Configuration for the Power Platform Environment Group creation.

This object defines the environment group that will serve as the container
for organizing multiple environments with consistent governance policies.

Properties:
- display_name: Human-readable name for the environment group (1-100 chars)
- description: Detailed description of the group purpose and scope (1-500 chars)

Example:
environment_group_config = {
  display_name = "Development Environment Group"
  description  = "Centralized group for all development environments with standardized governance policies"
}

Validation Rules:
- Display name must be unique within tenant and follow naming conventions
- Description should explain group purpose and governance approach
- Both fields are required and cannot be empty or whitespace-only
DESCRIPTION

  validation {
    condition     = length(var.environment_group_config.display_name) >= 1 && length(var.environment_group_config.display_name) <= 100
    error_message = "Environment group display name must be 1-100 characters. Current length: ${length(var.environment_group_config.display_name)}. Adjust name to meet Power Platform limits."
  }

  validation {
    condition     = length(trimspace(var.environment_group_config.display_name)) > 0
    error_message = "Environment group display name cannot be empty or contain only whitespace. Provide a meaningful name for the environment group."
  }

  validation {
    condition     = length(var.environment_group_config.description) >= 1 && length(var.environment_group_config.description) <= 500
    error_message = "Environment group description must be 1-500 characters. Current length: ${length(var.environment_group_config.description)}. Provide a clear, concise description."
  }

  validation {
    condition     = length(trimspace(var.environment_group_config.description)) > 0
    error_message = "Environment group description cannot be empty or contain only whitespace. Provide a meaningful description of the environment group purpose."
  }
}

variable "environments" {
  type = list(object({
    display_name       = string
    location           = string
    environment_type   = string
    dataverse_language = optional(string, "en")
    dataverse_currency = optional(string, "USD")
    domain             = optional(string)
  }))
  description = <<DESCRIPTION
List of environments to create and assign to the environment group.

Each environment object represents a Power Platform environment that will be
created and automatically assigned to the environment group for consistent
governance and policy application.

Properties:
- display_name: Human-readable name for the environment (required, 1-100 chars)
- location: Azure region for the environment (required, valid Azure region)
- environment_type: Type of environment - "Sandbox", "Production", or "Trial" (required)
- dataverse_language: Language code for Dataverse database (optional, default: "en")
- dataverse_currency: Currency code for Dataverse database (optional, default: "USD")
- domain: Custom domain name for the environment (optional, auto-generated if not provided)

Example:
environments = [
  {
    display_name     = "Development Environment"
    location         = "unitedstates"
    environment_type = "Sandbox"
    domain           = "dev-environment"
  },
  {
    display_name     = "Testing Environment"
    location         = "unitedstates"
    environment_type = "Sandbox"
    dataverse_language = "en"
    dataverse_currency = "USD"
  }
]

Validation Rules:
- At least one environment must be provided for the pattern to be meaningful
- Display names must be unique across the tenant
- Environment types are restricted to supported values for service principal authentication
- Locations must be valid Power Platform geographic regions
DESCRIPTION

  validation {
    condition     = length(var.environments) >= 1
    error_message = "At least one environment must be provided. Pattern modules require multiple resources to demonstrate orchestration patterns."
  }

  validation {
    condition = alltrue([
      for env in var.environments : length(env.display_name) >= 1 && length(env.display_name) <= 100
    ])
    error_message = "All environment display names must be 1-100 characters. Check each environment name length."
  }

  validation {
    condition = alltrue([
      for env in var.environments : length(trimspace(env.display_name)) > 0
    ])
    error_message = "Environment display names cannot be empty or contain only whitespace. Provide meaningful names for all environments."
  }

  validation {
    condition = alltrue([
      for env in var.environments : contains(["Sandbox", "Production", "Trial"], env.environment_type)
    ])
    error_message = "Environment types must be 'Sandbox', 'Production', or 'Trial'. Developer environments are not supported with service principal authentication."
  }

  validation {
    condition = alltrue([
      for env in var.environments : contains([
        "unitedstates", "europe", "asia", "australia", "unitedkingdom", "india",
        "canada", "southamerica", "france", "unitedarabemirates", "southafrica",
        "germany", "switzerland", "norway", "korea", "japan"
      ], env.location)
    ])
    error_message = "Environment locations must be valid Power Platform geographic regions. Supported regions: unitedstates, europe, asia, australia, unitedkingdom, india, canada, southamerica, france, unitedarabemirates, southafrica, germany, switzerland, norway, korea, japan."
  }
}

variable "enable_duplicate_protection" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Enable duplicate protection to prevent creation of environments with duplicate names.

This setting controls whether the pattern validates against existing environments
to prevent naming conflicts. In production scenarios, this should typically be
enabled to maintain environment naming consistency.

Default: true (recommended for production use)

Validation Rules:
- When true: Validates environment names against existing tenant environments
- When false: Allows potential duplicate names (useful for testing scenarios)
- Always validates that environments within the pattern have unique names
DESCRIPTION
}