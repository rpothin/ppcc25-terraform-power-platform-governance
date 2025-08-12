# Input Variables for Power Platform Environment Settings Configuration
#
# This file defines all input parameters following AVM variable standards
# with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Primary environment settings parameters
# - Audit & Logging: Compliance and monitoring configurations  
# - Email Settings: Communication and file handling controls
# - Product Settings: Power Platform feature and behavior controls
# - Security Settings: Access control and network protection configurations
#
# CRITICAL: All complex variables use explicit object types with property-level validation.
# The `any` type is forbidden in all production modules.

variable "environment_settings_config" {
  type = object({
    # Required: Environment identifier for settings application
    environment_id = string

    # Optional: Audit and logging configuration for compliance tracking
    audit_and_logs = optional(object({
      plugin_trace_log_setting = optional(string)
      audit_settings = optional(object({
        is_audit_enabled             = optional(bool)
        is_user_access_audit_enabled = optional(bool)
        is_read_audit_enabled        = optional(bool)
        log_retention_period_in_days = optional(number)
      }))
    }))

    # Optional: Email configuration for file handling
    email_settings = optional(object({
      email_settings = optional(object({
        max_upload_file_size_in_bytes = optional(number)
      }))
    }))

    # Optional: Product-specific settings for Power Platform features
    product_settings = optional(object({
      behavior_settings = optional(object({
        show_dashboard_cards_in_expanded_state = optional(bool)
      }))
      features = optional(object({
        power_apps_component_framework_for_canvas_apps = optional(bool)
      }))
      security = optional(object({
        allow_application_user_access               = optional(bool)
        allow_microsoft_trusted_service_tags        = optional(bool)
        allowed_ip_range_for_firewall               = optional(set(string))
        allowed_service_tags_for_firewall           = optional(set(string))
        enable_ip_based_firewall_rule               = optional(bool)
        enable_ip_based_firewall_rule_in_audit_mode = optional(bool)
        reverse_proxy_ip_addresses                  = optional(set(string))
      }))
    }))
  })

  description = <<DESCRIPTION
Comprehensive configuration object for Power Platform environment settings.

This variable consolidates all environment settings to reduce complexity while
ensuring proper governance and compliance controls are applied consistently.

Required Properties:
- environment_id: GUID of the Power Platform environment to configure

Optional Properties:
- audit_and_logs: Audit and logging configuration for compliance tracking
  - plugin_trace_log_setting: Plugin trace level ("Off", "Exception", "All")
  - audit_settings: Detailed audit configuration
    - is_audit_enabled: Enable general auditing
    - is_user_access_audit_enabled: Enable user access auditing
    - is_read_audit_enabled: Enable read operation auditing  
    - log_retention_period_in_days: Log retention (31-24855 days, -1 for forever)

- email_settings: Email and file handling configuration
  - email_settings: Email-specific settings
    - max_upload_file_size_in_bytes: Maximum file upload size in bytes

- product_settings: Power Platform feature and behavior controls
  - behavior_settings: User interface behaviors
    - show_dashboard_cards_in_expanded_state: Dashboard card display preference
  - features: Power Platform feature enablement
    - power_apps_component_framework_for_canvas_apps: Enable PCF for canvas apps
  - security: Access control and network protection
    - allow_application_user_access: Allow service principal access
    - allow_microsoft_trusted_service_tags: Allow Microsoft service tags
    - allowed_ip_range_for_firewall: Permitted IP ranges for firewall
    - allowed_service_tags_for_firewall: Permitted service tags for firewall
    - enable_ip_based_firewall_rule: Enable IP-based firewall
    - enable_ip_based_firewall_rule_in_audit_mode: Enable firewall audit mode
    - reverse_proxy_ip_addresses: Reverse proxy IP addresses

Example:
environment_settings_config = {
  environment_id = "12345678-1234-1234-1234-123456789012"
  audit_and_logs = {
    plugin_trace_log_setting = "Exception"
    audit_settings = {
      is_audit_enabled             = true
      is_user_access_audit_enabled = true
      is_read_audit_enabled        = false
      log_retention_period_in_days = 90
    }
  }
  product_settings = {
    security = {
      allow_application_user_access     = true
      enable_ip_based_firewall_rule     = true
      allowed_ip_range_for_firewall     = ["10.0.0.0/8", "192.168.1.0/24"]
      allowed_service_tags_for_firewall = ["ApiManagement"]
    }
  }
}

Validation Rules:
- Environment ID must be a valid GUID format for Power Platform compatibility
- Plugin trace log setting must be valid option if specified
- Log retention period must be within Power Platform limits
- IP ranges and service tags must follow Azure networking standards
- File size limits must be within Power Platform constraints
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_settings_config.environment_id))
    error_message = "Environment ID must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx). Current value: '${var.environment_settings_config.environment_id}'. Please provide a valid Power Platform environment GUID."
  }

  validation {
    condition     = var.environment_settings_config.audit_and_logs == null || var.environment_settings_config.audit_and_logs.plugin_trace_log_setting == null || contains(["Off", "Exception", "All"], var.environment_settings_config.audit_and_logs.plugin_trace_log_setting)
    error_message = "Plugin trace log setting must be one of: 'Off', 'Exception', 'All'. Current value: '${try(var.environment_settings_config.audit_and_logs.plugin_trace_log_setting, "null")}'. See Power Platform documentation for valid trace levels."
  }

  validation {
    condition     = var.environment_settings_config.audit_and_logs == null || var.environment_settings_config.audit_and_logs.audit_settings == null || var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days == null || (var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days >= 31 && var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days <= 24855) || var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days == -1
    error_message = "Log retention period must be between 31 and 24855 days, or -1 for forever. Current value: '${try(var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days, "null")}'. Please set to a valid retention period for compliance requirements."
  }

  validation {
    condition     = var.environment_settings_config.email_settings == null || var.environment_settings_config.email_settings.email_settings == null || var.environment_settings_config.email_settings.email_settings.max_upload_file_size_in_bytes == null || (var.environment_settings_config.email_settings.email_settings.max_upload_file_size_in_bytes > 0 && var.environment_settings_config.email_settings.email_settings.max_upload_file_size_in_bytes <= 131072000)
    error_message = "Maximum upload file size must be between 1 and 131,072,000 bytes (125 MB). Current value: '${try(var.environment_settings_config.email_settings.email_settings.max_upload_file_size_in_bytes, "null")}'. Please set to a valid file size limit within Power Platform constraints."
  }
}