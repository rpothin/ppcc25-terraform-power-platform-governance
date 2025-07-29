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

# =============================================================================
# GENERATION MODE VARIABLES
# =============================================================================

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

# =============================================================================
# TEMPLATE CONFIGURATION VARIABLES
# =============================================================================

variable "policy_name" {
  type        = string
  description = <<DESCRIPTION
Name of the new DLP policy to generate tfvars for (used only when not onboarding from export).

If not specified, defaults to "New DLP Policy".

Example: "Production Security"
DESCRIPTION
  default     = null
}

variable "template_type" {
  type        = string
  description = <<DESCRIPTION
Type of tfvars template to generate for new policies.

- Options: "strict-security", "balanced", "development"
- Used when creating a new policy tfvars from a governance template.

Template Characteristics:
- strict-security: Most connectors classified as Confidential, minimal business connectors
- balanced: Common productivity connectors as General, others as Confidential
- development: Most connectors as General, only risky ones blocked

Example: "strict-security"
DESCRIPTION
  validation {
    condition     = contains(["strict-security", "balanced", "development"], var.template_type)
    error_message = "template_type must be one of: strict-security, balanced, development."
  }
  default = "strict-security"
}

# =============================================================================
# DLP POLICY SETTINGS
# =============================================================================

variable "default_connectors_classification" {
  type        = string
  description = <<DESCRIPTION
Default classification for connectors ("General", "Confidential", "Blocked").

This setting determines the fallback classification for connectors not explicitly
configured in the business, non-business, or blocked connector lists.

Classification Meanings:
- General: Low-risk connectors suitable for business data
- Confidential: Medium-risk connectors requiring additional controls
- Blocked: High-risk connectors prohibited from use

Security Best Practice: Default to "Blocked" for security-first governance.
DESCRIPTION
  default     = "Blocked"
  validation {
    condition     = contains(["General", "Confidential", "Blocked"], var.default_connectors_classification)
    error_message = "Must be one of: General, Confidential, Blocked."
  }
}

variable "environment_type" {
  type        = string
  description = <<DESCRIPTION
Environment scope for policy application ("AllEnvironments", "ExceptEnvironments", "OnlyEnvironments").

Environment Types:
- AllEnvironments: Apply policy to all environments in the tenant
- ExceptEnvironments: Apply policy to all environments except those specified in 'environments' list
- OnlyEnvironments: Apply policy only to environments specified in 'environments' list

Security Best Practice: Use "OnlyEnvironments" for targeted governance.
DESCRIPTION
  default     = "OnlyEnvironments"
  validation {
    condition     = contains(["AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"], var.environment_type)
    error_message = "Must be one of: AllEnvironments, ExceptEnvironments, OnlyEnvironments."
  }
}

variable "environments" {
  type        = list(string)
  description = <<DESCRIPTION
List of environment IDs to which the policy is applied.

- Required when environment_type is "OnlyEnvironments" or "ExceptEnvironments"
- Leave empty when environment_type is "AllEnvironments"
- Environment IDs must be valid GUIDs from Power Platform

Example: ["00000000-0000-0000-0000-000000000000", "11111111-1111-1111-1111-111111111111"]
DESCRIPTION
  default     = []
}

variable "custom_connectors_patterns" {
  type = list(object({
    order            = number
    host_url_pattern = string
    data_group       = string
  }))
  description = <<DESCRIPTION
Set of custom connector patterns for advanced DLP scenarios.

Each pattern must specify:
- order: Priority order for pattern evaluation (lower numbers evaluated first)
- host_url_pattern: URL pattern to match (supports wildcards)
- data_group: Classification for matching connectors ("General", "Confidential", "Blocked")

Security Best Practice: Default blocks all custom connectors (*) unless explicitly allowed.

Example with specific allowances:
custom_connectors_patterns = [
  {
    order            = 1
    host_url_pattern = "https://*.contoso.com"
    data_group       = "General"
  },
  {
    order            = 2
    host_url_pattern = "*"
    data_group       = "Blocked"
  }
]
DESCRIPTION
  default = [
    {
      order            = 1
      host_url_pattern = "*"
      data_group       = "Blocked"
    }
  ]
  validation {
    condition = alltrue([
      for pattern in var.custom_connectors_patterns :
      contains(["General", "Confidential", "Blocked"], pattern.data_group)
    ])
    error_message = "Each custom connector pattern's data_group must be one of: General, Confidential, Blocked."
  }
}

# =============================================================================
# CONNECTOR CLASSIFICATIONS
# =============================================================================

variable "business_connectors" {
  type = list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
  description = <<DESCRIPTION
List of business connectors for sensitive data (General classification).

Business connectors are typically used for corporate data and productivity scenarios.
Each connector can have specific action rules and endpoint restrictions for granular control.

Used only in template mode for new policy creation. In onboarding mode, 
connector data is extracted from existing policy exports.

Example:
business_connectors = [
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
    action_rules = [
      {
        action_id = "DeleteItem_V2"
        behavior  = "Block"
      }
    ]
    endpoint_rules = [
      {
        endpoint = "contoso.sharepoint.com"
        behavior = "Allow"
        order    = 1
      }
    ]
  }
]
DESCRIPTION
  default     = []
  validation {
    condition = alltrue([
      for c in var.business_connectors :
      contains(["Allow", "Block", ""], c.default_action_rule_behavior)
    ])
    error_message = "Each business connector's default_action_rule_behavior must be one of: Allow, Block, or empty string."
  }
}

variable "non_business_connectors" {
  type = list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
  description = <<DESCRIPTION
List of non-business connectors for non-sensitive data (Confidential classification).

Non-business connectors are typically used for external services or less sensitive scenarios.
They require additional governance controls compared to business connectors.

Used only in template mode for new policy creation. In onboarding mode, 
connector data is extracted from existing policy exports.

Example:
non_business_connectors = [
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
    default_action_rule_behavior = "Allow"
    action_rules                 = []
    endpoint_rules               = []
  }
]
DESCRIPTION
  default     = []
  validation {
    condition = alltrue([
      for c in var.non_business_connectors :
      contains(["Allow", "Block", ""], c.default_action_rule_behavior)
    ])
    error_message = "Each non-business connector's default_action_rule_behavior must be one of: Allow, Block, or empty string."
  }
}

variable "blocked_connectors" {
  type = list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
  description = <<DESCRIPTION
List of blocked connectors prohibited from use.

Blocked connectors represent high-risk services that are not permitted in the organization.
These connectors will be completely blocked for users within the policy scope.

Used only in template mode for new policy creation. In onboarding mode, 
connector data is extracted from existing policy exports.

Example:
blocked_connectors = [
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_dropbox"
    default_action_rule_behavior = "Block"
    action_rules                 = []
    endpoint_rules               = []
  }
]
DESCRIPTION
  default     = []
  validation {
    condition = alltrue([
      for c in var.blocked_connectors :
      contains(["Allow", "Block", ""], c.default_action_rule_behavior)
    ])
    error_message = "Each blocked connector's default_action_rule_behavior must be one of: Allow, Block, or empty string."
  }
}

# =============================================================================
# OUTPUT CONFIGURATION
# =============================================================================

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