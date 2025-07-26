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
Set of business connectors for sensitive data. See provider docs for structure.
DESCRIPTION
  type        = any
}

variable "non_business_connectors" {
  description = <<DESCRIPTION
Set of non-business connectors for non-sensitive data. See provider docs for structure.
DESCRIPTION
  type        = any
}

variable "blocked_connectors" {
  description = <<DESCRIPTION
Set of blocked connectors. See provider docs for structure.
DESCRIPTION
  type        = any
}

variable "custom_connectors_patterns" {
  description = <<DESCRIPTION
Set of custom connector patterns for advanced DLP scenarios. See provider docs for structure.
DESCRIPTION
  type        = any
}
