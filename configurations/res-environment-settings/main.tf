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
# - Focused Variables: Decomposed object variables following AVM SNFR14 best practices
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single environment settings resource with comprehensive nested configuration
# - Post-Creation Management: Designed to configure environments after creation, complementing res-environment
# - Variable Design: Focused objects instead of monolithic configuration for better user experience
#
# Environment Lifecycle Progression:
# 1. res-environment: Creates the environment 
# 2. res-environment-application-admin: Assigns permissions
# 3. res-environment-settings: Configures environment settings (this module)


# Main resource: Power Platform Environment Settings
# Manages comprehensive environment configuration for governance and compliance
resource "powerplatform_environment_settings" "this" {
  environment_id = var.environment_id

  # Audit and logging configuration for compliance tracking
  # Controls what activities are logged and for how long
  audit_and_logs = var.audit_settings != null ? {
    # Plugin trace logging for troubleshooting and monitoring
    plugin_trace_log_setting = var.audit_settings.plugin_trace_log_setting

    # Comprehensive audit settings for compliance and security
    # Convert flat audit_settings to nested structure required by provider
    audit_settings = (
      var.audit_settings.is_audit_enabled != null ||
      var.audit_settings.is_user_access_audit_enabled != null ||
      var.audit_settings.is_read_audit_enabled != null ||
      var.audit_settings.log_retention_period_in_days != null
      ) ? {
      is_audit_enabled             = var.audit_settings.is_audit_enabled
      is_user_access_audit_enabled = var.audit_settings.is_user_access_audit_enabled
      is_read_audit_enabled        = var.audit_settings.is_read_audit_enabled
      log_retention_period_in_days = var.audit_settings.log_retention_period_in_days
    } : null
  } : null

  # Email configuration for file handling and communication settings
  email = var.email_settings != null ? {
    email_settings = var.email_settings.max_upload_file_size_in_bytes != null ? {
      max_upload_file_size_in_bytes = var.email_settings.max_upload_file_size_in_bytes
    } : null
  } : null

  # Product-specific configuration controlling Power Platform features and behaviors
  product = (var.feature_settings != null || var.security_settings != null) ? {
    # Behavior settings controlling user interface and experience
    behavior_settings = var.feature_settings != null && var.feature_settings.show_dashboard_cards_in_expanded_state != null ? {
      show_dashboard_cards_in_expanded_state = var.feature_settings.show_dashboard_cards_in_expanded_state
    } : null

    # Feature enablement controls for Power Platform capabilities
    features = var.feature_settings != null && var.feature_settings.power_apps_component_framework_for_canvas_apps != null ? {
      power_apps_component_framework_for_canvas_apps = var.feature_settings.power_apps_component_framework_for_canvas_apps
    } : null

    # Security settings for access control and network protection
    # WORKAROUND: Provider bug fix - explicitly set empty collections for optional attributes
    security = var.security_settings != null ? {
      allow_application_user_access               = var.security_settings.allow_application_user_access
      allow_microsoft_trusted_service_tags        = var.security_settings.allow_microsoft_trusted_service_tags
      enable_ip_based_firewall_rule               = var.security_settings.enable_ip_based_firewall_rule
      enable_ip_based_firewall_rule_in_audit_mode = var.security_settings.enable_ip_based_firewall_rule_in_audit_mode

      # Provider bug workaround: Set empty collections instead of null to prevent inconsistency errors
      # Issue: microsoft/terraform-provider-power-platform provider converts null to empty sets after apply
      allowed_ip_range_for_firewall     = var.security_settings.allowed_ip_range_for_firewall != null ? var.security_settings.allowed_ip_range_for_firewall : []
      allowed_service_tags_for_firewall = var.security_settings.allowed_service_tags_for_firewall != null ? var.security_settings.allowed_service_tags_for_firewall : []
      reverse_proxy_ip_addresses        = var.security_settings.reverse_proxy_ip_addresses != null ? var.security_settings.reverse_proxy_ip_addresses : []
    } : null
  } : null

  # Lifecycle management for manual admin center changes
  # Allows administrators to make manual adjustments without Terraform interference
  lifecycle {
    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []
  }
}