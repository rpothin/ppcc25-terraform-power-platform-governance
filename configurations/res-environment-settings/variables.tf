# Input Variables for Power Platform Environment Settings Configuration
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
# Provider Documentation: https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_settings

variable "environment_id" {
  type        = string
  description = <<DESCRIPTION
GUID of the Power Platform environment to configure with settings.

This is the primary identifier that links all environment settings to the
specific Power Platform environment instance.

Example:
environment_id = "12345678-1234-1234-1234-123456789012"

Requirements:
- Must be a valid GUID format for Power Platform compatibility
- Environment must exist before applying settings
- User must have Environment Admin privileges for the specified environment
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
    error_message = "Environment ID must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx). Current value: '${var.environment_id}'. Please provide a valid Power Platform environment GUID."
  }
}

variable "audit_settings" {
  type = object({
    # Plugin trace configuration for debugging and monitoring
    plugin_trace_log_setting = optional(string)

    # Comprehensive audit configuration for compliance
    is_audit_enabled             = optional(bool)
    is_user_access_audit_enabled = optional(bool)
    is_read_audit_enabled        = optional(bool)
    log_retention_period_in_days = optional(number)
  })

  default     = null
  description = <<DESCRIPTION
Audit and logging configuration for compliance tracking and monitoring.

When provided, enables comprehensive audit capabilities for the Power Platform
environment to support governance, compliance, and security monitoring requirements.

Properties:
- plugin_trace_log_setting: Plugin trace level for debugging ("Off", "Exception", "All")
- is_audit_enabled: Enable general auditing for environment operations
- is_user_access_audit_enabled: Enable user access auditing for security monitoring
- is_read_audit_enabled: Enable read operation auditing (high volume, use carefully)
- log_retention_period_in_days: Audit log retention period (31-24855 days, -1 for forever)

Example:
audit_settings = {
  plugin_trace_log_setting     = "Exception"
  is_audit_enabled             = true
  is_user_access_audit_enabled = true
  is_read_audit_enabled        = false
  log_retention_period_in_days = 90
}

Compliance Benefits:
- Supports SOX, GDPR, and other regulatory requirements
- Enables security incident investigation and forensics
- Provides audit trail for environment configuration changes
- Facilitates compliance reporting and evidence collection
DESCRIPTION

  validation {
    condition     = var.audit_settings == null || var.audit_settings.plugin_trace_log_setting == null || contains(["Off", "Exception", "All"], var.audit_settings.plugin_trace_log_setting)
    error_message = "Plugin trace log setting must be one of: 'Off', 'Exception', 'All'. Current value: '${try(var.audit_settings.plugin_trace_log_setting, "null")}'. See Power Platform documentation for valid trace levels."
  }

  validation {
    condition     = var.audit_settings == null || var.audit_settings.log_retention_period_in_days == null || (var.audit_settings.log_retention_period_in_days >= 31 && var.audit_settings.log_retention_period_in_days <= 24855) || var.audit_settings.log_retention_period_in_days == -1
    error_message = "Log retention period must be between 31 and 24855 days, or -1 for forever. Current value: '${try(var.audit_settings.log_retention_period_in_days, "null")}'. Please set to a valid retention period for compliance requirements."
  }
}

variable "security_settings" {
  type = object({
    # Application access controls
    allow_application_user_access        = optional(bool)
    allow_microsoft_trusted_service_tags = optional(bool)

    # Network security and firewall configuration
    # NOTE: IP firewall settings currently commented out in main.tf due to Power Platform limitation
    # Standard environments cannot have IP firewall rules - only managed environments support this
    enable_ip_based_firewall_rule               = optional(bool)
    enable_ip_based_firewall_rule_in_audit_mode = optional(bool)
    allowed_ip_range_for_firewall               = optional(set(string))
    allowed_service_tags_for_firewall           = optional(set(string))
    reverse_proxy_ip_addresses                  = optional(set(string))
  })

  default     = null
  description = <<DESCRIPTION
Security and access control configuration for Power Platform environment protection.

⚠️  IMPORTANT LIMITATION: IP firewall settings are currently commented out in the resource
due to Power Platform limitation where standard environments cannot have IP firewall rules.
Only managed environments support IP firewall functionality.

PLATFORM DELAY: This limitation currently prevents seamless deployment of IP firewall rules.
The settings are preserved in the variable definition for future use when:
1. Power Platform adds support for IP firewall rules in standard environments, OR  
2. When using managed environments instead of standard environments

Currently Active Properties:
- allow_application_user_access: Allow service principal (application) access to environment
- allow_microsoft_trusted_service_tags: Allow Microsoft trusted service tags for connectivity
- reverse_proxy_ip_addresses: IP addresses of reverse proxy servers for proper client identification

Currently Inactive Properties (preserved for future use):
- enable_ip_based_firewall_rule: Enable IP-based firewall for network access control
- enable_ip_based_firewall_rule_in_audit_mode: Enable firewall in audit mode (log only)
- allowed_ip_range_for_firewall: Permitted IP ranges in CIDR format (e.g., "10.0.0.0/8")
- allowed_service_tags_for_firewall: Permitted Azure service tags (e.g., "ApiManagement")

Example (current working configuration):
security_settings = {
  allow_application_user_access        = true
  allow_microsoft_trusted_service_tags = true
  reverse_proxy_ip_addresses          = ["10.0.1.100", "10.0.1.101"]
}

Example (future configuration when IP firewall is supported):
security_settings = {
  allow_application_user_access        = true
  allow_microsoft_trusted_service_tags = true
  enable_ip_based_firewall_rule        = true
  allowed_ip_range_for_firewall        = ["10.0.0.0/8", "192.168.1.0/24"]
  allowed_service_tags_for_firewall    = ["ApiManagement", "PowerPlatformPlex"]
}
DESCRIPTION

  validation {
    condition = var.security_settings == null || var.security_settings.allowed_ip_range_for_firewall == null || alltrue([
      for ip_range in var.security_settings.allowed_ip_range_for_firewall :
      can(cidrhost(ip_range, 0))
    ])
    error_message = "All IP ranges must be in valid CIDR format (e.g., '10.0.0.0/8', '192.168.1.0/24'). Please check the format of provided IP ranges."
  }

  validation {
    condition = var.security_settings == null || var.security_settings.allowed_service_tags_for_firewall == null || alltrue([
      for tag in var.security_settings.allowed_service_tags_for_firewall :
      length(tag) > 0 && length(tag) <= 80
    ])
    error_message = "Service tags must be 1-80 characters long. Please provide valid Azure service tag names."
  }
}

variable "feature_settings" {
  type = object({
    # Power Apps component framework
    power_apps_component_framework_for_canvas_apps = optional(bool)

    # User interface behaviors
    show_dashboard_cards_in_expanded_state = optional(bool)
  })

  default     = null
  description = <<DESCRIPTION
Power Platform feature enablement and user interface behavior configuration.

Controls advanced Power Platform features and user experience settings to optimize
the environment for specific organizational needs and user preferences.

Properties:
- power_apps_component_framework_for_canvas_apps: Enable Power Apps Component Framework (PCF) for canvas apps
- show_dashboard_cards_in_expanded_state: Display dashboard cards in expanded state by default

Example:
feature_settings = {
  power_apps_component_framework_for_canvas_apps = true
  show_dashboard_cards_in_expanded_state         = false
}

Feature Benefits:
- PCF enables advanced custom components in canvas apps
- Dashboard settings improve user experience and productivity
- Provides consistent user interface behavior across the organization
- Supports modern app development patterns and best practices
DESCRIPTION
}

variable "email_settings" {
  type = object({
    max_upload_file_size_in_bytes = optional(number)
  })

  default     = null
  description = <<DESCRIPTION
Email and file handling configuration for Power Platform environment.

Controls file upload limits and email-related settings to ensure proper
resource utilization and prevent abuse while supporting legitimate business needs.

Properties:
- max_upload_file_size_in_bytes: Maximum file upload size in bytes (1 to 131,072,000 bytes / 125 MB)

Example:
email_settings = {
  max_upload_file_size_in_bytes = 52428800  # 50 MB limit
}

Business Benefits:
- Prevents excessive storage consumption from large file uploads
- Ensures consistent file size policies across environments
- Supports compliance with data governance policies
- Optimizes environment performance and resource utilization
DESCRIPTION

  validation {
    condition     = var.email_settings == null || var.email_settings.max_upload_file_size_in_bytes == null || (var.email_settings.max_upload_file_size_in_bytes > 0 && var.email_settings.max_upload_file_size_in_bytes <= 131072000)
    error_message = "Maximum upload file size must be between 1 and 131,072,000 bytes (125 MB). Current value: '${try(var.email_settings.max_upload_file_size_in_bytes, "null")}'. Please set to a valid file size limit within Power Platform constraints."
  }
}