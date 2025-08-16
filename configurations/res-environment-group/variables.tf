# Input Variables for Power Platform Environment Group Configuration
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.

variable "display_name" {
  type        = string
  description = <<DESCRIPTION
Human-readable name for the Power Platform Environment Group.

This name appears in the Power Platform admin center and is used for identification
and management purposes. It should clearly indicate the purpose and scope of the
environment group.

Example: "Development Environment Group"

Validation Rules:
- Must be 1-100 characters for Power Platform compatibility  
- Cannot be empty or contain only whitespace characters
- Should be descriptive and follow organizational naming conventions
DESCRIPTION

  validation {
    condition     = length(var.display_name) >= 1 && length(var.display_name) <= 100
    error_message = "Display name must be 1-100 characters. Current length: ${length(var.display_name)}. Adjust name to meet Power Platform limits."
  }

  validation {
    condition     = length(trimspace(var.display_name)) > 0
    error_message = "Display name cannot be empty or contain only whitespace. Provide a meaningful name for the environment group."
  }
}

variable "description" {
  type        = string
  description = <<DESCRIPTION
Detailed description of the environment group purpose and scope.

This description provides context about what environments belong to this group,
what governance policies apply, and how it fits into the organization's Power
Platform strategy.

Example: "Centralized group for all development environments with standardized governance policies"

Validation Rules:
- Must be 1-500 characters to provide meaningful context
- Cannot be empty or contain only whitespace characters  
- Should explain the group's purpose and governance approach
DESCRIPTION

  validation {
    condition     = length(var.description) >= 1 && length(var.description) <= 500
    error_message = "Description must be 1-500 characters. Current length: ${length(var.description)}. Provide a clear, concise description."
  }

  validation {
    condition     = length(trimspace(var.description)) > 0
    error_message = "Description cannot be empty or contain only whitespace. Provide a meaningful description of the environment group purpose."
  }
}