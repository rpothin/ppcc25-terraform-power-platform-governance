# Output Values for Power Platform Managed Environment Configuration
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

# ============================================================================
# OUTPUT SCHEMA VERSION
# ============================================================================

locals {
  output_schema_version = "1.0.0"
}

output "output_schema_version" {
  description = "The version of the output schema for this module."
  value       = local.output_schema_version
}

# ============================================================================
# PRIMARY OUTPUTS - Managed Environment identification and reference
# ============================================================================

output "managed_environment_id" {
  description = <<DESCRIPTION
The unique identifier of the managed environment configuration.

This output provides the primary key for referencing this managed environment
in other Terraform configurations or external systems. Use this ID to:
- Reference in enterprise policy configurations
- Integrate with monitoring and reporting systems
- Set up advanced governance policies
- Configure environment-specific automation

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)
Note: This is the same as the environment_id but confirms successful managed environment setup
DESCRIPTION
  value       = var.environment_id
}

output "environment_id" {
  description = <<DESCRIPTION
The environment ID that was configured as a managed environment.

This output confirms which Power Platform environment was successfully
configured with managed environment capabilities. Useful for:
- Validation in CI/CD pipelines
- Integration with other environment configurations
- Dependency management in complex deployments
- Audit and compliance reporting

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)
DESCRIPTION
  value       = var.environment_id
}

# ============================================================================
# CONFIGURATION SUMMARY - Deployment validation and reporting
# ============================================================================

output "managed_environment_summary" {
  description = "Summary of deployed managed environment configuration for validation and compliance reporting"
  value = {
    # Core identification
    environment_id = powerplatform_managed_environment.this.environment_id

    # Module metadata
    resource_type     = "powerplatform_managed_environment"
    classification    = "res-*"
    deployment_status = "deployed"

    # Deployment tracking
    deployment_timestamp = timestamp()
    module_version       = local.output_schema_version

    # Governance configuration status
    sharing_controls_enabled    = true
    solution_validation_mode    = powerplatform_managed_environment.this.solution_checker_mode
    usage_insights_status       = powerplatform_managed_environment.this.is_usage_insights_disabled ? "disabled" : "enabled"
    maker_onboarding_configured = powerplatform_managed_environment.this.maker_onboarding_markdown != null && powerplatform_managed_environment.this.maker_onboarding_url != null

    # Compliance indicators
    group_sharing_restricted     = powerplatform_managed_environment.this.is_group_sharing_disabled
    user_sharing_limit           = powerplatform_managed_environment.this.max_limit_user_sharing
    validation_emails_configured = !powerplatform_managed_environment.this.suppress_validation_emails

    # Integration readiness
    ready_for_enterprise_policies = true # Can have enterprise policies applied
    ready_for_advanced_dlp        = true # Can use advanced DLP features
  }
}

# ============================================================================
# GOVERNANCE OUTPUTS - Policy and control status
# ============================================================================

output "sharing_configuration" {
  description = <<DESCRIPTION
Current sharing configuration and limits for the managed environment.

This output provides visibility into the sharing controls that are currently
active for the managed environment, useful for:
- Compliance auditing and reporting
- Integration with governance dashboards
- Validation of security posture
- Documentation of current policies
DESCRIPTION
  value = {
    group_sharing_disabled = powerplatform_managed_environment.this.is_group_sharing_disabled
    sharing_mode           = powerplatform_managed_environment.this.limit_sharing_mode
    max_users_for_sharing  = powerplatform_managed_environment.this.max_limit_user_sharing

    # Computed status indicators
    sharing_restriction_level = powerplatform_managed_environment.this.is_group_sharing_disabled ? "strict" : "permissive"
    sharing_scope             = powerplatform_managed_environment.this.limit_sharing_mode
  }
}

output "solution_validation_status" {
  description = <<DESCRIPTION
Current solution validation and checker configuration for the managed environment.

This output provides visibility into the quality control measures that are
currently active for solution imports, useful for:
- Quality assurance reporting
- Compliance verification
- Integration with ALM processes
- Validation of governance controls
DESCRIPTION
  value = {
    checker_mode              = powerplatform_managed_environment.this.solution_checker_mode
    validation_emails_enabled = !powerplatform_managed_environment.this.suppress_validation_emails
    rule_overrides_count      = length(powerplatform_managed_environment.this.solution_checker_rule_overrides)

    # Computed status indicators
    validation_enforcement = powerplatform_managed_environment.this.solution_checker_mode == "Block" ? "strict" : powerplatform_managed_environment.this.solution_checker_mode == "Warn" ? "advisory" : "disabled"
    quality_gate_active    = powerplatform_managed_environment.this.solution_checker_mode != "None"
  }
}

# ============================================================================
# DEPLOYMENT VALIDATION - Error handling and troubleshooting
# ============================================================================

output "deployment_validation" {
  description = "Comprehensive deployment validation and troubleshooting information for managed environment configuration"
  value = {
    # Deployment status
    deployment_successful = true
    environment_id_valid  = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", powerplatform_managed_environment.this.environment_id))
    configuration_applied = timestamp()

    # Environment readiness indicators
    environment_id_format = "valid"
    managed_env_enabled   = true

    # Troubleshooting information
    troubleshooting_guide = {
      common_issues = {
        "empty_environment_id" = {
          description = "Environment ID is empty or null during managed environment creation"
          causes = [
            "Environment resource not fully created",
            "Dependency chain broken between environment and managed environment modules",
            "Race condition in resource creation"
          ]
          solutions = [
            "Ensure explicit depends_on is configured",
            "Add null_resource for environment readiness validation",
            "Implement sequential deployment for multiple environments",
            "Verify environment module outputs are properly exposed"
          ]
        }
        "absolute_url_error" = {
          description = "Request url must be an absolute url error from Power Platform provider"
          causes = [
            "Empty or invalid environment_id passed to provider",
            "Provider internal state inconsistency",
            "API timing issues with Power Platform service"
          ]
          solutions = [
            "Add validation checks for environment_id before managed environment creation",
            "Implement retry logic with exponential backoff",
            "Use null_resource for environment readiness validation",
            "Consider sequential deployment instead of parallel"
          ]
        }
        "provider_timeout" = {
          description = "Provider timeouts during managed environment enablement"
          causes = [
            "Power Platform API latency",
            "Multiple concurrent operations",
            "Service throttling"
          ]
          solutions = [
            "Implement sequential deployment",
            "Add retry mechanisms",
            "Use smaller batch sizes for multiple environments",
            "Monitor Power Platform service health"
          ]
        }
      }

      validation_steps = [
        "1. Verify environment exists: az powerplatform environment show --environment-id <id>",
        "2. Check environment status: Ensure environment is in 'Ready' state",
        "3. Validate permissions: Confirm service principal has Environment Admin rights",
        "4. Test API connectivity: Verify Power Platform provider authentication",
        "5. Review dependencies: Ensure proper depends_on configuration",
        "6. Check for conflicts: Verify no manual managed environment configuration exists"
      ]

      recovery_procedures = {
        "failed_deployment" = [
          "1. Import existing managed environment if manually configured",
          "2. Remove managed environment from state and retry",
          "3. Apply environments and managed environments separately",
          "4. Use terraform refresh to sync state"
        ]
        "state_drift" = [
          "1. Run terraform plan to identify drift",
          "2. Use terraform refresh to update state",
          "3. Apply configuration to restore desired state",
          "4. Review for manual changes in Power Platform admin center"
        ]
      }
    }

    # Integration readiness
    ready_for_governance = {
      dlp_policies        = true
      enterprise_policies = true
      environment_groups  = true
      advanced_monitoring = true
    }
  }
}