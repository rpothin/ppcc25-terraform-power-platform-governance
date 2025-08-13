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

    # Settings categories applied (based on input configuration)
    audit_and_logs_configured   = var.environment_settings_config.audit_and_logs != null
    email_settings_configured   = var.environment_settings_config.email_settings != null
    product_settings_configured = var.environment_settings_config.product_settings != null

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

    # Applied configuration details
    audit_configuration = var.environment_settings_config.audit_and_logs != null ? {
      plugin_tracing_enabled = var.environment_settings_config.audit_and_logs.plugin_trace_log_setting != null
      audit_settings_applied = var.environment_settings_config.audit_and_logs.audit_settings != null
      compliance_ready       = true
    } : null

    email_configuration = var.environment_settings_config.email_settings != null ? {
      upload_limits_configured = var.environment_settings_config.email_settings.email_settings != null
      file_handling_managed    = true
    } : null

    product_configuration = var.environment_settings_config.product_settings != null ? {
      behavior_settings_applied  = var.environment_settings_config.product_settings.behavior_settings != null
      features_configured        = var.environment_settings_config.product_settings.features != null
      security_settings_applied  = var.environment_settings_config.product_settings.security != null
      governance_controls_active = true
    } : null

    # Integration context
    complements_configurations = [
      "res-environment (environment creation)",
      "res-environment-application-admin (permission assignment)"
    ]

    # Operational notes
    manual_override_supported = "Manual changes in Power Platform admin center are preserved via lifecycle ignore_changes"
    drift_detection_note      = "Configuration drift from manual changes will not trigger Terraform updates"
  }
}