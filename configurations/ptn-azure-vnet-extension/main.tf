# Main Configuration for Power Platform Azure VNet Extension Pattern
#
# WHY: Pattern modules need validation-first approach to prevent costly deployment
# failures in multi-subscription Azure environments
#
# CONTEXT: Phase 1 validates configuration and remote state integration before
# Phase 2 deploys actual Azure infrastructure (VNets, enterprise policies)
#
# IMPACT: Early validation catches configuration errors and ensures proper
# integration between pattern modules before resource provisioning

# ============================================================================
# CONFIGURATION VALIDATION - Early Failure Prevention
# ============================================================================

# WHY: Validate configuration before any resource creation
# CONTEXT: Complex multi-environment, multi-subscription pattern needs validation
# IMPACT: Prevents partial deployments and resource creation with invalid configuration
resource "terraform_data" "configuration_validation" {
  # Trigger validation checks
  input = local.configuration_validation

  # Fail deployment if validation errors exist
  lifecycle {
    precondition {
      condition     = local.configuration_valid
      error_message = "Configuration validation failed: ${join(", ", nonsensitive(local.actual_validation_errors))}"
    }

    precondition {
      condition     = local.remote_state_valid
      error_message = "Remote state from ptn-environment-group is invalid. Ensure the ptn-environment-group configuration is deployed and available."
    }
  }
}

# ============================================================================
# PHASE 2 PLACEHOLDER - Azure Infrastructure Orchestration
# ============================================================================

# NOTE: Phase 2 implementation will include:
# 1. Resource Group creation using Azure/avm-res-resources-resourcegroup
# 2. VNet creation using Azure/avm-res-network-virtualnetwork  
# 3. Enterprise Policy creation using res-enterprise-policy module
# 4. Policy linking using res-enterprise-policy-link module

# Placeholder locals for Phase 2 module orchestration
locals {
  # Module orchestration planning (Phase 2)
  planned_modules = {
    # Primary region resource groups
    primary_resource_groups = {
      for idx, env in local.vnet_ready_environments : idx => {
        module_source = "Azure/avm-res-resources-resourcegroup/azurerm"
        name          = "${local.environment_resource_names[idx].resource_group_name}-primary"
        location      = local.network_configuration[idx].primary_location
        subscription  = local.subscription_mapping[idx].subscription_id
      }
    }

    # Failover region resource groups
    failover_resource_groups = {
      for idx, env in local.vnet_ready_environments : idx => {
        module_source = "Azure/avm-res-resources-resourcegroup/azurerm"
        name          = "${local.environment_resource_names[idx].resource_group_name}-failover"
        location      = local.network_configuration[idx].failover_location
        subscription  = local.subscription_mapping[idx].subscription_id
      }
    }

    # Primary region virtual networks
    primary_virtual_networks = {
      for idx, env in local.vnet_ready_environments : idx => {
        module_source = "Azure/avm-res-network-virtualnetwork/azurerm"
        name          = "${local.environment_resource_names[idx].virtual_network_name}-primary"
        address_space = [local.network_configuration[idx].primary_vnet_address_space]
        location      = local.network_configuration[idx].primary_location
        subnet_config = {
          power_platform   = local.network_configuration[idx].primary_power_platform_subnet_cidr
          private_endpoint = local.network_configuration[idx].primary_private_endpoint_subnet_cidr
          delegation       = local.network_configuration[idx].subnet_delegation
        }
      }
    }

    # Failover region virtual networks  
    failover_virtual_networks = {
      for idx, env in local.vnet_ready_environments : idx => {
        module_source = "Azure/avm-res-network-virtualnetwork/azurerm"
        name          = "${local.environment_resource_names[idx].virtual_network_name}-failover"
        address_space = [local.network_configuration[idx].failover_vnet_address_space]
        location      = local.network_configuration[idx].failover_location
        subnet_config = {
          power_platform   = local.network_configuration[idx].failover_power_platform_subnet_cidr
          private_endpoint = local.network_configuration[idx].failover_private_endpoint_subnet_cidr
          delegation       = local.network_configuration[idx].subnet_delegation
        }
      }
    }

    enterprise_policies = {
      for idx, env in local.vnet_ready_environments : idx => {
        module_source           = "../res-enterprise-policy"
        policy_type             = "NetworkInjection"
        environment_integration = env
      }
    }

    policy_links = {
      for idx, env in local.vnet_ready_environments : idx => {
        module_source  = "../res-enterprise-policy-link"
        environment_id = env.environment_id
        policy_type    = "NetworkInjection"
      }
    }
  }
}

# ============================================================================
# DEPLOYMENT STATUS TRACKING
# ============================================================================

# WHY: Track deployment progress and provide status information
# CONTEXT: Complex multi-phase deployment needs progress tracking
# IMPACT: Enables monitoring and debugging of deployment status
locals {
  deployment_status = {
    phase_1_complete = true  # Configuration and validation complete
    phase_2_complete = false # Azure infrastructure (to be implemented)
    phase_3_complete = false # Power Platform policies (to be implemented)

    environments_processed = length(local.processed_environments)
    environments_ready     = length(local.vnet_ready_environments)
    modules_planned = (length(local.planned_modules.primary_resource_groups) +
      length(local.planned_modules.failover_resource_groups) +
      length(local.planned_modules.primary_virtual_networks) +
      length(local.planned_modules.failover_virtual_networks) +
      length(local.planned_modules.enterprise_policies) +
    length(local.planned_modules.policy_links))

    validation_status   = local.configuration_valid
    remote_state_status = local.remote_state_valid
  }
}