# Output Values for Power Platform Azure VNet Extension Pattern Configuration
#
# WHY: Pattern modules must provide anti-corruption layer outputs to prevent
# tight coupling between patterns and maintain clean interface boundaries
#
# CONTEXT: Phase 1 outputs focus on validation and planning data, Phase 2 will
# add infrastructure resource IDs for downstream consumption
#
# IMPACT: Clean output interfaces enable pattern composability and reduce
# breaking changes when internal implementations evolve

# ============================================================================
# OUTPUT SCHEMA VERSION
# ============================================================================

locals {
  output_schema_version = "1.0.0"
}

output "output_schema_version" {
  description = "The version of the output schema for this VNet extension pattern module."
  value       = local.output_schema_version
}

# ============================================================================
# CONFIGURATION VALIDATION OUTPUTS - Phase 1
# ============================================================================

output "configuration_validation_status" {
  description = <<DESCRIPTION
Comprehensive validation status of the VNet extension pattern configuration.

Reports the validation status of all configuration components including
remote state integration, environment processing, and network planning.
Essential for troubleshooting configuration issues before resource deployment.

Validation Components:
- remote_state_valid: Remote state from ptn-environment-group is accessible
- environments_found: Environment data successfully extracted from remote state
- subscriptions_different: Production and non-production subscriptions are distinct
- subnet_within_vnet: Power Platform subnet is properly allocated within VNet space
- names_generated: CAF-compliant resource names successfully generated
DESCRIPTION
  sensitive   = true
  value = {
    overall_valid           = local.configuration_valid
    remote_state_valid      = local.configuration_validation.remote_state_valid
    environments_found      = local.configuration_validation.environments_found
    subscriptions_different = local.configuration_validation.subscriptions_different
    primary_subnet_valid    = local.configuration_validation.primary_subnet_within_vnet
    failover_subnet_valid   = local.configuration_validation.failover_subnet_within_vnet
    names_generated         = local.configuration_validation.names_generated

    validation_errors = local.actual_validation_errors
    total_errors      = length(local.actual_validation_errors)
  }
}

output "remote_state_integration_summary" {
  description = <<DESCRIPTION
Summary of remote state integration from ptn-environment-group configuration.

Details the environment data successfully read from the remote state and
how it's being processed for VNet integration. Critical for verifying
proper integration between pattern modules.

Remote State Components:
- workspace_name: Base workspace name from environment group
- environments_discovered: Count of environments available for VNet integration
- environment_types: Distribution of environment types (Production, Sandbox, etc.)
- template_metadata: Template information from the environment group pattern
DESCRIPTION
  value = {
    remote_state_accessible = local.remote_state_valid
    workspace_name          = local.remote_workspace_name
    environments_discovered = length(local.remote_environment_ids)

    environment_summary = {
      for idx, env in local.processed_environments : idx => {
        name = env.environment_name
        type = env.environment_type
        id   = env.environment_id
      }
    }

    environment_types_distribution = {
      for env_type in distinct(values(local.remote_environment_types)) : env_type => length([
        for type in values(local.remote_environment_types) : type if type == env_type
      ])
    }

    template_metadata = local.remote_template_metadata
  }
}

output "network_planning_summary" {
  description = "Summary of network configuration planning for dual VNet architecture validation"
  sensitive   = true
  value = {
    primary_region = {
      location            = var.network_configuration.primary.location
      region_abbreviation = local.region_abbreviations[var.network_configuration.primary.location]
      base_address_space  = var.network_configuration.primary.vnet_address_space_base
      environment_count   = length(local.processed_environments)
    }

    failover_region = {
      location            = var.network_configuration.failover.location
      region_abbreviation = local.region_abbreviations[var.network_configuration.failover.location]
      base_address_space  = var.network_configuration.failover.vnet_address_space_base
      environment_count   = length(local.processed_environments)
    }

    # WHY: Show computed network allocation per environment
    # CONTEXT: Demonstrates dynamic IP calculation from base address spaces
    # IMPACT: Helps validate non-overlapping IP allocation across environments
    environment_networks = {
      for idx, env_name in keys(local.processed_environments) : env_name => {
        primary_vnet_cidr                = local.network_configuration[idx].primary_vnet_address_space
        primary_power_platform_subnet    = local.network_configuration[idx].primary_power_platform_subnet_cidr
        primary_private_endpoint_subnet  = local.network_configuration[idx].primary_private_endpoint_subnet_cidr
        failover_vnet_cidr               = local.network_configuration[idx].failover_vnet_address_space
        failover_power_platform_subnet   = local.network_configuration[idx].failover_power_platform_subnet_cidr
        failover_private_endpoint_subnet = local.network_configuration[idx].failover_private_endpoint_subnet_cidr
        environment_index                = idx
      }
    }

    validation_status = local.configuration_validation
  }
}

output "resource_naming_summary" {
  description = <<DESCRIPTION
CAF-compliant resource naming summary for all Azure resources.

Shows the generated resource names following Cloud Adoption Framework
naming conventions. Essential for validating naming consistency and
ensuring governance compliance across all environments.

Naming Components:
- Base components: Project, workspace, location abbreviations
- Patterns: CAF-compliant naming patterns for each resource type
- Generated names: Actual resource names for each environment
- Validation: Naming rule compliance and uniqueness checks
DESCRIPTION
  value = {
    base_naming_components = local.base_name_components
    naming_patterns        = local.naming_patterns

    per_environment_names = {
      for idx, env in local.processed_environments : env.environment_name => {
        resource_group_name    = local.environment_resource_names[idx].resource_group_name
        virtual_network_name   = local.environment_resource_names[idx].virtual_network_name
        subnet_name            = local.environment_resource_names[idx].subnet_name
        enterprise_policy_name = local.environment_resource_names[idx].enterprise_policy_name

        display_names = {
          resource_group    = local.environment_resource_names[idx].resource_group_display_name
          virtual_network   = local.environment_resource_names[idx].virtual_network_display_name
          enterprise_policy = local.environment_resource_names[idx].enterprise_policy_display_name
        }
      }
    }

    naming_validation = {
      caf_compliant    = true
      names_unique     = length(distinct(values(local.environment_resource_names)[*].resource_group_name)) == length(local.environment_resource_names)
      length_compliant = alltrue([for names in values(local.environment_resource_names) : length(names.resource_group_name) <= 90])
    }
  }
}

output "deployment_planning_summary" {
  description = <<DESCRIPTION
Deployment planning summary showing readiness for Phase 2 implementation.

Provides detailed planning information for Azure infrastructure deployment
including module orchestration, subscription mapping, and deployment readiness.
Critical for Phase 2 implementation planning and resource deployment.

Planning Components:
- Environments ready: Count of environments prepared for VNet integration
- Module planning: Planned AVM modules for resource deployment
- Subscription strategy: Multi-subscription deployment approach
- Deployment phases: Phased deployment approach and current status
DESCRIPTION
  sensitive   = true
  value = {
    phase_1_status = {
      complete               = local.deployment_status.phase_1_complete
      environments_processed = local.deployment_status.environments_processed
      environments_ready     = local.deployment_status.environments_ready
      validation_passed      = local.deployment_status.validation_status
    }

    phase_2_planning = {
      ready_for_implementation = local.configuration_valid
      planned_modules_count    = local.deployment_status.modules_planned

      module_breakdown = {
        primary_resource_groups   = length(local.planned_modules.primary_resource_groups)
        failover_resource_groups  = length(local.planned_modules.failover_resource_groups)
        primary_virtual_networks  = length(local.planned_modules.primary_virtual_networks)
        failover_virtual_networks = length(local.planned_modules.failover_virtual_networks)
        enterprise_policies       = length(local.planned_modules.enterprise_policies)
        policy_links              = length(local.planned_modules.policy_links)
      }
    }

    subscription_strategy = {
      multi_subscription_deployment = local.configuration_validation.subscriptions_different
      production_environments = length([
        for env in local.processed_environments : env if env.is_production
      ])
      non_production_environments = length([
        for env in local.processed_environments : env if !env.is_production
      ])
    }

    deployment_readiness = {
      configuration_valid = local.configuration_valid
      remote_state_valid  = local.remote_state_valid
      network_planned     = local.configuration_validation.primary_subnet_within_vnet && local.configuration_validation.failover_subnet_within_vnet
      naming_ready        = local.configuration_validation.names_generated
      ready_for_phase_2   = local.configuration_valid
    }
  }
}

# ============================================================================
# PATTERN METADATA - Configuration and Compliance Summary
# ============================================================================

output "pattern_configuration_summary" {
  description = "Comprehensive summary of VNet extension pattern configuration and compliance"
  sensitive   = true
  value = {
    pattern_info = {
      pattern_name     = "ptn-azure-vnet-extension"
      pattern_version  = local.output_schema_version
      pattern_type     = "orchestration"
      avm_compliant    = true
      phase_1_complete = true
    }

    workspace_config = {
      workspace_name   = var.workspace_name
      paired_with      = "ptn-environment-group"
      remote_state_key = "ptn-environment-group/${var.workspace_name}.tfstate"
    }

    azure_config = {
      primary_region              = var.network_configuration.primary.location
      failover_region             = var.network_configuration.failover.location
      primary_base_address_space  = var.network_configuration.primary.vnet_address_space_base
      failover_base_address_space = var.network_configuration.failover.vnet_address_space_base
      environment_count           = length(local.processed_environments)
      multi_subscription          = var.production_subscription_id != var.non_production_subscription_id
      ip_allocation_strategy      = "dynamic-per-environment"
    }

    compliance_info = {
      caf_naming           = true
      avm_orchestration    = true
      security_oidc_only   = true
      power_platform_ready = true
      baseline_compliant   = true
    }

    deployment_timestamp = timestamp()
  }
}

# ============================================================================
# PHASE 2 PLACEHOLDER OUTPUTS - Infrastructure Integration
# ============================================================================

# NOTE: Phase 2 implementation will add these outputs:
# - vnet_resource_ids: Map of VNet resource IDs per environment
# - subnet_resource_ids: Map of Power Platform subnet IDs
# - enterprise_policy_ids: Map of enterprise policy system IDs  
# - policy_link_summaries: Policy assignment status per environment
# - integration_endpoints: VNet integration endpoints for downstream use