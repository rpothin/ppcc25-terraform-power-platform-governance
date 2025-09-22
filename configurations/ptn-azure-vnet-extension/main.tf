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
# ENVIRONMENT SEPARATION - Production vs Non-Production
# ============================================================================

# WHY: Separate production and non-production environments for provider routing
# CONTEXT: Terraform doesn't support conditional provider references in module blocks
# IMPACT: Enables proper subscription-level governance through explicit separation
locals {
  # Filter environments by type for provider routing
  production_environments = {
    for idx, env in local.vnet_ready_environments : idx => env
    if env.environment_type == "Production"
  }

  non_production_environments = {
    for idx, env in local.vnet_ready_environments : idx => env
    if env.environment_type != "Production"
  }
}

# ============================================================================
# AZURE INFRASTRUCTURE DEPLOYMENT - Phase 2 Implementation
# ============================================================================

# WHY: Deploy actual Azure infrastructure instead of validation placeholders
# CONTEXT: Phase 2 transforms pattern from planning to resource deployment
# IMPACT: Creates VNets and enterprise policies per environment

# ============================================================================
# RESOURCE GROUP ORCHESTRATION - Production and Non-Production Separation
# ============================================================================

# WHY: Deploy single resource group per production environment in primary location
# CONTEXT: Single RG contains both primary and failover VNets for easier management
# IMPACT: Simplified governance with one RG per Power Platform environment
module "production_resource_groups" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "~> 0.2.0"
  for_each = local.production_environments

  # WHY: Use production provider for production environments
  # CONTEXT: Routes production resources to dedicated subscription
  # IMPACT: Enables proper subscription-level governance and isolation
  providers = {
    azurerm = azurerm.production
  }

  # Basic resource group configuration - single RG per environment
  name     = local.environment_resource_names[each.key].resource_group_name
  location = local.network_configuration[each.key].primary_location

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Architecture   = "single-rg-per-environment"
      EnvironmentKey = each.key
    }
  )
}

# WHY: Deploy single resource group per non-production environment in primary location
# CONTEXT: Single RG contains both primary and failover VNets for easier management
# IMPACT: Cost-effective resource organization with one RG per Power Platform environment
module "non_production_resource_groups" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "~> 0.2.0"
  for_each = local.non_production_environments

  # WHY: Use default provider for non-production environments
  # CONTEXT: Routes non-production resources to shared subscription
  # IMPACT: Enables cost-effective resource management
  providers = {
    azurerm = azurerm
  }

  # Basic resource group configuration - single RG per environment
  name     = local.environment_resource_names[each.key].resource_group_name
  location = local.network_configuration[each.key].primary_location

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Architecture   = "single-rg-per-environment"
      EnvironmentKey = each.key
    }
  )
}

# ============================================================================
# VIRTUAL NETWORK ORCHESTRATION - Production and Non-Production Separation
# ============================================================================

# WHY: Deploy primary VNets for production environments in single resource group
# CONTEXT: Primary VNets provide main connectivity in primary region
# IMPACT: Secure network foundation for Power Platform integration
module "production_primary_virtual_networks" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm"
  version  = "~> 0.7.2"
  for_each = local.production_environments

  # WHY: Use production provider for production environments
  # CONTEXT: Routes production resources to dedicated subscription
  # IMPACT: Enables proper subscription-level governance and isolation
  providers = {
    azurerm = azurerm.production
  }

  # Basic VNet configuration with dynamic IP allocation
  name                = "${local.environment_resource_names[each.key].virtual_network_base_name}-${local.region_abbreviations[local.network_configuration[each.key].primary_location]}-primary"
  location            = local.network_configuration[each.key].primary_location
  resource_group_name = module.production_resource_groups[each.key].name
  address_space       = [local.network_configuration[each.key].primary_vnet_address_space]

  # Subnet configuration with Power Platform delegation
  subnets = {
    "PowerPlatformSubnet" = {
      name             = local.environment_resource_names[each.key].subnet_name
      address_prefixes = [local.network_configuration[each.key].primary_power_platform_subnet_cidr]

      # WHY: Subnet delegation required for Power Platform enterprise policies
      # CONTEXT: Microsoft.PowerPlatform/enterprisePolicies requires dedicated delegation
      # IMPACT: Enables network injection policies for discovered environments
      delegation = [
        {
          name = "PowerPlatformDelegation"
          service_delegation = {
            name = "Microsoft.PowerPlatform/enterprisePolicies"
          }
        }
      ]
    }

    "PrivateEndpointSubnet" = {
      name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(each.value.suffix, " ", "")}"
      address_prefixes = [local.network_configuration[each.key].primary_private_endpoint_subnet_cidr]
    }
  }

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Region         = "primary"
      EnvironmentKey = each.key
      NetworkRange   = local.network_configuration[each.key].primary_vnet_address_space
    }
  )

  depends_on = [module.production_resource_groups]
}

# WHY: Deploy primary VNets for non-production environments in single resource group
# CONTEXT: Primary VNets provide main connectivity in primary region
# IMPACT: Cost-effective network foundation for Power Platform integration
module "non_production_primary_virtual_networks" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm"
  version  = "~> 0.7.2"
  for_each = local.non_production_environments

  # WHY: Use default provider for non-production environments
  # CONTEXT: Routes non-production resources to shared subscription
  # IMPACT: Enables cost-effective resource management
  providers = {
    azurerm = azurerm
  }

  # Basic VNet configuration with dynamic IP allocation
  name                = "${local.environment_resource_names[each.key].virtual_network_base_name}-${local.region_abbreviations[local.network_configuration[each.key].primary_location]}-primary"
  location            = local.network_configuration[each.key].primary_location
  resource_group_name = module.non_production_resource_groups[each.key].name
  address_space       = [local.network_configuration[each.key].primary_vnet_address_space]

  # Subnet configuration with Power Platform delegation
  subnets = {
    "PowerPlatformSubnet" = {
      name             = local.environment_resource_names[each.key].subnet_name
      address_prefixes = [local.network_configuration[each.key].primary_power_platform_subnet_cidr]

      # WHY: Subnet delegation required for Power Platform enterprise policies
      # CONTEXT: Microsoft.PowerPlatform/enterprisePolicies requires dedicated delegation
      # IMPACT: Enables network injection policies for discovered environments
      delegation = [
        {
          name = "PowerPlatformDelegation"
          service_delegation = {
            name = "Microsoft.PowerPlatform/enterprisePolicies"
          }
        }
      ]
    }

    "PrivateEndpointSubnet" = {
      name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(each.value.suffix, " ", "")}"
      address_prefixes = [local.network_configuration[each.key].primary_private_endpoint_subnet_cidr]
    }
  }

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Region         = "primary"
      EnvironmentKey = each.key
      NetworkRange   = local.network_configuration[each.key].primary_vnet_address_space
    }
  )

  depends_on = [module.non_production_resource_groups]
} # WHY: Deploy failover VNets for production environments in same resource group as primary
# CONTEXT: Single RG per environment contains both primary and failover VNets
# IMPACT: Simplified governance with all environment resources in one place
module "production_failover_virtual_networks" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm"
  version  = "~> 0.7.2"
  for_each = local.production_environments

  # WHY: Use production provider for production environments
  # CONTEXT: Routes production resources to dedicated subscription
  # IMPACT: Enables proper subscription-level governance and isolation
  providers = {
    azurerm = azurerm.production
  }

  # Basic VNet configuration with dynamic IP allocation
  name                = "${local.environment_resource_names[each.key].virtual_network_base_name}-${local.region_abbreviations[local.network_configuration[each.key].failover_location]}-failover"
  location            = local.network_configuration[each.key].failover_location
  resource_group_name = module.production_resource_groups[each.key].name
  address_space       = [local.network_configuration[each.key].failover_vnet_address_space]

  # Subnet configuration with Power Platform delegation
  subnets = {
    "PowerPlatformSubnet" = {
      name             = local.environment_resource_names[each.key].subnet_name
      address_prefixes = [local.network_configuration[each.key].failover_power_platform_subnet_cidr]

      # WHY: Mirror delegation configuration from primary region
      # CONTEXT: Failover VNet must support same enterprise policy capabilities
      # IMPACT: Enables seamless failover for Power Platform workloads
      delegation = [
        {
          name = "PowerPlatformDelegation"
          service_delegation = {
            name = "Microsoft.PowerPlatform/enterprisePolicies"
          }
        }
      ]
    }

    "PrivateEndpointSubnet" = {
      name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(each.value.suffix, " ", "")}"
      address_prefixes = [local.network_configuration[each.key].failover_private_endpoint_subnet_cidr]
    }
  }

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Region         = "failover"
      EnvironmentKey = each.key
      NetworkRange   = local.network_configuration[each.key].failover_vnet_address_space
    }
  )

  depends_on = [module.production_resource_groups]
}

# WHY: Deploy failover VNets for non-production environments in same resource group as primary
# CONTEXT: Single RG per environment contains both primary and failover VNets
# IMPACT: Cost-effective resource organization with all environment resources in one place
module "non_production_failover_virtual_networks" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm"
  version  = "~> 0.7.2"
  for_each = local.non_production_environments

  # WHY: Use default provider for non-production environments
  # CONTEXT: Routes non-production resources to shared subscription
  # IMPACT: Enables cost-effective resource management
  providers = {
    azurerm = azurerm
  }

  # Basic VNet configuration with dynamic IP allocation
  name                = "${local.environment_resource_names[each.key].virtual_network_base_name}-${local.region_abbreviations[local.network_configuration[each.key].failover_location]}-failover"
  location            = local.network_configuration[each.key].failover_location
  resource_group_name = module.non_production_resource_groups[each.key].name
  address_space       = [local.network_configuration[each.key].failover_vnet_address_space]

  # Subnet configuration with Power Platform delegation
  subnets = {
    "PowerPlatformSubnet" = {
      name             = local.environment_resource_names[each.key].subnet_name
      address_prefixes = [local.network_configuration[each.key].failover_power_platform_subnet_cidr]

      # WHY: Mirror delegation configuration from primary region
      # CONTEXT: Failover VNet must support same enterprise policy capabilities
      # IMPACT: Enables seamless failover for Power Platform workloads
      delegation = [
        {
          name = "PowerPlatformDelegation"
          service_delegation = {
            name = "Microsoft.PowerPlatform/enterprisePolicies"
          }
        }
      ]
    }

    "PrivateEndpointSubnet" = {
      name             = "snet-privateendpoint-${local.base_name_components.project}-${local.base_name_components.workspace}-${replace(each.value.suffix, " ", "")}"
      address_prefixes = [local.network_configuration[each.key].failover_private_endpoint_subnet_cidr]
    }
  }

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Region         = "failover"
      EnvironmentKey = each.key
      NetworkRange   = local.network_configuration[each.key].failover_vnet_address_space
    }
  )

  depends_on = [module.non_production_resource_groups]
}

# ============================================================================
# PRIVATE DNS ZONE ORCHESTRATION - Phase 2 AVM Module Integration
# ============================================================================

# WHY: Deploy private DNS zones on-demand for Azure service connectivity
# CONTEXT: Phase 2 implements actual AVM modules for DNS zones with VNet links
# IMPACT: Enables private endpoint connectivity for any Azure service

# Production Private DNS Zones with VNet Links
module "production_private_dns_zones" {
  for_each = {
    for combo in setproduct(keys(local.production_environments), var.private_dns_zones) :
    "${combo[0]}-${replace(combo[1], ".", "-")}" => {
      env_key     = combo[0]
      domain_name = combo[1]
    }
  }

  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.1"

  # DNS zone configuration using parent_id for resource group
  domain_name = each.value.domain_name
  parent_id   = module.production_resource_groups[each.value.env_key].resource_id

  # WHY: Link to both primary and failover VNets for comprehensive DNS resolution
  # CONTEXT: Dual VNet architecture requires DNS resolution in both regions
  # IMPACT: Ensures private endpoints resolve correctly from either VNet
  virtual_network_links = {
    primary_vnet = {
      name                 = "link-primary-${each.value.env_key}"
      virtual_network_id   = module.production_primary_virtual_networks[each.value.env_key].resource_id
      registration_enabled = false
    }
    failover_vnet = {
      name                 = "link-failover-${each.value.env_key}"
      virtual_network_id   = module.production_failover_virtual_networks[each.value.env_key].resource_id
      registration_enabled = false
    }
  }

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = local.production_environments[each.value.env_key].environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Component      = "private-dns-zone"
      EnvironmentKey = each.value.env_key
      DNSZone        = each.value.domain_name
    }
  )

  # WHY: AVM DNS zone modules use azapi provider internally, not azurerm
  # CONTEXT: No need to pass azurerm provider to DNS zone modules
  # IMPACT: Eliminates provider reference warnings
  # NOTE: The module deploys to the correct subscription via parent_id resource group reference

  depends_on = [
    module.production_primary_virtual_networks,
    module.production_failover_virtual_networks
  ]
}

# Non-Production Private DNS Zones with VNet Links
module "non_production_private_dns_zones" {
  for_each = {
    for combo in setproduct(keys(local.non_production_environments), var.private_dns_zones) :
    "${combo[0]}-${replace(combo[1], ".", "-")}" => {
      env_key     = combo[0]
      domain_name = combo[1]
    }
  }

  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.1"

  # DNS zone configuration using parent_id for resource group
  domain_name = each.value.domain_name
  parent_id   = module.non_production_resource_groups[each.value.env_key].resource_id

  # WHY: Link to both primary and failover VNets for comprehensive DNS resolution
  # CONTEXT: Dual VNet architecture requires DNS resolution in both regions
  # IMPACT: Ensures private endpoints resolve correctly from either VNet
  virtual_network_links = {
    primary_vnet = {
      name                 = "link-primary-${each.value.env_key}"
      virtual_network_id   = module.non_production_primary_virtual_networks[each.value.env_key].resource_id
      registration_enabled = false
    }
    failover_vnet = {
      name                 = "link-failover-${each.value.env_key}"
      virtual_network_id   = module.non_production_failover_virtual_networks[each.value.env_key].resource_id
      registration_enabled = false
    }
  }

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = local.non_production_environments[each.value.env_key].environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Component      = "private-dns-zone"
      EnvironmentKey = each.value.env_key
      DNSZone        = each.value.domain_name
    }
  )

  # WHY: AVM DNS zone modules use azapi provider internally, not azurerm
  # CONTEXT: No need to pass azurerm provider to DNS zone modules  
  # IMPACT: Eliminates provider reference warnings
  # NOTE: The module deploys to the correct subscription via parent_id resource group reference

  depends_on = [
    module.non_production_primary_virtual_networks,
    module.non_production_failover_virtual_networks
  ]
}

# ============================================================================
# NETWORK SECURITY GROUP ORCHESTRATION - Phase 2 Zero-Trust Implementation
# ============================================================================

# WHY: Deploy unified NSG per environment following "Keep It Simple" principle
# CONTEXT: Single NSG serves both PowerPlatform and PrivateEndpoint subnets with identical rules
# IMPACT: Reduced complexity while maintaining same security posture (5 focused zero-trust rules)

# Production Environment NSGs (Unified)
module "production_nsgs" {
  for_each = local.production_environments

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  # WHY: Single NSG per environment simplifies management
  # CONTEXT: Both subnet types need identical security rules per VNet injection architecture
  # IMPACT: Eliminates duplicate resources while maintaining security functionality
  name                = "nsg-unified-${local.environment_resource_names[each.key].env_suffix_clean}"
  resource_group_name = module.production_resource_groups[each.key].name
  location            = local.network_configuration[each.key].primary_location

  # WHY: Apply zero-trust rules conditionally based on variable
  # CONTEXT: Same 5 focused rules apply to both PowerPlatform and PrivateEndpoint subnets
  # IMPACT: Security by default with configurable development flexibility
  security_rules = var.enable_zero_trust_networking ? local.zero_trust_nsg_rules : {}

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = each.value.environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Component      = "network-security-group"
      SubnetTypes    = "PowerPlatform,PrivateEndpoint" # Serves both subnet types
      EnvironmentKey = each.key
      ZeroTrust      = var.enable_zero_trust_networking ? "enabled" : "disabled"
      Architecture   = "unified-nsg-per-environment"
    }
  )

  # WHY: Use production provider for production environments
  # CONTEXT: Routes production resources to dedicated subscription
  # IMPACT: Enables proper subscription-level governance and isolation
  providers = {
    azurerm = azurerm.production
  }

  depends_on = [module.production_resource_groups]
}

# Non-Production Environment NSGs (Unified)
module "non_production_nsgs" {
  for_each = local.non_production_environments

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  # WHY: Single NSG per environment simplifies management
  # CONTEXT: Both subnet types need identical security rules per VNet injection architecture
  # IMPACT: Eliminates duplicate resources while maintaining security functionality
  name                = "nsg-unified-${local.environment_resource_names[each.key].env_suffix_clean}"
  resource_group_name = module.non_production_resource_groups[each.key].name
  location            = local.network_configuration[each.key].primary_location

  # WHY: Apply zero-trust rules conditionally based on variable
  # CONTEXT: Same 5 focused rules apply to both PowerPlatform and PrivateEndpoint subnets
  # IMPACT: Security by default with configurable development flexibility
  security_rules = var.enable_zero_trust_networking ? local.zero_trust_nsg_rules : {}

  # Enterprise tagging for governance
  tags = merge(
    var.tags,
    {
      Environment    = local.non_production_environments[each.key].environment_type
      Workspace      = local.remote_workspace_name
      Pattern        = "ptn-azure-vnet-extension"
      Component      = "network-security-group"
      SubnetTypes    = "PowerPlatform,PrivateEndpoint" # Serves both subnet types
      EnvironmentKey = each.key
      ZeroTrust      = var.enable_zero_trust_networking ? "enabled" : "disabled"
      Architecture   = "unified-nsg-per-environment"
    }
  )

  # WHY: Use default provider for non-production environments
  # CONTEXT: Routes non-production resources to shared subscription
  # IMPACT: Enables cost-effective resource management
  providers = {
    azurerm = azurerm
  }

  depends_on = [module.non_production_resource_groups]
}

# NSG-SUBNET ASSOCIATIONS - Phase 2 Security Rule Enforcement
# WHY: Associate unified NSGs with both subnet types for consistent security
# CONTEXT: Single NSG per environment serves both PowerPlatform and PrivateEndpoint subnets
# IMPACT: Simplified management with identical security rules across both subnet types

# Production PowerPlatform Subnet Associations
resource "azurerm_subnet_network_security_group_association" "production_power_platform" {
  for_each = local.production_environments

  subnet_id                 = module.production_primary_virtual_networks[each.key].subnets["PowerPlatformSubnet"].resource_id
  network_security_group_id = module.production_nsgs[each.key].resource_id

  # Use production provider for production environments
  provider = azurerm.production

  depends_on = [
    module.production_primary_virtual_networks,
    module.production_nsgs
  ]
}

# Non-Production PowerPlatform Subnet Associations
resource "azurerm_subnet_network_security_group_association" "non_production_power_platform" {
  for_each = local.non_production_environments

  subnet_id                 = module.non_production_primary_virtual_networks[each.key].subnets["PowerPlatformSubnet"].resource_id
  network_security_group_id = module.non_production_nsgs[each.key].resource_id

  depends_on = [
    module.non_production_primary_virtual_networks,
    module.non_production_nsgs
  ]
}

# Production PrivateEndpoint Subnet Associations
resource "azurerm_subnet_network_security_group_association" "production_private_endpoint" {
  for_each = local.production_environments

  subnet_id                 = module.production_primary_virtual_networks[each.key].subnets["PrivateEndpointSubnet"].resource_id
  network_security_group_id = module.production_nsgs[each.key].resource_id

  # Use production provider for production environments
  provider = azurerm.production

  depends_on = [
    module.production_primary_virtual_networks,
    module.production_nsgs
  ]
}

# Non-Production PrivateEndpoint Subnet Associations
resource "azurerm_subnet_network_security_group_association" "non_production_private_endpoint" {
  for_each = local.non_production_environments

  subnet_id                 = module.non_production_primary_virtual_networks[each.key].subnets["PrivateEndpointSubnet"].resource_id
  network_security_group_id = module.non_production_nsgs[each.key].resource_id

  depends_on = [
    module.non_production_primary_virtual_networks,
    module.non_production_nsgs
  ]
}


# WHY: Create NetworkInjection enterprise policies for production environments
# CONTEXT: Production Power Platform workloads require dedicated VNet infrastructure
# IMPACT: Provides network injection capabilities for production environments
module "production_enterprise_policies" {
  source   = "../res-enterprise-policy"
  for_each = local.production_environments

  # Enterprise policy configuration for NetworkInjection
  policy_configuration = {
    name              = local.environment_resource_names[each.key].enterprise_policy_name
    location          = local.azure_to_power_platform_regions[local.network_configuration[each.key].primary_location]
    policy_type       = "NetworkInjection"
    resource_group_id = module.production_resource_groups[each.key].resource_id

    # Network injection configuration with both primary and failover VNets
    network_injection_config = {
      virtual_networks = [
        {
          id = module.production_primary_virtual_networks[each.key].resource_id
          subnet = {
            name = local.environment_resource_names[each.key].subnet_name
          }
        },
        {
          id = module.production_failover_virtual_networks[each.key].resource_id
          subnet = {
            name = local.environment_resource_names[each.key].subnet_name
          }
        }
      ]
    }
  }

  # Ensure VNets are created before enterprise policies
  depends_on = [
    module.production_primary_virtual_networks,
    module.production_failover_virtual_networks
  ]
}

# WHY: Create NetworkInjection enterprise policies for non-production environments
# CONTEXT: Dev, Test, Staging Power Platform workloads use shared VNet infrastructure
# IMPACT: Provides network injection capabilities for non-production environments
module "non_production_enterprise_policies" {
  source   = "../res-enterprise-policy"
  for_each = local.non_production_environments

  # Enterprise policy configuration for NetworkInjection
  policy_configuration = {
    name              = local.environment_resource_names[each.key].enterprise_policy_name
    location          = local.azure_to_power_platform_regions[local.network_configuration[each.key].primary_location]
    policy_type       = "NetworkInjection"
    resource_group_id = module.non_production_resource_groups[each.key].resource_id

    # Network injection configuration with both primary and failover VNets
    network_injection_config = {
      virtual_networks = [
        {
          id = module.non_production_primary_virtual_networks[each.key].resource_id
          subnet = {
            name = local.environment_resource_names[each.key].subnet_name
          }
        },
        {
          id = module.non_production_failover_virtual_networks[each.key].resource_id
          subnet = {
            name = local.environment_resource_names[each.key].subnet_name
          }
        }
      ]
    }
  }

  # Ensure VNets are created before enterprise policies
  depends_on = [
    module.non_production_primary_virtual_networks,
    module.non_production_failover_virtual_networks
  ]
}

# ============================================================================
# POWER PLATFORM POLICY LINKING - Production and Non-Production Separation
# ============================================================================

# WHY: Link enterprise policies to production Power Platform environments
# CONTEXT: Assigns NetworkInjection policies to production environments from remote state
# IMPACT: Enables VNet integration for production Power Platform environments
module "production_policy_links" {
  source   = "../res-enterprise-policy-link"
  for_each = local.production_environments

  # Policy linking configuration using individual variables
  environment_id = each.value.environment_id
  policy_type    = "NetworkInjection"
  system_id      = module.production_enterprise_policies[each.key].enterprise_policy_system_id

  # Ensure enterprise policies are created before linking
  depends_on = [module.production_enterprise_policies]
}

# WHY: Link enterprise policies to non-production Power Platform environments
# CONTEXT: Assigns NetworkInjection policies to non-production environments from remote state
# IMPACT: Enables VNet integration for non-production Power Platform environments
module "non_production_policy_links" {
  source   = "../res-enterprise-policy-link"
  for_each = local.non_production_environments

  # Policy linking configuration using individual variables
  environment_id = each.value.environment_id
  policy_type    = "NetworkInjection"
  system_id      = module.non_production_enterprise_policies[each.key].enterprise_policy_system_id

  # Ensure enterprise policies are created before linking
  depends_on = [module.non_production_enterprise_policies]
}

# ============================================================================
# DEPLOYMENT STATUS TRACKING
# ============================================================================

# WHY: Track deployment progress and provide status information
# CONTEXT: Phase 2 deployment includes actual Azure resources and Power Platform integration
# IMPACT: Enables monitoring and debugging of deployment status
locals {
  deployment_status = {
    phase_1_complete = true # Configuration and validation complete
    phase_2_complete = true # Azure infrastructure deployed
    phase_3_complete = true # Power Platform policies deployed

    environments_processed      = length(local.processed_environments)
    environments_ready          = length(local.vnet_ready_environments)
    production_environments     = length(local.production_environments)
    non_production_environments = length(local.non_production_environments)

    # Resource group deployment status - Single RG per environment architecture
    production_resource_groups     = length(module.production_resource_groups)
    non_production_resource_groups = length(module.non_production_resource_groups)

    # Virtual network deployment status
    production_primary_virtual_networks      = length(module.production_primary_virtual_networks)
    production_failover_virtual_networks     = length(module.production_failover_virtual_networks)
    non_production_primary_virtual_networks  = length(module.non_production_primary_virtual_networks)
    non_production_failover_virtual_networks = length(module.non_production_failover_virtual_networks)

    # Network Security Group deployment status - Unified architecture (1 NSG per environment)
    production_nsgs     = length(module.production_nsgs)
    non_production_nsgs = length(module.non_production_nsgs)

    # Enterprise policy deployment status
    production_enterprise_policies     = length(module.production_enterprise_policies)
    non_production_enterprise_policies = length(module.non_production_enterprise_policies)
    production_policy_links            = length(module.production_policy_links)
    non_production_policy_links        = length(module.non_production_policy_links)

    validation_status   = local.configuration_valid
    remote_state_status = local.remote_state_valid
  }
}