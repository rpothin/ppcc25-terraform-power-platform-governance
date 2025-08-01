# Input Variables for res-dlp-policy
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Primary DLP policy settings
# - Environment Settings: Target environments for policy application
# - Security Settings: Authentication and access controls

variable "display_name" {
  description = <<DESCRIPTION
The display name of the DLP policy.
DESCRIPTION
  type        = string
}

variable "default_connectors_classification" {
  description = <<DESCRIPTION
Default classification for connectors ("General", "Confidential", "Blocked").
DESCRIPTION
  type        = string
  validation {
    condition     = contains(["General", "Confidential", "Blocked"], var.default_connectors_classification)
    error_message = "Must be one of: General, Confidential, Blocked."
  }
  default = "Blocked"
}

variable "environment_type" {
  description = <<DESCRIPTION
Default environment handling for the policy ("AllEnvironments", "ExceptEnvironments", "OnlyEnvironments").
DESCRIPTION
  type        = string
  validation {
    condition     = contains(["AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"], var.environment_type)
    error_message = "Must be one of: AllEnvironments, ExceptEnvironments, OnlyEnvironments."
  }
  default = "OnlyEnvironments"
}

variable "environments" {
  description = <<DESCRIPTION
List of environment IDs to which the policy is applied. Leave empty for all environments.
DESCRIPTION
  type        = list(string)
  default     = []
}

variable "business_connectors" {
  description = <<DESCRIPTION
List of business connectors for sensitive data. Each object must match the provider schema and allows full configuration of connector DLP rules.

Example:
business_connectors = [
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    action_rules = [
      {
        action_id = "DeleteItem_V2"
        behavior  = "Block"
      }
    ]
    endpoint_rules = [
      {
        endpoint = "contoso.com"
        behavior = "Allow"
        order    = 1
      }
    ]
  }
]
DESCRIPTION
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
  validation {
    condition = alltrue([
      for c in var.business_connectors :
      contains(["Allow", "Block", ""], c.default_action_rule_behavior)
    ])
    error_message = "Each business connector's default_action_rule_behavior must be one of: Allow, Block, or empty string."
  }
}

variable "non_business_connectors" {
  description = <<DESCRIPTION
Set of non-business connectors for non-sensitive data. Each object must match the provider schema and allows full configuration of connector DLP rules.

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
  default = []
  validation {
    condition = alltrue([
      for c in var.non_business_connectors :
      contains(["Allow", "Block", ""], c.default_action_rule_behavior)
    ])
    error_message = "Each non-business connector's default_action_rule_behavior must be one of: Allow, Block, or empty string."
  }
}

variable "blocked_connectors" {
  description = <<DESCRIPTION
Set of blocked connectors. Each object must match the provider schema and allows full configuration of connector DLP rules.

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
  default = []
  validation {
    condition = alltrue([
      for c in var.blocked_connectors :
      contains(["Allow", "Block", ""], c.default_action_rule_behavior)
    ])
    error_message = "Each blocked connector's default_action_rule_behavior must be one of: Allow, Block, or empty string."
  }
}

variable "custom_connectors_patterns" {
  description = <<DESCRIPTION
Set of custom connector patterns for advanced DLP scenarios. Each pattern must specify order, host_url_pattern, and data_group.

By default, blocks all custom connectors following security-first principles. Override this variable to allow specific URL patterns for approved custom connectors.

Example with specific allowances:
custom_connectors_patterns = [
  {
    order            = 1
    host_url_pattern = "https://*.contoso.com"
    data_group       = "Business"
  },
  {
    order            = 2
    host_url_pattern = "*"
    data_group       = "Blocked"
  }
]
DESCRIPTION
  type = list(object({
    order            = number
    host_url_pattern = string
    data_group       = string
  }))
  default = [
    {
      order            = 1
      host_url_pattern = "*"
      data_group       = "Blocked"
    }
  ]
}

variable "enable_duplicate_protection" {
  description = <<DESCRIPTION
Enable duplicate DLP policy detection and prevention. Set to true in production.
If true, the module will query existing DLP policies and fail the plan if a duplicate is detected (same display_name and environment_type).

Set to false to disable duplicate detection (not recommended for production).
DESCRIPTION
  type        = bool
  default     = true
}
