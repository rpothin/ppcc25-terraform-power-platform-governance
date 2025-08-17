# Output Values for Power Platform Environment Group Pattern Configuration
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
  description = "The version of the output schema for this pattern module."
  value       = local.output_schema_version
}

# ============================================================================
# PRIMARY OUTPUTS - Environment Group and Environment identification
# ============================================================================

output "environment_group_id" {
  description = <<DESCRIPTION
The unique identifier of the created Power Platform Environment Group.

This output provides the primary key for referencing the environment group
created by this pattern. Use this ID to:
- Configure additional governance policies targeting this group
- Reference the group in external configuration management systems
- Set up environment routing rules and rule sets
- Integrate with monitoring and compliance reporting systems

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)
DESCRIPTION
  value       = module.environment_group.environment_group_id
}

output "environment_group_name" {
  description = <<DESCRIPTION
The display name of the created environment group.

This output provides the human-readable name for validation and reporting purposes.
Useful for:
- Confirming successful pattern deployment with expected naming
- Integration with external documentation and governance systems
- Validation in CI/CD pipelines and automated testing
- User-facing reports and operational dashboards
DESCRIPTION
  value       = module.environment_group.environment_group_name
}

output "environment_ids" {
  description = <<DESCRIPTION
Map of environment identifiers created by this pattern.

This output provides the unique identifiers for all environments created
and assigned to the environment group. The map uses the array index as the
key and the environment ID as the value.

Format: Map where each value is a GUID
Usage: Reference specific environments by index for additional configuration
DESCRIPTION
  value = {
    for idx, env_module in module.environments : idx => env_module.environment_id
  }
}

output "environment_names" {
  description = <<DESCRIPTION
Map of environment display names created by this pattern.

This output provides the human-readable names for all environments
created as part of this pattern, useful for validation and reporting.

Format: Map where each value is the environment display name
Usage: Validation, reporting, and cross-reference with environment IDs
DESCRIPTION
  value = {
    for idx, env in var.environments : idx => env.display_name
  }
}

# ============================================================================
# ORCHESTRATION SUMMARY - Pattern deployment validation and reporting
# ============================================================================

output "orchestration_summary" {
  description = "Summary of pattern deployment status and multi-resource orchestration results"
  value = {
    # Pattern identification
    pattern_type      = local.pattern_metadata.pattern_type
    pattern_version   = local.output_schema_version
    deployment_status = "deployed"

    # Resource orchestration metrics
    total_resources_created = local.pattern_metadata.resource_count
    environment_group_id    = local.pattern_metadata.environment_group_id
    environments_created    = local.pattern_metadata.created_environments

    # Dependency validation
    dependency_chain_valid = local.deployment_validation.all_environments_created
    group_assignment_valid = local.deployment_validation.group_assignment_valid
    pattern_complete       = local.deployment_validation.pattern_complete

    # Environment details
    environment_summary = local.environment_summary

    # Deployment tracking
    deployment_timestamp = timestamp()
    module_version       = local.output_schema_version

    # Integration readiness
    ready_for_governance = true # Pattern creates governable resource structure
    ready_for_policies   = true # Environment group can have DLP policies applied
    ready_for_routing    = true # Environment group can be used for routing rules
  }
}

# ============================================================================
# GOVERNANCE INTEGRATION - Outputs for downstream governance configuration
# ============================================================================

output "governance_ready_resources" {
  description = "Map of resources ready for governance configuration and policy application"
  value = {
    environment_group = {
      id               = module.environment_group.environment_group_id
      name             = module.environment_group.environment_group_name
      resource_type    = "powerplatform_environment_group"
      governance_ready = true
      policy_targets   = ["dlp_policies", "routing_rules", "environment_rules"]
    }

    environments = {
      for idx, env_module in module.environments : idx => {
        id                 = env_module.environment_id
        name               = var.environments[idx].display_name
        resource_type      = "powerplatform_environment"
        environment_type   = var.environments[idx].environment_type
        group_membership   = module.environment_group.environment_group_id
        governance_ready   = true
        policy_inheritance = "from_group" # Inherits policies from environment group
      }
    }
  }
}

# ============================================================================
# CONFIGURATION SUMMARY - Deployment validation and compliance reporting
# ============================================================================

output "pattern_configuration_summary" {
  description = "Comprehensive summary of pattern configuration for audit and compliance reporting"
  value = {
    # Input validation summary
    environment_group_config = {
      display_name = var.environment_group_config.display_name
      description  = var.environment_group_config.description
      name_length  = length(var.environment_group_config.display_name)
      desc_length  = length(var.environment_group_config.description)
    }

    # Environment configuration summary
    environments_config = {
      count                = length(var.environments)
      duplicate_protection = var.enable_duplicate_protection
      environment_types    = [for env in var.environments : env.environment_type]
      locations            = [for env in var.environments : env.location]
      unique_names         = length(distinct([for env in var.environments : env.display_name])) == length(var.environments)
      dataverse_enabled    = true # Required for environment group assignment
    }

    # Pattern orchestration summary
    orchestration_results = {
      pattern_executed      = true
      resources_deployed    = local.pattern_metadata.resource_count
      dependency_order      = ["environment_group", "environments"]
      group_assignment_mode = "automatic"
      validation_passed     = local.deployment_validation.pattern_complete
    }

    # Compliance and audit information
    compliance_info = {
      avm_compliance        = "adapted" # AVM-inspired with Power Platform adaptations
      security_model        = "oidc_only"
      provider_version      = "~> 3.8"
      anti_corruption_layer = true
      lifecycle_protection  = "enabled_on_environments"
    }
  }
}