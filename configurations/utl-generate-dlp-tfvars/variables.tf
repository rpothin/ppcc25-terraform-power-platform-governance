# Input Variables for Smart DLP tfvars Generator (utl-generate-dlp-tfvars)
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Generation Mode: Controls onboarding vs template mode
# - Template Configuration: Settings for new policy generation
# - DLP Policy Settings: Core policy configuration parameters
# - Connector Classifications: Business, non-business, and blocked connectors
# - Output Configuration: File generation settings

# Onboarding-only variables
variable "source_policy_name" {
  type        = string
  description = <<DESCRIPTION
Name of the DLP policy to onboard and generate tfvars for.

- Used to select an existing policy from exported data (onboarding mode).
- Must match a policy name present in the exported JSON file if provided.

Example: "Copilot Studio Autonomous Agents"
DESCRIPTION
  validation {
    condition     = length(var.source_policy_name) > 0 && can(regex("^[a-zA-Z0-9 _-]+$", var.source_policy_name)) && length(var.source_policy_name) <= 100
    error_message = "source_policy_name must be a valid policy name (max 100 chars, alphanumeric, space, dash, underscore)."
  }
}

variable "output_file" {
  type        = string
  description = <<DESCRIPTION
Path and filename for the generated tfvars output.

- Should end with .tfvars extension for Terraform compatibility
- Path is relative to the current working directory
- If not specified, defaults to "generated-dlp-policy.tfvars"

Example: "outputs/generated-policy.tfvars"
DESCRIPTION
  default     = "generated-dlp-policy.tfvars"
  validation {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars extension."
  }
}