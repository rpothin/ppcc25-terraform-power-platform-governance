
# Input Variables for Smart DLP tfvars Generator
#
# All variables use explicit types and strong validation (AVM/project standard).
# Comments focus on intent and rationale, not just mechanics.

variable "policy_name" {
  type        = string
  description = <<DESCRIPTION
Name of the new DLP policy to generate tfvars for (used only when not onboarding from export).

If not specified, defaults to "New DLP Policy".

Example: "Production Security"
DESCRIPTION
  default     = null
}

variable "source_policy_name" {
  type        = string
  description = <<DESCRIPTION
Name of the DLP policy to onboard and generate tfvars for.

- Used to select an existing policy from exported data (onboarding mode).
- If not specified, the generator will use template mode for new policy creation.
- Must match a policy name present in the exported JSON file if provided.

Example: "Copilot Studio Autonomous Agents"
DESCRIPTION
  default     = ""
  validation {
    condition     = var.source_policy_name == "" || (length(var.source_policy_name) > 0 && can(regex("^[a-zA-Z0-9 _-]+$", var.source_policy_name)) && length(var.source_policy_name) <= 100)
    error_message = "source_policy_name must be empty (for template mode) or a valid policy name (max 100 chars, alphanumeric, space, dash, underscore)."
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
