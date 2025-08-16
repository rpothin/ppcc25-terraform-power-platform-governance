# Input Variables for Power Platform Environment Group Rule Set Configuration
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.

variable "environment_group_id" {
  type        = string
  description = <<DESCRIPTION
Unique identifier of the Power Platform Environment Group to apply rules to.

This GUID identifies the target environment group where governance rules will be
applied. The environment group must already exist and be accessible with current
authentication permissions.

Example: "12345678-1234-1234-1234-123456789012"

Validation Rules:
- Must be a valid GUID format (32 hexadecimal digits in 8-4-4-4-12 pattern)
- Cannot be empty or contain only whitespace characters
- Must reference an existing environment group in the tenant

Integration Requirements:
- Environment group must exist (created via res-environment-group or manually)
- Must have appropriate permissions to modify group rules
- Rules will be published automatically upon successful application
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_group_id))
    error_message = "Environment group ID must be a valid GUID format (e.g., '12345678-1234-1234-1234-123456789012'). Current value: '${var.environment_group_id}'. Check the environment group ID in Power Platform admin center."
  }

  validation {
    condition     = length(trimspace(var.environment_group_id)) > 0
    error_message = "Environment group ID cannot be empty or contain only whitespace. Provide the GUID of an existing environment group."
  }
}

variable "rules" {
  type = object({
    sharing_controls = optional(object({
      share_mode      = optional(string, "exclude sharing with security groups")
      share_max_limit = optional(number, 10)
    }))
    usage_insights = optional(object({
      insights_enabled = optional(bool, false)
    }))
    maker_welcome_content = optional(object({
      maker_onboarding_url      = string
      maker_onboarding_markdown = string
    }))
    solution_checker_enforcement = optional(object({
      solution_checker_mode = optional(string, "block")
      send_emails_enabled   = optional(bool, true)
    }))
    backup_retention = optional(object({
      period_in_days = number
    }))
    ai_generated_descriptions = optional(object({
      ai_description_enabled = optional(bool, false)
    }))
    ai_generative_settings = optional(object({
      move_data_across_regions_enabled = optional(bool, false)
      bing_search_enabled              = optional(bool, false)
    }))
  })
  description = <<DESCRIPTION
Comprehensive rule configuration for the environment group governance.

This object defines all available governance rules that can be applied to environments
within the group. Each rule type controls specific aspects of environment behavior
and enforces organizational policies consistently across environments.

Rule Categories:
- sharing_controls: Controls app and flow sharing within the group
- usage_insights: Enables usage analytics and reporting
- maker_welcome_content: Customizes onboarding experience for makers
- solution_checker_enforcement: Enforces solution quality standards
- backup_retention: Manages backup retention policies
- ai_generated_descriptions: Controls AI-generated content features
- ai_generative_settings: Manages AI capabilities and data movement

Example:
rules = {
  sharing_controls = {
    share_mode      = "exclude sharing with security groups"
    share_max_limit = 25
  }
  usage_insights = {
    insights_enabled = true
  }
  solution_checker_enforcement = {
    solution_checker_mode = "block"
    send_emails_enabled   = true
  }
  backup_retention = {
    period_in_days = 21
  }
  ai_generative_settings = {
    move_data_across_regions_enabled = false
    bing_search_enabled              = true
  }
}

Validation Rules:
- sharing_controls.share_mode: Must be valid sharing mode string
- sharing_controls.share_max_limit: Must be positive integer
- backup_retention.period_in_days: Must be 7, 14, 21, or 28 days
- solution_checker_enforcement.solution_checker_mode: Must be "block" or "audit"
- All boolean values must be explicitly set (no implicit conversions)
DESCRIPTION
  default     = {}

  validation {
    condition = var.rules.sharing_controls == null ? true : contains(
      ["exclude sharing with security groups", "allow sharing with security groups"],
      var.rules.sharing_controls.share_mode
    )
    error_message = "Sharing controls share_mode must be either 'exclude sharing with security groups' or 'allow sharing with security groups'. Check Power Platform documentation for valid options."
  }

  validation {
    condition = var.rules.sharing_controls == null ? true : (
      var.rules.sharing_controls.share_max_limit >= 1 && var.rules.sharing_controls.share_max_limit <= 10000
    )
    error_message = "Sharing controls share_max_limit must be between 1 and 10000. Current value: ${var.rules.sharing_controls != null ? var.rules.sharing_controls.share_max_limit : "null"}. Adjust to a reasonable sharing limit."
  }

  validation {
    condition     = var.rules.backup_retention == null ? true : contains([7, 14, 21, 28], var.rules.backup_retention.period_in_days)
    error_message = "Backup retention period_in_days must be one of: 7, 14, 21, or 28 days. Current value: ${var.rules.backup_retention != null ? var.rules.backup_retention.period_in_days : "null"}. Select a valid retention period."
  }

  validation {
    condition = var.rules.solution_checker_enforcement == null ? true : contains(
      ["block", "audit"],
      var.rules.solution_checker_enforcement.solution_checker_mode
    )
    error_message = "Solution checker enforcement mode must be either 'block' or 'audit'. Current value: '${var.rules.solution_checker_enforcement != null ? var.rules.solution_checker_enforcement.solution_checker_mode : "null"}'. Choose appropriate enforcement level."
  }

  validation {
    condition = var.rules.maker_welcome_content == null ? true : (
      length(var.rules.maker_welcome_content.maker_onboarding_url) > 0 &&
      length(var.rules.maker_welcome_content.maker_onboarding_markdown) > 0
    )
    error_message = "Maker welcome content requires both maker_onboarding_url and maker_onboarding_markdown to be non-empty strings. Provide complete onboarding content."
  }

  validation {
    condition     = var.rules.maker_welcome_content == null ? true : can(regex("^https?://", var.rules.maker_welcome_content.maker_onboarding_url))
    error_message = "Maker onboarding URL must be a valid HTTP or HTTPS URL. Current value: '${var.rules.maker_welcome_content != null ? var.rules.maker_welcome_content.maker_onboarding_url : "null"}'. Provide a complete URL including protocol."
  }
}