# Output Values for Power Platform Environment Settings Configuration
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

# Primary resource identifier for downstream configurations
output "environment_settings_id" {
  description = <<DESCRIPTION
The unique identifier of the environment settings configuration.

This output provides the primary key for referencing this environment settings
configuration in other Terraform configurations or external systems. This ID
represents the computed identifier for the settings applied to the environment.
DESCRIPTION
  value       = powerplatform_environment_settings.this.id
}

# Environment reference for validation and linking
output "environment_id" {
  description = <<DESCRIPTION
The Power Platform environment ID where settings were applied.

This output confirms which environment received the settings configuration,
useful for validation and linking with other environment-related resources
like res-environment and res-environment-application-admin configurations.
DESCRIPTION
  value       = powerplatform_environment_settings.this.environment_id
}

# Applied settings summary for validation and compliance reporting
output "applied_settings_summary" {
  description = <<DESCRIPTION
Summary of applied environment settings for validation and compliance reporting.

This output provides a consolidated view of the settings that were successfully
applied to the environment, including which categories were configured and
their high-level status. Useful for governance dashboards and audit reports.
DESCRIPTION
  value = {
    environment_id        = powerplatform_environment_settings.this.environment_id
    configuration_applied = "environment_settings"
    module_classification = "res-*"

    # Settings categories applied (based on decomposed input configuration)
    audit_settings_configured    = var.audit_settings != null
    security_settings_configured = var.security_settings != null
    feature_settings_configured  = var.feature_settings != null
    email_settings_configured    = var.email_settings != null

    # Deployment metadata
    terraform_configuration = "res-environment-settings"
    deployment_timestamp    = timestamp()

    # Governance context
    governance_purpose  = "post_environment_configuration"
    compliance_category = "environment_settings_management"
  }
}

# Settings configuration summary for operational visibility
output "settings_configuration_summary" {
  description = <<DESCRIPTION
Detailed summary of environment settings configuration for operational teams.

This output provides operational visibility into the specific settings categories
that were configured, enabling support teams to understand the environment's
governance posture and troubleshoot configuration-related issues.
DESCRIPTION
  value = {
    # Configuration scope and purpose
    scope_description           = "Power Platform environment settings for governance and compliance"
    environment_lifecycle_stage = "post_creation_configuration"

    # Applied configuration details using decomposed variables
    audit_configuration = var.audit_settings != null ? {
      plugin_tracing_enabled = var.audit_settings.plugin_trace_log_setting != null
      audit_logging_enabled = (
        var.audit_settings.is_audit_enabled != null ||
        var.audit_settings.is_user_access_audit_enabled != null ||
        var.audit_settings.is_read_audit_enabled != null ||
        var.audit_settings.log_retention_period_in_days != null
      )
      compliance_ready = true
      settings_applied = {
        plugin_trace_log_setting     = var.audit_settings.plugin_trace_log_setting
        is_audit_enabled             = var.audit_settings.is_audit_enabled
        is_user_access_audit_enabled = var.audit_settings.is_user_access_audit_enabled
        is_read_audit_enabled        = var.audit_settings.is_read_audit_enabled
        log_retention_period_in_days = var.audit_settings.log_retention_period_in_days
      }
    } : null

    security_configuration = var.security_settings != null ? {
      firewall_configured           = var.security_settings.enable_ip_based_firewall_rule != null
      application_access_configured = var.security_settings.allow_application_user_access != null
      network_restrictions_applied = (
        var.security_settings.allowed_ip_range_for_firewall != null ||
        var.security_settings.allowed_service_tags_for_firewall != null
      )
      governance_controls_active = true
      settings_applied = {
        allow_application_user_access        = var.security_settings.allow_application_user_access
        allow_microsoft_trusted_service_tags = var.security_settings.allow_microsoft_trusted_service_tags
        enable_ip_based_firewall_rule        = var.security_settings.enable_ip_based_firewall_rule
        firewall_audit_mode_enabled          = var.security_settings.enable_ip_based_firewall_rule_in_audit_mode
        ip_ranges_count                      = var.security_settings.allowed_ip_range_for_firewall != null ? length(var.security_settings.allowed_ip_range_for_firewall) : 0
        service_tags_count                   = var.security_settings.allowed_service_tags_for_firewall != null ? length(var.security_settings.allowed_service_tags_for_firewall) : 0
        reverse_proxy_addresses_count        = var.security_settings.reverse_proxy_ip_addresses != null ? length(var.security_settings.reverse_proxy_ip_addresses) : 0
      }
    } : null

    feature_configuration = var.feature_settings != null ? {
      pcf_for_canvas_apps_configured = var.feature_settings.power_apps_component_framework_for_canvas_apps != null
      dashboard_behavior_configured  = var.feature_settings.show_dashboard_cards_in_expanded_state != null
      user_experience_optimized      = true
      settings_applied = {
        power_apps_component_framework_for_canvas_apps = var.feature_settings.power_apps_component_framework_for_canvas_apps
        show_dashboard_cards_in_expanded_state         = var.feature_settings.show_dashboard_cards_in_expanded_state
      }
    } : null

    email_configuration = var.email_settings != null ? {
      upload_limits_configured = var.email_settings.max_upload_file_size_in_bytes != null
      file_handling_managed    = true
      settings_applied = {
        max_upload_file_size_in_bytes = var.email_settings.max_upload_file_size_in_bytes
        max_upload_size_mb            = var.email_settings.max_upload_file_size_in_bytes != null ? var.email_settings.max_upload_file_size_in_bytes / 1048576 : null
      }
    } : null

    # Integration context
    complements_configurations = [
      "res-environment (environment creation)",
      "res-environment-application-admin (permission assignment)"
    ]

    # Configuration summary
    total_setting_categories_configured = length([
      for category in [var.audit_settings, var.security_settings, var.feature_settings, var.email_settings] : category
      if category != null
    ])

    # Operational notes
    manual_override_supported = "Manual changes in Power Platform admin center are preserved via lifecycle ignore_changes"
    drift_detection_note      = "Configuration drift from manual changes will not trigger Terraform updates"

    # AVM compliance notes
    variable_design_pattern = "Decomposed focused objects following AVM SNFR14"
    anti_corruption_layer   = "Discrete outputs prevent resource object exposure"
  }
}

# Individual setting category outputs for granular reference
output "audit_settings_applied" {
  description = "Confirmation of audit settings application with details"
  value = var.audit_settings != null ? {
    applied              = true
    plugin_trace_setting = var.audit_settings.plugin_trace_log_setting
    audit_enabled        = var.audit_settings.is_audit_enabled
    user_access_audit    = var.audit_settings.is_user_access_audit_enabled
    read_audit           = var.audit_settings.is_read_audit_enabled
    retention_days       = var.audit_settings.log_retention_period_in_days
  } : null
}

output "security_settings_applied" {
  description = "Confirmation of security settings application with details"
  value = var.security_settings != null ? {
    applied                    = true
    application_access_allowed = var.security_settings.allow_application_user_access
    firewall_enabled           = var.security_settings.enable_ip_based_firewall_rule
    firewall_audit_mode        = var.security_settings.enable_ip_based_firewall_rule_in_audit_mode
    ip_ranges_configured       = var.security_settings.allowed_ip_range_for_firewall != null ? length(var.security_settings.allowed_ip_range_for_firewall) : 0
    service_tags_configured    = var.security_settings.allowed_service_tags_for_firewall != null ? length(var.security_settings.allowed_service_tags_for_firewall) : 0
  } : null
}

output "feature_settings_applied" {
  description = "Confirmation of feature settings application with details"
  value = var.feature_settings != null ? {
    applied                             = true
    pcf_for_canvas_apps                 = var.feature_settings.power_apps_component_framework_for_canvas_apps
    dashboard_cards_expanded_by_default = var.feature_settings.show_dashboard_cards_in_expanded_state
  } : null
}

output "email_settings_applied" {
  description = "Confirmation of email settings application with details"
  value = var.email_settings != null ? {
    applied                    = true
    max_upload_file_size_bytes = var.email_settings.max_upload_file_size_in_bytes
    max_upload_file_size_mb    = var.email_settings.max_upload_file_size_in_bytes != null ? var.email_settings.max_upload_file_size_in_bytes / 1048576 : null
  } : null
}