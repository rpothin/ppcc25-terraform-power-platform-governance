# Power Platform Environment Settings Configuration
#
# This configuration manages Power Platform environment settings to control various
# aspects of Power Platform features and behaviors after environment creation,
# enabling standardized governance and compliance controls through Infrastructure as Code
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Follows AVM patterns for resource modules (res-*) with comprehensive validation
# - Anti-Corruption Layer: Discrete outputs instead of full resource exposure for interface stability  
# - Security-First: OIDC authentication, input validation, and sensitive data protection
# - Resource Deployment: Deploys primary Power Platform resources with lifecycle management
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform`
# - Lifecycle Management: Resource modules include `ignore_changes` for manual admin center changes
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single environment settings resource with comprehensive nested configuration
# - Post-Creation Management: Designed to configure environments after creation, complementing res-environment
#
# Environment Lifecycle Progression:
# 1. res-environment: Creates the environment 
# 2. res-environment-application-admin: Assigns permissions
# 3. res-environment-settings: Configures environment settings (this module)


# Main resource: Power Platform Environment Settings
# Manages comprehensive environment configuration for governance and compliance
resource "powerplatform_environment_settings" "this" {
  environment_id = var.environment_settings_config.environment_id

  # Audit and logging configuration for compliance tracking
  # Controls what activities are logged and for how long
  audit_and_logs = var.environment_settings_config.audit_and_logs != null ? {
    # Plugin trace logging for troubleshooting and monitoring
    plugin_trace_log_setting = var.environment_settings_config.audit_and_logs.plugin_trace_log_setting

    # Comprehensive audit settings for compliance and security
    audit_settings = var.environment_settings_config.audit_and_logs.audit_settings != null ? {
      is_audit_enabled             = var.environment_settings_config.audit_and_logs.audit_settings.is_audit_enabled
      is_user_access_audit_enabled = var.environment_settings_config.audit_and_logs.audit_settings.is_user_access_audit_enabled
      is_read_audit_enabled        = var.environment_settings_config.audit_and_logs.audit_settings.is_read_audit_enabled
      log_retention_period_in_days = var.environment_settings_config.audit_and_logs.audit_settings.log_retention_period_in_days
    } : null
  } : null

  # Email configuration for file handling and communication settings
  email = var.environment_settings_config.email_settings != null ? {
    email_settings = var.environment_settings_config.email_settings.email_settings != null ? {
      max_upload_file_size_in_bytes = var.environment_settings_config.email_settings.email_settings.max_upload_file_size_in_bytes
    } : null
  } : null

  # Product-specific configuration controlling Power Platform features and behaviors
  product = var.environment_settings_config.product_settings != null ? {
    # Behavior settings controlling user interface and experience
    behavior_settings = var.environment_settings_config.product_settings.behavior_settings != null ? {
      show_dashboard_cards_in_expanded_state = var.environment_settings_config.product_settings.behavior_settings.show_dashboard_cards_in_expanded_state
    } : null

    # Feature enablement controls for Power Platform capabilities
    features = var.environment_settings_config.product_settings.features != null ? {
      power_apps_component_framework_for_canvas_apps = var.environment_settings_config.product_settings.features.power_apps_component_framework_for_canvas_apps
    } : null

    # Security settings for access control and network protection
    # WORKAROUND: Provider bug fix - explicitly set empty collections for optional attributes
    security = var.environment_settings_config.product_settings.security != null ? {
      allow_application_user_access               = var.environment_settings_config.product_settings.security.allow_application_user_access
      allow_microsoft_trusted_service_tags        = var.environment_settings_config.product_settings.security.allow_microsoft_trusted_service_tags
      enable_ip_based_firewall_rule               = var.environment_settings_config.product_settings.security.enable_ip_based_firewall_rule
      enable_ip_based_firewall_rule_in_audit_mode = var.environment_settings_config.product_settings.security.enable_ip_based_firewall_rule_in_audit_mode

      # Provider bug workaround: Set empty collections instead of null to prevent inconsistency errors
      # Issue: microsoft/terraform-provider-power-platform provider converts null to empty sets after apply
      allowed_ip_range_for_firewall     = var.environment_settings_config.product_settings.security.allowed_ip_range_for_firewall != null ? var.environment_settings_config.product_settings.security.allowed_ip_range_for_firewall : []
      allowed_service_tags_for_firewall = var.environment_settings_config.product_settings.security.allowed_service_tags_for_firewall != null ? var.environment_settings_config.product_settings.security.allowed_service_tags_for_firewall : []
      reverse_proxy_ip_addresses        = var.environment_settings_config.product_settings.security.reverse_proxy_ip_addresses != null ? var.environment_settings_config.product_settings.security.reverse_proxy_ip_addresses : []
    } : null
  } : null

  # Lifecycle management for manual admin center changes
  # Allows administrators to make manual adjustments without Terraform interference
  lifecycle {
    ignore_changes = [
      # Allow manual changes to audit settings in admin center
      audit_and_logs,
      # Allow manual changes to email settings
      email,
      # Allow manual changes to product configurations
      product
    ]
  }
}