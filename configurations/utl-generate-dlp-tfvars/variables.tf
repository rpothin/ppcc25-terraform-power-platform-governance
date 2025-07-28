# Input Variables for Smart DLP tfvars Generator
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Policy Selection: Select policy by name, environment, or other criteria
# - Template Type: Choose template (strict, balanced, development)
# - Output File: Specify output file location and naming
#
# CRITICAL: Forbid use of `any` type. All complex variables must use explicit object types with property-level validation.

variable "source_policy_name" {
  type        = string
  description = <<DESCRIPTION
Name of the DLP policy to onboard or generate tfvars for.

- Used to select an existing policy from exported data.
- Must match a policy name present in the exported JSON file.

Example: "Copilot Studio Autonomous Agents"
DESCRIPTION
  validation {
    condition     = length(var.source_policy_name) > 0
    error_message = "source_policy_name must not be empty."
  }
}

variable "template_type" {
  type        = string
  description = <<DESCRIPTION
Type of tfvars template to generate for new policies.

- Options: "strict-security", "balanced", "development"
- Used when creating a new policy tfvars from a governance template.

Example: "strict-security"
DESCRIPTION
  validation {
    condition     = contains(["strict-security", "balanced", "development"], var.template_type)
    error_message = "template_type must be one of: strict-security, balanced, development."
  }
}

variable "output_file" {
  type        = string
  description = <<DESCRIPTION
Path and filename for the generated tfvars output.

- Should end with .tfvars
- If not specified, defaults to "generated-dlp-policy.tfvars"

Example: "outputs/generated-policy.tfvars"
DESCRIPTION
  validation {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars."
  }
  default = "generated-dlp-policy.tfvars"
}
