# Input Variables for Power Platform Environment Group Configuration
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Primary environment group settings
# - Governance Settings: Policy and rule configuration parameters
# - Security Settings: Authentication and access controls
# - Feature Flags: Optional functionality toggles
#
# CRITICAL: Forbid use of `any` type. All complex variables must use explicit object types with property-level validation.

variable "environment_group_config" {
  type = object({
    display_name = string
    description  = string
  })
  description = <<DESCRIPTION
Configuration for Power Platform Environment Group creation.

This variable consolidates core environment group settings to reduce complexity while
ensuring all requirements are validated at plan time.

Properties:
- display_name: Human-readable name for the environment group (max 100 chars)
- description: Detailed description of the environment group purpose and scope

Example:
{
  display_name = "Development Environment Group"
  description  = "Centralized group for all development environments with standardized governance policies"
}

Validation Rules:
- Display name must be 1-100 characters for Power Platform compatibility
- Description must be provided to ensure clear group purpose documentation
- Both fields must not contain only whitespace characters
DESCRIPTION

  validation {
    condition     = length(var.environment_group_config.display_name) >= 1 && length(var.environment_group_config.display_name) <= 100
    error_message = "Display name must be 1-100 characters. Current length: ${length(var.environment_group_config.display_name)}. Adjust name to meet Power Platform limits."
  }

  validation {
    condition     = length(trimspace(var.environment_group_config.display_name)) > 0
    error_message = "Display name cannot be empty or contain only whitespace. Provide a meaningful name for the environment group."
  }

  validation {
    condition     = length(var.environment_group_config.description) >= 1 && length(var.environment_group_config.description) <= 500
    error_message = "Description must be 1-500 characters. Current length: ${length(var.environment_group_config.description)}. Provide a clear, concise description."
  }

  validation {
    condition     = length(trimspace(var.environment_group_config.description)) > 0
    error_message = "Description cannot be empty or contain only whitespace. Provide a meaningful description of the environment group purpose."
  }
}