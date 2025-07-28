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
List of connector IDs to classify as business connectors. When provided, non-business and blocked connectors will be auto-classified unless explicitly set. If null, both non_business_connectors and blocked_connectors must be provided.

Example:
business_connectors = [
  "/providers/Microsoft.PowerApps/apis/shared_sql",
  "/providers/Microsoft.PowerApps/apis/shared_approvals"
]
DESCRIPTION
  type    = list(string)
  default = null
}

variable "non_business_connectors" {
  description = <<DESCRIPTION
Set of non-business connectors for non-sensitive data. When null and business_connectors is provided, will be auto-classified as all unblockable connectors not in business_connectors. When provided, auto-classification is bypassed.

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
  type    = list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules                 = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
  default = null
}

variable "blocked_connectors" {
  description = <<DESCRIPTION
Set of blocked connectors. When null and business_connectors is provided, will be auto-classified as all blockable connectors not in business_connectors. When provided, auto-classification is bypassed.

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
  type    = list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules                 = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
  default = null
}

variable "custom_connectors_patterns" {
  description = <<DESCRIPTION
Set of custom connector patterns for advanced DLP scenarios. Each pattern must specify order, host_url_pattern, and data_group.

Example:
custom_connectors_patterns = [
  {
    order            = 1
    host_url_pattern = "https://*.contoso.com"
    data_group       = "Blocked"
  },
  {
    order            = 2
    host_url_pattern = "*"
    data_group       = "Ignore"
  }
]
DESCRIPTION
  type = list(object({
    order            = number
    host_url_pattern = string
    data_group       = string
  }))
  default = []
}

# Validation: If business_connectors is null, both non_business_connectors and blocked_connectors must be provided
locals {
  _auto_classification_invalid = (
    var.business_connectors == null &&
    (var.non_business_connectors == null || var.blocked_connectors == null)
  )
}


