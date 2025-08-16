# Output Values for Power Platform Environment Group Configuration
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
# PRIMARY OUTPUTS - Environment Group identification and reference
# ============================================================================

output "environment_group_id" {
  description = <<DESCRIPTION
The unique identifier of the created Power Platform Environment Group.

This output provides the primary key for referencing this environment group
in other Terraform configurations or external systems. Use this ID to:
- Configure environment routing settings in tenant configuration
- Reference the group in environment creation resources
- Integrate with environment group rule set configurations
- Set up governance policies that target this specific group

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)
DESCRIPTION
  value       = powerplatform_environment_group.this.id
}

output "environment_group_name" {
  description = <<DESCRIPTION
The display name of the created environment group.

This output provides the human-readable name for validation and reporting purposes.
Useful for:
- Confirming successful deployment with expected naming
- Integration with external documentation systems
- Validation in CI/CD pipelines
- User-facing reports and dashboards
DESCRIPTION
  value       = powerplatform_environment_group.this.display_name
}

# ============================================================================
# CONFIGURATION SUMMARY - Deployment validation and reporting
# ============================================================================

output "environment_group_summary" {
  description = "Summary of deployed environment group configuration for validation and compliance reporting"
  value = {
    # Core identification
    id          = powerplatform_environment_group.this.id
    name        = powerplatform_environment_group.this.display_name
    description = powerplatform_environment_group.this.description

    # Module metadata
    resource_type     = "powerplatform_environment_group"
    classification    = "res-*"
    deployment_status = "deployed"

    # Deployment tracking
    deployment_timestamp = timestamp()
    module_version       = local.output_schema_version

    # Configuration validation
    name_length        = length(powerplatform_environment_group.this.display_name)
    description_length = length(powerplatform_environment_group.this.description)

    # Integration readiness
    ready_for_routing = true # Can be used for environment routing
    ready_for_rules   = true # Can have rule sets applied
  }
}