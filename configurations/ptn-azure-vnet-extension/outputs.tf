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
      for env_name in keys(local.processed_environments) : env_name => {
        primary_vnet_cidr                = local.network_configuration[env_name].primary_vnet_address_space
        primary_power_platform_subnet    = local.network_configuration[env_name].primary_power_platform_subnet_cidr
        primary_private_endpoint_subnet  = local.network_configuration[env_name].primary_private_endpoint_subnet_cidr
        failover_vnet_cidr               = local.network_configuration[env_name].failover_vnet_address_space
        failover_power_platform_subnet   = local.network_configuration[env_name].failover_power_platform_subnet_cidr
        failover_private_endpoint_subnet = local.network_configuration[env_name].failover_private_endpoint_subnet_cidr
        environment_index                = local.environment_numeric_mapping[env_name]
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

output "deployment_status_summary" {
  description = <<DESCRIPTION
Complete deployment status summary for all phases of VNet extension pattern.

Provides comprehensive status information for Azure infrastructure deployment
including actual resource counts, deployment success metrics, and integration
status. Critical for monitoring deployment progress and validating completion.

Deployment Components:
- Phase Status: Completion status for all deployment phases
- Resource Counts: Actual deployed Azure resources by type and subscription
- Integration Status: Power Platform policy assignment and VNet integration
- Deployment Metrics: Success rates and deployment validation
DESCRIPTION
  sensitive   = true
  value = {
    # Overall deployment status
    deployment_complete = {
      phase_1_complete = local.deployment_status.phase_1_complete # Configuration and validation
      phase_2_complete = local.deployment_status.phase_2_complete # Azure infrastructure 
      phase_3_complete = local.deployment_status.phase_3_complete # Power Platform integration
      overall_complete = local.deployment_status.phase_1_complete && local.deployment_status.phase_2_complete && local.deployment_status.phase_3_complete
    }

    # Environment processing summary
    environment_status = {
      environments_processed      = local.deployment_status.environments_processed
      environments_ready          = local.deployment_status.environments_ready
      production_environments     = local.deployment_status.production_environments
      non_production_environments = local.deployment_status.non_production_environments
      validation_status           = local.deployment_status.validation_status
      remote_state_status         = local.deployment_status.remote_state_status
    }

    # Actual deployed resource counts
    deployed_resources = {
      # Resource Groups
      resource_groups = {
        production_primary      = local.deployment_status.production_primary_resource_groups
        production_failover     = local.deployment_status.production_failover_resource_groups
        non_production_primary  = local.deployment_status.non_production_primary_resource_groups
        non_production_failover = local.deployment_status.non_production_failover_resource_groups
        total = (
          local.deployment_status.production_primary_resource_groups +
          local.deployment_status.production_failover_resource_groups +
          local.deployment_status.non_production_primary_resource_groups +
          local.deployment_status.non_production_failover_resource_groups
        )
      }

      # Virtual Networks
      virtual_networks = {
        production_primary      = local.deployment_status.production_primary_virtual_networks
        production_failover     = local.deployment_status.production_failover_virtual_networks
        non_production_primary  = local.deployment_status.non_production_primary_virtual_networks
        non_production_failover = local.deployment_status.non_production_failover_virtual_networks
        total = (
          local.deployment_status.production_primary_virtual_networks +
          local.deployment_status.production_failover_virtual_networks +
          local.deployment_status.non_production_primary_virtual_networks +
          local.deployment_status.non_production_failover_virtual_networks
        )
      }

      # Enterprise Policies and Links
      power_platform_integration = {
        production_enterprise_policies     = local.deployment_status.production_enterprise_policies
        non_production_enterprise_policies = local.deployment_status.non_production_enterprise_policies
        production_policy_links            = local.deployment_status.production_policy_links
        non_production_policy_links        = local.deployment_status.non_production_policy_links
        total_enterprise_policies = (
          local.deployment_status.production_enterprise_policies +
          local.deployment_status.non_production_enterprise_policies
        )
        total_policy_links = (
          local.deployment_status.production_policy_links +
          local.deployment_status.non_production_policy_links
        )
      }
    }

    # Deployment success metrics
    deployment_metrics = {
      expected_modules = length(local.processed_environments) * 6 # 6 module types per environment
      actual_modules = (
        local.deployment_status.production_primary_resource_groups +
        local.deployment_status.production_failover_resource_groups +
        local.deployment_status.production_primary_virtual_networks +
        local.deployment_status.production_failover_virtual_networks +
        local.deployment_status.production_enterprise_policies +
        local.deployment_status.production_policy_links +
        local.deployment_status.non_production_primary_resource_groups +
        local.deployment_status.non_production_failover_resource_groups +
        local.deployment_status.non_production_primary_virtual_networks +
        local.deployment_status.non_production_failover_virtual_networks +
        local.deployment_status.non_production_enterprise_policies +
        local.deployment_status.non_production_policy_links
      )
      deployment_success_rate = length(local.processed_environments) > 0 ? (
        (
          local.deployment_status.production_primary_resource_groups +
          local.deployment_status.production_failover_resource_groups +
          local.deployment_status.production_primary_virtual_networks +
          local.deployment_status.production_failover_virtual_networks +
          local.deployment_status.production_enterprise_policies +
          local.deployment_status.production_policy_links +
          local.deployment_status.non_production_primary_resource_groups +
          local.deployment_status.non_production_failover_resource_groups +
          local.deployment_status.non_production_primary_virtual_networks +
          local.deployment_status.non_production_failover_virtual_networks +
          local.deployment_status.non_production_enterprise_policies +
          local.deployment_status.non_production_policy_links
        ) / (length(local.processed_environments) * 6) * 100
      ) : 0
    }

    # Multi-subscription deployment summary
    subscription_deployment = {
      multi_subscription_enabled = local.configuration_validation.subscriptions_different
      production_subscription_resources = (
        local.deployment_status.production_primary_resource_groups +
        local.deployment_status.production_failover_resource_groups +
        local.deployment_status.production_primary_virtual_networks +
        local.deployment_status.production_failover_virtual_networks
      )
      non_production_subscription_resources = (
        local.deployment_status.non_production_primary_resource_groups +
        local.deployment_status.non_production_failover_resource_groups +
        local.deployment_status.non_production_primary_virtual_networks +
        local.deployment_status.non_production_failover_virtual_networks
      )
    }
  }
}

# ============================================================================
# PATTERN METADATA - Configuration and Compliance Summary
# ============================================================================

output "pattern_configuration_summary" {
  description = "Comprehensive summary of VNet extension pattern configuration, compliance, and infrastructure status"
  sensitive   = true
  value = {
    pattern_info = {
      pattern_name        = "ptn-azure-vnet-extension"
      pattern_version     = local.output_schema_version
      pattern_type        = "orchestration"
      avm_compliant       = true
      phase_1_complete    = local.deployment_status.phase_1_complete
      phase_2_complete    = local.deployment_status.phase_2_complete
      phase_3_complete    = local.deployment_status.phase_3_complete
      deployment_complete = local.deployment_status.phase_1_complete && local.deployment_status.phase_2_complete && local.deployment_status.phase_3_complete
    }

    workspace_config = {
      workspace_name          = var.workspace_name
      paired_with             = "ptn-environment-group"
      remote_state_key        = "ptn-environment-group/${var.workspace_name}.tfstate"
      environments_integrated = length(local.processed_environments)
    }

    azure_config = {
      primary_region              = var.network_configuration.primary.location
      failover_region             = var.network_configuration.failover.location
      primary_base_address_space  = var.network_configuration.primary.vnet_address_space_base
      failover_base_address_space = var.network_configuration.failover.vnet_address_space_base
      environment_count           = length(local.processed_environments)
      multi_subscription          = var.production_subscription_id != var.non_production_subscription_id
      ip_allocation_strategy      = "dynamic-per-environment"

      # Infrastructure deployment status
      infrastructure_status = {
        vnets_deployed = (
          local.deployment_status.production_primary_virtual_networks +
          local.deployment_status.production_failover_virtual_networks +
          local.deployment_status.non_production_primary_virtual_networks +
          local.deployment_status.non_production_failover_virtual_networks
        )
        resource_groups_deployed = (
          local.deployment_status.production_primary_resource_groups +
          local.deployment_status.production_failover_resource_groups +
          local.deployment_status.non_production_primary_resource_groups +
          local.deployment_status.non_production_failover_resource_groups
        )
        enterprise_policies_deployed = (
          local.deployment_status.production_enterprise_policies +
          local.deployment_status.non_production_enterprise_policies
        )
        policy_assignments_deployed = (
          local.deployment_status.production_policy_links +
          local.deployment_status.non_production_policy_links
        )
      }
    }

    power_platform_integration = {
      enterprise_policies_created = (
        local.deployment_status.production_enterprise_policies +
        local.deployment_status.non_production_enterprise_policies
      )
      environment_assignments = (
        local.deployment_status.production_policy_links +
        local.deployment_status.non_production_policy_links
      )
      network_injection_enabled = (
        local.deployment_status.production_policy_links +
        local.deployment_status.non_production_policy_links
      ) > 0
    }

    compliance_info = {
      caf_naming              = true
      avm_orchestration       = true
      security_oidc_only      = true
      power_platform_ready    = true
      baseline_compliant      = true
      infrastructure_deployed = local.deployment_status.phase_2_complete
      integration_complete    = local.deployment_status.phase_3_complete
    }

    deployment_timestamp = timestamp()
  }
}

# ============================================================================
# PHASE 2 INFRASTRUCTURE OUTPUTS - Actual Azure Resource Integration
# ============================================================================

# WHY: Expose actual Azure resource IDs for downstream consumption and integration
# CONTEXT: Phase 2 deployment creates real Azure infrastructure resources
# IMPACT: Enables pattern composability and downstream resource integration

output "azure_resource_groups" {
  description = <<DESCRIPTION
Azure Resource Group information for all deployed environments.

Provides resource group IDs, names, and locations for both primary and failover
resource groups across production and non-production subscriptions. Essential
for downstream modules that need to reference these resource groups.

Resource Groups:
- Primary: Resource groups in primary Azure region for each environment
- Failover: Resource groups in failover Azure region for disaster recovery
- Production: Deployed to dedicated production subscription
- Non-Production: Deployed to shared non-production subscription
DESCRIPTION
  value = merge(
    # Production primary resource groups
    {
      for env_key, rg in module.production_primary_resource_groups : "${env_key}_primary_production" => {
        resource_id  = rg.resource_id
        name         = rg.name
        location     = local.network_configuration[env_key].primary_location
        subscription = "production"
        region_type  = "primary"
        environment  = local.processed_environments[env_key].environment_name
      }
    },
    # Production failover resource groups
    {
      for env_key, rg in module.production_failover_resource_groups : "${env_key}_failover_production" => {
        resource_id  = rg.resource_id
        name         = rg.name
        location     = local.network_configuration[env_key].failover_location
        subscription = "production"
        region_type  = "failover"
        environment  = local.processed_environments[env_key].environment_name
      }
    },
    # Non-production primary resource groups
    {
      for env_key, rg in module.non_production_primary_resource_groups : "${env_key}_primary_non_production" => {
        resource_id  = rg.resource_id
        name         = rg.name
        location     = local.network_configuration[env_key].primary_location
        subscription = "non_production"
        region_type  = "primary"
        environment  = local.processed_environments[env_key].environment_name
      }
    },
    # Non-production failover resource groups
    {
      for env_key, rg in module.non_production_failover_resource_groups : "${env_key}_failover_non_production" => {
        resource_id  = rg.resource_id
        name         = rg.name
        location     = local.network_configuration[env_key].failover_location
        subscription = "non_production"
        region_type  = "failover"
        environment  = local.processed_environments[env_key].environment_name
      }
    }
  )
}

output "azure_virtual_networks" {
  description = <<DESCRIPTION
Azure Virtual Network information for all deployed environments.

Provides VNet resource IDs, names, address spaces, and subnet information for
both primary and failover VNets across production and non-production subscriptions.
Critical for downstream modules requiring network integration or private connectivity.

VNet Components:
- Resource ID: Full Azure resource identifier for the VNet
- Address Space: CIDR blocks allocated to each VNet (dynamically calculated)
- Subnets: Power Platform delegated subnets and private endpoint subnets
- Region: Primary and failover region deployment information
DESCRIPTION
  value = merge(
    # Production primary virtual networks
    {
      for env_key, vnet in module.production_primary_virtual_networks : "${env_key}_primary_production" => {
        resource_id   = vnet.resource_id
        name          = vnet.name
        location      = local.network_configuration[env_key].primary_location
        address_space = [local.network_configuration[env_key].primary_vnet_address_space]
        subscription  = "production"
        region_type   = "primary"
        environment   = local.processed_environments[env_key].environment_name

        # Subnet information for downstream integration
        subnets = {
          power_platform = {
            name             = local.environment_resource_names[env_key].subnet_name
            address_prefixes = [local.network_configuration[env_key].primary_power_platform_subnet_cidr]
            resource_id      = vnet.subnets["PowerPlatformSubnet"].resource_id
          }
          private_endpoint = {
            name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
            address_prefixes = [local.network_configuration[env_key].primary_private_endpoint_subnet_cidr]
            resource_id      = vnet.subnets["PrivateEndpointSubnet"].resource_id
          }
        }
      }
    },
    # Production failover virtual networks
    {
      for env_key, vnet in module.production_failover_virtual_networks : "${env_key}_failover_production" => {
        resource_id   = vnet.resource_id
        name          = vnet.name
        location      = local.network_configuration[env_key].failover_location
        address_space = [local.network_configuration[env_key].failover_vnet_address_space]
        subscription  = "production"
        region_type   = "failover"
        environment   = local.processed_environments[env_key].environment_name

        # Subnet information for downstream integration
        subnets = {
          power_platform = {
            name             = local.environment_resource_names[env_key].subnet_name
            address_prefixes = [local.network_configuration[env_key].failover_power_platform_subnet_cidr]
            resource_id      = vnet.subnets["PowerPlatformSubnet"].resource_id
          }
          private_endpoint = {
            name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
            address_prefixes = [local.network_configuration[env_key].failover_private_endpoint_subnet_cidr]
            resource_id      = vnet.subnets["PrivateEndpointSubnet"].resource_id
          }
        }
      }
    },
    # Non-production primary virtual networks
    {
      for env_key, vnet in module.non_production_primary_virtual_networks : "${env_key}_primary_non_production" => {
        resource_id   = vnet.resource_id
        name          = vnet.name
        location      = local.network_configuration[env_key].primary_location
        address_space = [local.network_configuration[env_key].primary_vnet_address_space]
        subscription  = "non_production"
        region_type   = "primary"
        environment   = local.processed_environments[env_key].environment_name

        # Subnet information for downstream integration
        subnets = {
          power_platform = {
            name             = local.environment_resource_names[env_key].subnet_name
            address_prefixes = [local.network_configuration[env_key].primary_power_platform_subnet_cidr]
            resource_id      = vnet.subnets["PowerPlatformSubnet"].resource_id
          }
          private_endpoint = {
            name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
            address_prefixes = [local.network_configuration[env_key].primary_private_endpoint_subnet_cidr]
            resource_id      = vnet.subnets["PrivateEndpointSubnet"].resource_id
          }
        }
      }
    },
    # Non-production failover virtual networks
    {
      for env_key, vnet in module.non_production_failover_virtual_networks : "${env_key}_failover_non_production" => {
        resource_id   = vnet.resource_id
        name          = vnet.name
        location      = local.network_configuration[env_key].failover_location
        address_space = [local.network_configuration[env_key].failover_vnet_address_space]
        subscription  = "non_production"
        region_type   = "failover"
        environment   = local.processed_environments[env_key].environment_name

        # Subnet information for downstream integration
        subnets = {
          power_platform = {
            name             = local.environment_resource_names[env_key].subnet_name
            address_prefixes = [local.network_configuration[env_key].failover_power_platform_subnet_cidr]
            resource_id      = vnet.subnets["PowerPlatformSubnet"].resource_id
          }
          private_endpoint = {
            name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
            address_prefixes = [local.network_configuration[env_key].failover_private_endpoint_subnet_cidr]
            resource_id      = vnet.subnets["PrivateEndpointSubnet"].resource_id
          }
        }
      }
    }
  )
}

output "enterprise_policies" {
  description = <<DESCRIPTION
Power Platform Enterprise Policy information for all deployed environments.

Provides enterprise policy system IDs, names, and configuration details for
NetworkInjection policies across production and non-production environments.
Essential for external integrations and policy management workflows.

Enterprise Policy Components:
- System ID: Power Platform system identifier for the enterprise policy
- Policy Type: NetworkInjection for VNet integration capabilities
- Virtual Networks: Associated VNet resource IDs for network injection
- Location: Power Platform region mapping from Azure regions
DESCRIPTION
  sensitive   = true
  value = merge(
    # Production enterprise policies
    {
      for env_key, policy in module.production_enterprise_policies : "${env_key}_production" => {
        system_id        = policy.enterprise_policy_system_id
        name             = policy.policy_deployment_summary.policy_name
        policy_type      = policy.policy_deployment_summary.policy_type
        location         = policy.policy_deployment_summary.policy_location
        environment      = local.processed_environments[env_key].environment_name
        environment_type = local.processed_environments[env_key].environment_type
        subscription     = "production"

        # Associated virtual networks for network injection
        virtual_networks = [
          module.production_primary_virtual_networks[env_key].resource_id,
          module.production_failover_virtual_networks[env_key].resource_id
        ]
      }
    },
    # Non-production enterprise policies
    {
      for env_key, policy in module.non_production_enterprise_policies : "${env_key}_non_production" => {
        system_id        = policy.enterprise_policy_system_id
        name             = policy.policy_deployment_summary.policy_name
        policy_type      = policy.policy_deployment_summary.policy_type
        location         = policy.policy_deployment_summary.policy_location
        environment      = local.processed_environments[env_key].environment_name
        environment_type = local.processed_environments[env_key].environment_type
        subscription     = "non_production"

        # Associated virtual networks for network injection
        virtual_networks = [
          module.non_production_primary_virtual_networks[env_key].resource_id,
          module.non_production_failover_virtual_networks[env_key].resource_id
        ]
      }
    }
  )
}

output "policy_assignments" {
  description = <<DESCRIPTION
Power Platform policy assignment status for all environments.

Provides policy assignment information showing which NetworkInjection enterprise
policies have been successfully linked to Power Platform environments. Critical
for validating VNet integration deployment and troubleshooting assignment issues.

Policy Assignment Components:
- Environment ID: Power Platform environment identifier from remote state
- System ID: Associated enterprise policy system identifier
- Policy Type: NetworkInjection for VNet integration
- Assignment Status: Deployment and linking status information
DESCRIPTION
  sensitive   = true
  value = merge(
    # Production policy assignments
    {
      for env_key, link in module.production_policy_links : "${env_key}_production" => {
        environment_id    = local.processed_environments[env_key].environment_id
        environment_name  = local.processed_environments[env_key].environment_name
        system_id         = module.production_enterprise_policies[env_key].enterprise_policy_system_id
        policy_type       = "NetworkInjection"
        subscription      = "production"
        assignment_status = "deployed"

        # Linked VNet information
        primary_vnet_id  = module.production_primary_virtual_networks[env_key].resource_id
        failover_vnet_id = module.production_failover_virtual_networks[env_key].resource_id
      }
    },
    # Non-production policy assignments
    {
      for env_key, link in module.non_production_policy_links : "${env_key}_non_production" => {
        environment_id    = local.processed_environments[env_key].environment_id
        environment_name  = local.processed_environments[env_key].environment_name
        system_id         = module.non_production_enterprise_policies[env_key].enterprise_policy_system_id
        policy_type       = "NetworkInjection"
        subscription      = "non_production"
        assignment_status = "deployed"

        # Linked VNet information
        primary_vnet_id  = module.non_production_primary_virtual_networks[env_key].resource_id
        failover_vnet_id = module.non_production_failover_virtual_networks[env_key].resource_id
      }
    }
  )
}

output "integration_endpoints" {
  description = <<DESCRIPTION
VNet integration endpoints for downstream consumption and private connectivity.

Provides structured integration points for downstream modules requiring private
connectivity to the deployed VNet infrastructure. Essential for storage accounts,
Key Vaults, and other Azure services requiring private endpoint connectivity.

Integration Components:
- Private Endpoint Subnets: Subnet IDs for private endpoint deployment
- VNet Integration: VNet resource IDs for service integration
- Network Security: Security group and routing information
- DNS Integration: Private DNS zone integration points
DESCRIPTION
  value = {
    # Private endpoint integration points
    private_endpoint_subnets = merge(
      {
        for env_key, vnet in module.production_primary_virtual_networks : "${env_key}_primary_production" => {
          subnet_id          = vnet.subnets["PrivateEndpointSubnet"].resource_id
          subnet_name        = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
          address_prefixes   = [local.network_configuration[env_key].primary_private_endpoint_subnet_cidr]
          virtual_network_id = vnet.resource_id
          environment        = local.processed_environments[env_key].environment_name
          region_type        = "primary"
          subscription       = "production"
        }
      },
      {
        for env_key, vnet in module.production_failover_virtual_networks : "${env_key}_failover_production" => {
          subnet_id          = vnet.subnets["PrivateEndpointSubnet"].resource_id
          subnet_name        = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
          address_prefixes   = [local.network_configuration[env_key].failover_private_endpoint_subnet_cidr]
          virtual_network_id = vnet.resource_id
          environment        = local.processed_environments[env_key].environment_name
          region_type        = "failover"
          subscription       = "production"
        }
      },
      {
        for env_key, vnet in module.non_production_primary_virtual_networks : "${env_key}_primary_non_production" => {
          subnet_id          = vnet.subnets["PrivateEndpointSubnet"].resource_id
          subnet_name        = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
          address_prefixes   = [local.network_configuration[env_key].primary_private_endpoint_subnet_cidr]
          virtual_network_id = vnet.resource_id
          environment        = local.processed_environments[env_key].environment_name
          region_type        = "primary"
          subscription       = "non_production"
        }
      },
      {
        for env_key, vnet in module.non_production_failover_virtual_networks : "${env_key}_failover_non_production" => {
          subnet_id          = vnet.subnets["PrivateEndpointSubnet"].resource_id
          subnet_name        = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(local.processed_environments[env_key].suffix, " ", "")}"
          address_prefixes   = [local.network_configuration[env_key].failover_private_endpoint_subnet_cidr]
          virtual_network_id = vnet.resource_id
          environment        = local.processed_environments[env_key].environment_name
          region_type        = "failover"
          subscription       = "non_production"
        }
      }
    )

    # VNet integration summary
    vnet_integration_summary = {
      total_vnets_deployed       = length(local.processed_environments) * 2 # Primary + Failover per environment
      production_vnets           = length(local.production_environments) * 2
      non_production_vnets       = length(local.non_production_environments) * 2
      enterprise_policies_linked = length(local.processed_environments)

      # Network capacity summary
      total_ip_capacity = {
        primary_vnets = {
          for env_name in keys(local.processed_environments) : env_name => pow(2, 32 - tonumber(split("/", local.network_configuration[env_name].primary_vnet_address_space)[1]))
        }
        failover_vnets = {
          for env_name in keys(local.processed_environments) : env_name => pow(2, 32 - tonumber(split("/", local.network_configuration[env_name].failover_vnet_address_space)[1]))
        }
      }
    }
  }
}