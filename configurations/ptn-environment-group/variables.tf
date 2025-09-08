# Input Variables for Power Platform Environment Group Pattern Configuration
#
# Template-driven pattern for creating environment groups with predefined
# workspace templates. Follows convention over configuration principles
# for PPCC25 demonstration scenarios.

variable "workspace_template" {
  type        = string
  description = <<DESCRIPTION
Workspace template that defines the environments to create.

Predefined templates provide standardized environment configurations
for different use cases and governance requirements.

Available templates:
- "basic": Creates Dev, Test, and Prod environments
- "simple": Creates Dev and Prod environments only  
- "enterprise": Creates Dev, Staging, Test, and Prod environments

Example:
workspace_template = "basic"
DESCRIPTION

  validation {
    condition     = contains(["basic", "simple", "enterprise"], var.workspace_template)
    error_message = "workspace_template must be one of: basic, simple, enterprise"
  }
}

variable "enable_pattern_duplicate_protection" {
  type        = bool
  description = <<DESCRIPTION
Enable pattern-level duplicate environment detection and prevention.

When enabled, this checks if environments with the same names already exist
in the Power Platform tenant before creating new ones. This prevents
accidental resource conflicts.

IMPORTANT USAGE SCENARIOS:
- Set to true for NEW deployments to prevent creating duplicate environments
- Set to false when working with EXISTING Terraform state that manages environments
- Set to false when importing existing environments into Terraform management

If you see duplicate detection errors on environments that should be managed
by this Terraform configuration, this likely means:
1. The environments need to be imported into Terraform state, OR
2. You're working with existing managed environments and should set this to false
DESCRIPTION
  default     = true

  validation {
    condition = (
      var.enable_pattern_duplicate_protection == true || var.enable_pattern_duplicate_protection == false
    )
    error_message = "Invalid boolean value for enable_pattern_duplicate_protection. Must be true or false. GOVERNANCE NOTE: Setting to false disables duplicate protection at pattern level - use only for testing scenarios or when importing existing environments."
  }
}

variable "assume_existing_environments_are_managed" {
  type        = bool
  description = <<DESCRIPTION
Assume that existing environments with matching names are managed by this Terraform configuration.

This variable implements the state-aware duplicate detection logic from the research document:
- When true: Existing environments are assumed to be managed (allows updates)
- When false: Existing environments are assumed to be unmanaged (blocks as duplicates)

USAGE GUIDELINES:
- Set to false for FRESH deployments where you want strict duplicate protection
- Set to true when working with EXISTING state where environments should be managed
- This is the key variable that implements the "managed_update" vs "duplicate_blocked" logic

This variable works in conjunction with enable_pattern_duplicate_protection to provide
fine-grained control over the three-scenario detection pattern.
DESCRIPTION
  default     = false

  validation {
    condition = (
      var.assume_existing_environments_are_managed == true || var.assume_existing_environments_are_managed == false
    )
    error_message = "Invalid boolean value for assume_existing_environments_are_managed. Must be true or false."
  }
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
Workspace name used as the base for all environment names.

This name will be combined with environment suffixes defined in the
selected workspace template to create individual environment names.

Example:
name = "MyProject"

With "basic" template, this creates:
- "MyProject - Dev"
- "MyProject - Test" 
- "MyProject - Prod"

Validation Rules:
- Must be 1-50 characters to allow for suffixes
- Cannot be empty or contain only whitespace
- Should follow organizational naming conventions
DESCRIPTION

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 50
    error_message = "Workspace name must be 1-50 characters to accommodate environment suffixes. Current length: ${length(var.name)}."
  }

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Workspace name cannot be empty or contain only whitespace. Provide a meaningful workspace name."
  }
}

variable "description" {
  type        = string
  description = <<DESCRIPTION
Description of the workspace and its purpose.

This description will be used for the environment group and provides
context for the workspace's governance and business purpose.

Example:
description = "Project workspace for customer portal development"

Validation Rules:
- Must be 1-200 characters
- Cannot be empty or contain only whitespace
- Should describe business purpose and governance approach
DESCRIPTION

  validation {
    condition     = length(var.description) >= 1 && length(var.description) <= 200
    error_message = "Description must be 1-200 characters. Current length: ${length(var.description)}. Provide a clear, concise description."
  }

  validation {
    condition     = length(trimspace(var.description)) > 0
    error_message = "Description cannot be empty or contain only whitespace. Provide a meaningful description of the workspace purpose."
  }
}

variable "location" {
  type        = string
  description = <<DESCRIPTION
Power Platform geographic region for all environments in this workspace.

All environments created by the template will be deployed to this region.
The location must be supported by the selected workspace template.

Example:
location = "unitedstates"

Supported locations:
- unitedstates, europe, asia, australia, unitedkingdom, india
- canada, southamerica, france, unitedarabemirates, southafrica
- germany, switzerland, norway, korea, japan

Validation Rules:
- Must be a valid Power Platform geographic region
- Will be validated against template-specific allowed locations
- Cannot be changed after workspace creation without recreation
DESCRIPTION

  validation {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "unitedkingdom", "india",
      "canada", "southamerica", "france", "unitedarabemirates", "southafrica",
      "germany", "switzerland", "norway", "korea", "japan"
    ], var.location)
    error_message = "Location must be a valid Power Platform geographic region. Supported: unitedstates, europe, asia, australia, unitedkingdom, india, canada, southamerica, france, unitedarabemirates, southafrica, germany, switzerland, norway, korea, japan."
  }
}