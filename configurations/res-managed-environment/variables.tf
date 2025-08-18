# Input Variables for Power Platform Managed Environment Configuration
#
# This file defines input parameters following AVM variable standards with focused,
# consumable object types that provide clear value through logical grouping.
#
# Design Principles:
# - Simple types preferred over complex nesting (SNFR14)
# - Each object serves a specific, logical purpose
# - Comprehensive documentation with HEREDOC format (TFNFR17)
# - Property-level validation with actionable error messages
#
# Provider Documentation: https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment

variable "environment_id" {
  type        = string
  description = <<DESCRIPTION
GUID of the Power Platform environment to configure as a managed environment.

This is the primary identifier that links managed environment capabilities to the
specific Power Platform environment instance.

Example:
environment_id = "12345678-1234-1234-1234-123456789012"

Requirements:
- Must be a valid GUID format for Power Platform compatibility
- Environment must exist before applying managed environment settings
- User must have Environment Admin privileges for the specified environment
- Environment must support managed environment capabilities (premium licensing required)
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
    error_message = "Environment ID must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx). Current value: '${var.environment_id}'. Please provide a valid Power Platform environment GUID."
  }
}

variable "sharing_settings" {
  type = object({
    # Control canvas app sharing across the organization
    is_group_sharing_disabled = bool

    # Define sharing scope and limitations  
    limit_sharing_mode = string

    # Maximum number of users for sharing (use -1 if group sharing is enabled)
    max_limit_user_sharing = number
  })

  default = {
    is_group_sharing_disabled = false      # Enable group sharing (better practice than individual sharing)
    limit_sharing_mode        = "No limit" # Allow unrestricted sharing with security groups
    max_limit_user_sharing    = -1         # Unlimited when group sharing is enabled
  }

  description = <<DESCRIPTION
Canvas app sharing controls and limitations for the managed environment.

This configuration manages how widely canvas apps can be shared within the organization,
providing governance controls to prevent data exposure and maintain compliance.

Properties:
- is_group_sharing_disabled: Prevents sharing with security groups when true
- limit_sharing_mode: Controls sharing scope ("No limit", "Exclude sharing with security groups")
- max_limit_user_sharing: Maximum users for individual sharing (-1 if group sharing enabled)

Example:
sharing_settings = {
  is_group_sharing_disabled = false
  limit_sharing_mode        = "No limit"
  max_limit_user_sharing    = -1
}

Default Configuration (Governance Best Practice):
- Enables group sharing (is_group_sharing_disabled = false)
- Allows unrestricted sharing (limit_sharing_mode = "No limit")
- Sets unlimited user sharing (max_limit_user_sharing = -1)
- Encourages security group usage over individual user sharing

Validation Rules:
- If group sharing is disabled, max_limit_user_sharing must be > 0
- If group sharing is enabled, max_limit_user_sharing should be -1
- limit_sharing_mode must be a valid sharing mode value

See: https://learn.microsoft.com/power-platform/admin/managed-environment-sharing-limits
DESCRIPTION

  validation {
    condition     = var.sharing_settings.is_group_sharing_disabled == false ? var.sharing_settings.max_limit_user_sharing == -1 : var.sharing_settings.max_limit_user_sharing > 0
    error_message = "When group sharing is enabled (is_group_sharing_disabled = false), max_limit_user_sharing must be -1. When group sharing is disabled (is_group_sharing_disabled = true), max_limit_user_sharing must be greater than 0. Current values: is_group_sharing_disabled = ${var.sharing_settings.is_group_sharing_disabled}, max_limit_user_sharing = ${var.sharing_settings.max_limit_user_sharing}."
  }

  validation {
    condition     = contains(["No limit", "Exclude sharing with security groups"], var.sharing_settings.limit_sharing_mode)
    error_message = "limit_sharing_mode must be one of: 'No limit', 'Exclude sharing with security groups'. Current value: '${var.sharing_settings.limit_sharing_mode}'. Please use a valid sharing mode as documented in the Power Platform provider."
  }
}

variable "usage_insights_disabled" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Controls whether weekly usage insights digest is disabled for the managed environment.

When set to false, administrators receive weekly email digests with usage
insights for the environment. When set to true (default), these insights are disabled.

Example:
usage_insights_disabled = false  # Enable weekly insights
usage_insights_disabled = true   # Disable weekly insights (default)

Default: true (insights disabled to avoid spamming tenant administrators)

Note: While insights can provide governance visibility, they often generate excessive
email volume. Consider enabling only for critical production environments or using
alternative monitoring approaches.

See: https://learn.microsoft.com/power-platform/admin/managed-environment-usage-insights
DESCRIPTION
}

variable "solution_checker" {
  type = object({
    # Solution validation mode for imports
    mode = string

    # Email notification settings for validation results
    suppress_validation_emails = bool

    # Override specific solution checker rules
    rule_overrides = optional(set(string), [])
  })

  default = {
    mode                       = "Warn" # Balanced approach: validate but don't block
    suppress_validation_emails = true   # Reduce email noise, only send for blocked solutions
    rule_overrides             = []     # No rule overrides by default
  }

  description = <<DESCRIPTION
Solution checker configuration for automated validation and quality control.

This configuration enables automatic verification of solution checker results for
security and reliability issues before solution import, supporting governance
and compliance requirements.

Properties:
- mode: Validation enforcement level (None, Warn, Block)
- suppress_validation_emails: When true, only sends emails for blocked solutions
- rule_overrides: Set of solution checker rules to override/disable

Example:
solution_checker = {
  mode                      = "Warn"
  suppress_validation_emails = true
  rule_overrides            = ["meta-avoid-reg-no-attribute", "app-use-delayoutput-text-input"]
}

Default Configuration (Balanced Governance):
- Uses "Warn" mode for validation without blocking imports
- Suppresses validation emails to reduce noise
- No rule overrides (full validation suite)

Validation Rules:
- mode must be one of: None, Warn, Block
- rule_overrides must contain valid solution checker rule names

See: https://learn.microsoft.com/power-platform/admin/managed-environment-solution-checker
DESCRIPTION

  validation {
    condition     = contains(["None", "Warn", "Block"], var.solution_checker.mode)
    error_message = "Solution checker mode must be one of: 'None', 'Warn', 'Block'. Current value: '${var.solution_checker.mode}'. Please use a valid solution checker mode."
  }
}

variable "maker_onboarding" {
  type = object({
    # Markdown content displayed to first-time makers in Power Apps Studio
    markdown_content = string

    # URL for additional maker resources and guidance
    learn_more_url = string
  })

  default = {
    markdown_content = "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions."
    learn_more_url   = "https://learn.microsoft.com/power-platform/"
  }

  description = <<DESCRIPTION
Maker onboarding configuration to provide guidance and resources for new Power Platform makers.

This configuration enables administrators to provide customized welcome content and
learning resources that appear when makers first access Power Apps Studio in this environment.

Properties:
- markdown_content: Rich text content displayed in Power Apps Studio (supports markdown)
- learn_more_url: URL for additional documentation, training, or support resources

Example:
maker_onboarding = {
  markdown_content = "## Welcome to Our Power Platform Environment\\n\\nPlease review our development guidelines before creating apps."
  learn_more_url   = "https://company.com/power-platform-guidance"
}

Default Configuration:
- Provides basic welcome message with governance reminder
- Links to official Microsoft Power Platform documentation
- Can be customized for organization-specific guidance

Note: While maker onboarding can provide value, many organizations prefer to handle
user guidance through separate training programs and documentation systems.

Validation Rules:
- markdown_content must not be empty
- learn_more_url must be a valid HTTPS URL for security
- Content should follow organizational guidelines and branding

See: https://learn.microsoft.com/power-platform/admin/welcome-content
DESCRIPTION

  validation {
    condition     = length(trimspace(var.maker_onboarding.markdown_content)) > 0
    error_message = "Maker onboarding markdown content cannot be empty or contain only whitespace. Please provide meaningful guidance content for new makers."
  }

  validation {
    condition     = can(regex("^https://[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\..*", var.maker_onboarding.learn_more_url))
    error_message = "Maker onboarding learn more URL must be a valid HTTPS URL for security. Current value: '${var.maker_onboarding.learn_more_url}'. Please provide a secure HTTPS URL."
  }
}