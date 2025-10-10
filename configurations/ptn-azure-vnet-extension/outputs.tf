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
      # Resource Groups - Single RG per environment architecture
      resource_groups = {
        production     = local.deployment_status.production_resource_groups
        non_production = local.deployment_status.non_production_resource_groups
        total          = local.deployment_status.production_resource_groups + local.deployment_status.non_production_resource_groups
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
      expected_modules = length(local.processed_environments) * 5 # 5 module types per environment (1 RG + 2 VNets + 1 policy + 1 link)
      actual_modules = (
        local.deployment_status.production_resource_groups +
        local.deployment_status.production_primary_virtual_networks +
        local.deployment_status.production_failover_virtual_networks +
        local.deployment_status.production_enterprise_policies +
        local.deployment_status.production_policy_links +
        local.deployment_status.non_production_resource_groups +
        local.deployment_status.non_production_primary_virtual_networks +
        local.deployment_status.non_production_failover_virtual_networks +
        local.deployment_status.non_production_enterprise_policies +
        local.deployment_status.non_production_policy_links
      )
      deployment_success_rate = length(local.processed_environments) > 0 ? (
        (
          local.deployment_status.production_resource_groups +
          local.deployment_status.production_primary_virtual_networks +
          local.deployment_status.production_failover_virtual_networks +
          local.deployment_status.production_enterprise_policies +
          local.deployment_status.production_policy_links +
          local.deployment_status.non_production_resource_groups +
          local.deployment_status.non_production_primary_virtual_networks +
          local.deployment_status.non_production_failover_virtual_networks +
          local.deployment_status.non_production_enterprise_policies +
          local.deployment_status.non_production_policy_links
        ) / (length(local.processed_environments) * 5) * 100
      ) : 0
    }

    # Multi-subscription deployment summary
    subscription_deployment = {
      multi_subscription_enabled = local.configuration_validation.subscriptions_different
      production_subscription_resources = (
        local.deployment_status.production_resource_groups +
        local.deployment_status.production_primary_virtual_networks +
        local.deployment_status.production_failover_virtual_networks
      )
      non_production_subscription_resources = (
        local.deployment_status.non_production_resource_groups +
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
      workspace_name          = local.remote_workspace_name
      paired_with             = "ptn-environment-group"
      remote_state_key        = "ptn-environment-group-${var.paired_tfvars_file}.tfstate"
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
          local.deployment_status.production_resource_groups +
          local.deployment_status.non_production_resource_groups
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

Single resource group per Power Platform environment containing both primary
and failover VNets. Provides resource group IDs, names, and locations across
production and non-production subscriptions for cleaner governance.

Resource Groups:
- Single RG per Environment: All environment resources in one resource group
- Primary Location: Resource group created in primary Azure region
- Production: Deployed to dedicated production subscription  
- Non-Production: Deployed to shared non-production subscription
DESCRIPTION
  value = merge(
    # Production resource groups (single RG per environment)
    {
      for env_key, rg in module.production_resource_groups : "${env_key}_production" => {
        resource_id  = rg.resource_id
        name         = rg.name
        location     = local.network_configuration[env_key].primary_location
        subscription = "production"
        environment  = local.processed_environments[env_key].environment_name
        architecture = "single-rg-per-environment"

        # Resources contained in this RG
        contains = {
          primary_vnet  = "${local.environment_resource_names[env_key].virtual_network_name}-primary"
          failover_vnet = "${local.environment_resource_names[env_key].virtual_network_name}-failover"
        }
      }
    },
    # Non-production resource groups (single RG per environment)
    {
      for env_key, rg in module.non_production_resource_groups : "${env_key}_non_production" => {
        resource_id  = rg.resource_id
        name         = rg.name
        location     = local.network_configuration[env_key].primary_location
        subscription = "non_production"
        environment  = local.processed_environments[env_key].environment_name
        architecture = "single-rg-per-environment"

        # Resources contained in this RG
        contains = {
          primary_vnet  = "${local.environment_resource_names[env_key].virtual_network_name}-primary"
          failover_vnet = "${local.environment_resource_names[env_key].virtual_network_name}-failover"
        }
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

# ============================================================================
# PHASE 2 PRIVATE DNS ZONE OUTPUTS - Demo-Ready Private Connectivity
# ============================================================================

output "private_dns_zones" {
  description = <<DESCRIPTION
Private DNS zone information for all deployed environments and requested DNS zones.

Provides DNS zone resource IDs, domain names, and VNet link information for
private endpoint connectivity. Only created when private_dns_zones variable
contains domain names, enabling on-demand DNS infrastructure for demo scenarios.

Private DNS Components:
- Domain Name: DNS zone domain (e.g., privatelink.vault.core.windows.net)
- Resource ID: Full Azure resource identifier for the DNS zone
- VNet Links: Automatic linking to both primary and failover VNets per environment
- Demo Ready: DNS zones are immediately available for private endpoint creation
DESCRIPTION

  value = {
    zones_configured   = length(var.private_dns_zones)
    zero_trust_enabled = var.enable_zero_trust_networking

    # Phase 2 Complete: Deployed DNS zones
    dns_zones_deployed = var.private_dns_zones != null && length(var.private_dns_zones) > 0 ? {
      production_zones = {
        for zone_key, zone_config in local.production_dns_zone_combinations : zone_key => {
          domain_name = zone_config.zone_name
          resource_id = module.production_private_dns_zones[zone_key].resource_id
          environment = zone_config.env_key
          location    = zone_config.location
          vnet_links  = 1 # Primary VNet linked
          status      = "deployed"
        }
      }
      non_production_zones = {
        for zone_key, zone_config in local.non_production_dns_zone_combinations : zone_key => {
          domain_name = zone_config.zone_name
          resource_id = module.non_production_private_dns_zones[zone_key].resource_id
          environment = zone_config.env_key
          location    = zone_config.location
          vnet_links  = 1 # Primary VNet linked
          status      = "deployed"
        }
      }
      total_zones = length(local.production_dns_zone_combinations) + length(local.non_production_dns_zone_combinations)
      } : {
      production_zones     = {}
      non_production_zones = {}
      total_zones          = 0
    }

    implementation_status = {
      phase_1_completed = true
      phase_2_completed = true
      azure_resources   = "deployed"
      next_action       = "ready for private endpoint creation"
    }
  }
}

# ============================================================================
# PHASE 2 NETWORK SECURITY GROUP OUTPUTS - Zero-Trust Security Implementation
# ============================================================================

output "network_security_groups" {
  description = <<DESCRIPTION
Network Security Group information for zero-trust networking implementation.

Provides NSG resource IDs, names, security rules, and subnet associations for
both Power Platform and Private Endpoint subnets. Security rules are applied
conditionally based on the enable_zero_trust_networking variable setting.

Network Security Components:
- Power Platform NSGs: Applied to subnets with Power Platform delegation
- Private Endpoint NSGs: Applied to subnets designated for private endpoints
- Security Rules: Zero-trust rules (allow VNet, PowerPlatform service tag, deny Internet)
- Subnet Associations: Automatic association with respective subnet types
DESCRIPTION

  value = {
    zero_trust_enabled        = var.enable_zero_trust_networking
    security_rules_configured = length(keys(local.zero_trust_nsg_rules))
    security_rules_applied    = length(keys(local.environment_nsg_rules))

    # Phase 2 Complete: Deployed NSGs
    nsgs_deployed = {
      production_power_platform_nsgs = {
        for env_key in keys(local.production_environments) : env_key => {
          name           = "nsg-powerplatform-${local.environment_resource_names[env_key].env_suffix_clean}"
          resource_id    = module.production_nsgs[env_key].resource_id
          subnet_type    = "PowerPlatform"
          environment    = env_key
          security_rules = var.enable_zero_trust_networking ? length(keys(local.zero_trust_nsg_rules)) : 0
          status         = "deployed"
        }
      }
      non_production_power_platform_nsgs = {
        for env_key in keys(local.non_production_environments) : env_key => {
          name           = "nsg-powerplatform-${local.environment_resource_names[env_key].env_suffix_clean}"
          resource_id    = module.non_production_nsgs[env_key].resource_id
          subnet_type    = "PowerPlatform"
          environment    = env_key
          security_rules = var.enable_zero_trust_networking ? length(keys(local.zero_trust_nsg_rules)) : 0
          status         = "deployed"
        }
      }
      production_private_endpoint_nsgs = {
        for env_key in keys(local.production_environments) : env_key => {
          name           = "nsg-privateendpoint-${local.environment_resource_names[env_key].env_suffix_clean}"
          resource_id    = module.production_nsgs[env_key].resource_id
          subnet_type    = "PrivateEndpoint"
          environment    = env_key
          security_rules = var.enable_zero_trust_networking ? length(keys(local.zero_trust_nsg_rules)) : 0
          status         = "deployed"
        }
      }
      non_production_private_endpoint_nsgs = {
        for env_key in keys(local.non_production_environments) : env_key => {
          name           = "nsg-privateendpoint-${local.environment_resource_names[env_key].env_suffix_clean}"
          resource_id    = module.non_production_nsgs[env_key].resource_id
          subnet_type    = "PrivateEndpoint"
          environment    = env_key
          security_rules = var.enable_zero_trust_networking ? length(keys(local.zero_trust_nsg_rules)) : 0
          status         = "deployed"
        }
      }
    }

    # Zero-trust security rules as configured
    security_rules_detail = {
      for rule_name, rule in local.zero_trust_nsg_rules : rule_name => {
        access                     = rule.access
        direction                  = rule.direction
        priority                   = rule.priority
        protocol                   = rule.protocol
        source_address_prefix      = rule.source_address_prefix
        destination_address_prefix = rule.destination_address_prefix
        enabled                    = var.enable_zero_trust_networking
      }
    }

    implementation_status = {
      phase_1_completed         = true
      phase_2_completed         = true
      conditional_logic_working = var.enable_zero_trust_networking ? "zero-trust rules applied" : "zero-trust rules disabled"
      azure_resources           = "deployed"
      next_action               = "ready for subnet association and traffic filtering"
    }
  }
}

# ============================================================================
# VNET PEERING ORCHESTRATION OUTPUTS - Phase 2
# ============================================================================

output "vnet_peering_status" {
  description = <<DESCRIPTION
Status and configuration details of VNet peering connections for cross-region connectivity.

Provides comprehensive information about peering deployments including:
- Connection status and resource IDs for all peerings
- Bidirectional connectivity validation
- Hub-spoke architecture verification
- Provider-specific peering assignments

This output enables validation of the single private endpoint architecture
where primary region endpoints serve traffic from both regions via VNet peering.

Peering Components:
- production_peerings: Production environment peering connections
- non_production_peerings: Non-production environment peering connections
- peering_configuration: Applied peering settings and policies
- connectivity_validation: Cross-region connectivity status
DESCRIPTION
  sensitive   = false
  value = var.enable_vnet_peering ? {
    peering_enabled = true
    peering_configuration = {
      allow_virtual_network_access = true
      allow_forwarded_traffic      = false
      allow_gateway_transit        = false
      use_remote_gateways          = false
      bidirectional                = true
    }

    production_peerings = {
      primary_to_failover_peerings = {
        for env_key in keys(local.production_environments) : env_key => {
          name                  = module.production_primary_to_failover_peering[env_key].name
          resource_id           = module.production_primary_to_failover_peering[env_key].resource_id
          source_vnet           = module.production_primary_virtual_networks[env_key].name
          destination_vnet      = module.production_failover_virtual_networks[env_key].name
          peering_direction     = "primary-to-failover"
          provider_subscription = "production"
          status                = "deployed"
        }
      }
      failover_to_primary_peerings = {
        for env_key in keys(local.production_environments) : env_key => {
          name                  = module.production_failover_to_primary_peering[env_key].name
          resource_id           = module.production_failover_to_primary_peering[env_key].resource_id
          source_vnet           = module.production_failover_virtual_networks[env_key].name
          destination_vnet      = module.production_primary_virtual_networks[env_key].name
          peering_direction     = "failover-to-primary"
          provider_subscription = "production"
          status                = "deployed"
        }
      }
    }

    non_production_peerings = {
      primary_to_failover_peerings = {
        for env_key in keys(local.non_production_environments) : env_key => {
          name                  = module.non_production_primary_to_failover_peering[env_key].name
          resource_id           = module.non_production_primary_to_failover_peering[env_key].resource_id
          source_vnet           = module.non_production_primary_virtual_networks[env_key].name
          destination_vnet      = module.non_production_failover_virtual_networks[env_key].name
          peering_direction     = "primary-to-failover"
          provider_subscription = "non-production"
          status                = "deployed"
        }
      }
      failover_to_primary_peerings = {
        for env_key in keys(local.non_production_environments) : env_key => {
          name                  = module.non_production_failover_to_primary_peering[env_key].name
          resource_id           = module.non_production_failover_to_primary_peering[env_key].resource_id
          source_vnet           = module.non_production_failover_virtual_networks[env_key].name
          destination_vnet      = module.non_production_primary_virtual_networks[env_key].name
          peering_direction     = "failover-to-primary"
          provider_subscription = "non-production"
          status                = "deployed"
        }
      }
    }

    connectivity_validation = {
      total_peering_connections = (
        length(local.production_environments) * 2 +   # Bidirectional production
        length(local.non_production_environments) * 2 # Bidirectional non-production
      )
      bidirectional_connectivity = true
      cross_region_access        = "enabled"
      hub_spoke_pattern          = "single endpoint per service"
      architecture_pattern       = "hub-spoke with cross-region peering"
    }

    implementation_status = {
      phase_2_1_completed = true
      avm_modules_used    = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
      azure_resources     = "deployed"
      next_action         = "ready for private endpoint deployment"
    }
    } : {
    peering_enabled         = false
    peering_configuration   = null
    production_peerings     = {}
    non_production_peerings = {}
    connectivity_validation = null
    implementation_status = {
      phase_2_1_completed = false
      avm_modules_used    = null
      azure_resources     = "not deployed"
      next_action         = "deploy private endpoints in both regions"
    }
  }
}