# Output Values for Power Platform Environment Group Rule Set Configuration
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
# PRIMARY OUTPUTS - Environment Group Rule Set identification and reference
# ============================================================================

output "environment_group_rule_set_id" {
  description = <<DESCRIPTION
The unique identifier of the created Power Platform Environment Group Rule Set.

This output provides the primary key for referencing this rule set in other
Terraform configurations or external systems. Use this ID to:
- Reference the rule set in monitoring and compliance systems
- Integrate with governance reporting workflows
- Coordinate with environment management automations
- Track rule set deployment status and configuration

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)
DESCRIPTION
  value       = powerplatform_environment_group_rule_set.this.id
}

output "environment_group_id" {
  description = <<DESCRIPTION
The environment group ID that this rule set is applied to.

This output provides the target environment group identifier for validation
and integration purposes. Useful for:
- Confirming successful deployment to the correct group
- Integration with environment group management workflows
- Validation in CI/CD pipelines
- Cross-reference with environment routing configurations
DESCRIPTION
  value       = powerplatform_environment_group_rule_set.this.environment_group_id
}

# ============================================================================
# CONFIGURATION SUMMARY - Deployment validation and reporting
# ============================================================================

output "rule_set_configuration_summary" {
  description = "Summary of deployed environment group rule set configuration for validation and compliance reporting"
  value = {
    # Core identification
    rule_set_id          = powerplatform_environment_group_rule_set.this.id
    environment_group_id = powerplatform_environment_group_rule_set.this.environment_group_id

    # Module metadata
    resource_type     = "powerplatform_environment_group_rule_set"
    classification    = "res-*"
    deployment_status = "deployed"

    # Deployment tracking
    deployment_timestamp = timestamp()
    module_version       = local.output_schema_version

    # Rule configuration summary
    rules_configured = {
      sharing_controls             = var.rules.sharing_controls != null
      usage_insights               = var.rules.usage_insights != null
      maker_welcome_content        = var.rules.maker_welcome_content != null
      solution_checker_enforcement = var.rules.solution_checker_enforcement != null
      backup_retention             = var.rules.backup_retention != null
      ai_generated_descriptions    = var.rules.ai_generated_descriptions != null
      ai_generative_settings       = var.rules.ai_generative_settings != null
    }

    # Configuration details (non-sensitive)
    rule_count = length([
      for rule_type, rule_config in var.rules : rule_type
      if rule_config != null
    ])

    # Integration readiness
    ready_for_environment_assignment = true # Can assign environments to this group
    ready_for_governance_reporting   = true # Can be included in compliance reports

    # Governance configuration highlights
    has_sharing_controls = var.rules.sharing_controls != null
    has_solution_checker = var.rules.solution_checker_enforcement != null
    has_backup_retention = var.rules.backup_retention != null
    has_ai_governance    = var.rules.ai_generative_settings != null
  }
}