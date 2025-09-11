# Output Values for res-dlp-policy
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.
#
# Output Categories:
# - Resource Identifiers: Primary keys for downstream references
# - Computed Values: Derived attributes useful for integration
# - Summary Information: Aggregated data for reporting
# - Security Attributes: Access-related information (marked sensitive)
# - Helper Outputs: Troubleshooting and validation support

output "dlp_policy_id" {
  description = <<DESCRIPTION
The unique identifier of the DLP policy.
This output provides the primary key for referencing this resource in other Terraform configurations or external systems. The ID format follows Power Platform standards.
DESCRIPTION
  value       = powerplatform_data_loss_prevention_policy.this.id
}

output "dlp_policy_display_name" {
  description = "The display name of the DLP policy."
  value       = powerplatform_data_loss_prevention_policy.this.display_name
}

output "dlp_policy_environment_type" {
  description = "The environment type for the DLP policy."
  value       = powerplatform_data_loss_prevention_policy.this.environment_type
}

# Required summary outputs per terraform-iac instructions for resource modules
output "policy_configuration_summary" {
  description = <<DESCRIPTION
Comprehensive summary of deployed DLP policy configuration for validation and governance reporting.
This output aggregates key configuration details following the AVM pattern for resource modules.
Used by pattern modules and governance systems for compliance monitoring.
DESCRIPTION
  value = {
    # Core identification
    policy_id                         = powerplatform_data_loss_prevention_policy.this.id
    display_name                      = powerplatform_data_loss_prevention_policy.this.display_name
    default_connectors_classification = powerplatform_data_loss_prevention_policy.this.default_connectors_classification

    # Environment scope
    environment_type = powerplatform_data_loss_prevention_policy.this.environment_type
    environments     = powerplatform_data_loss_prevention_policy.this.environments

    # Connector classification metrics
    business_connectors_count     = length(var.business_connectors)
    non_business_connectors_count = length(local.auto_non_business_connectors)
    blocked_connectors_count      = length(local.auto_blocked_connectors)
    custom_connector_patterns     = length(var.custom_connectors_patterns)

    # Deployment metadata
    deployment_status = "deployed"
    last_modified     = timestamp()
    terraform_managed = true

    # Auto-classification detection
    uses_auto_classification = (
      length(var.non_business_connectors) == 0 || length(var.blocked_connectors) == 0
    )
    total_connectors_managed = (
      length(var.business_connectors) +
      length(local.auto_non_business_connectors) +
      length(local.auto_blocked_connectors)
    )
  }
}

output "connector_classification_summary" {
  description = <<DESCRIPTION
Summary of connector classifications applied by the DLP policy for audit and compliance reporting.
Provides detailed breakdown of connectors by data group classification with security posture analysis.
Used for governance dashboards and compliance auditing systems.
DESCRIPTION
  value = {
    # Classification totals
    total_connectors = (
      length(var.business_connectors) +
      length(local.auto_non_business_connectors) +
      length(local.auto_blocked_connectors)
    )

    # By classification type
    business_data_group = {
      count      = length(var.business_connectors)
      connectors = [for c in var.business_connectors : c.id]
    }

    non_business_data_group = {
      count      = length(local.auto_non_business_connectors)
      connectors = [for c in local.auto_non_business_connectors : c.id]
    }

    blocked_data_group = {
      count      = length(local.auto_blocked_connectors)
      connectors = [for c in local.auto_blocked_connectors : c.id]
    }

    # Custom connector governance
    custom_connector_governance = {
      patterns_defined = length(var.custom_connectors_patterns)
      default_action   = length(var.custom_connectors_patterns) > 0 ? var.custom_connectors_patterns[0].data_group : "Not configured"
    }

    # Security posture indicator
    security_posture = var.default_connectors_classification == "Blocked" ? "Restrictive" : "Permissive"
  }
}