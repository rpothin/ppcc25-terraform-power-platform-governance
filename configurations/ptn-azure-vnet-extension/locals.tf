# Local Values for Power Platform Azure VNet Extension Pattern Configuration
#
# This file contains data transformation logic, Cloud Adoption Framework (CAF) 
# naming conventions, and subscription mapping based on remote state data.

# ============================================================================
# ENVIRONMENT PROCESSING - Remote State Data Transformation
# ============================================================================

# WHY: Transform remote state data into actionable environment configuration
# CONTEXT: Remote state provides environment metadata that needs processing for Azure deployment
# IMPACT: Creates structured data for for_each loops and resource creation
locals {
  # Process environments from remote state for VNet integration
  processed_environments = {
    for idx, env_id in local.remote_environment_ids : idx => {
      environment_id   = env_id
      environment_name = try(local.remote_environment_names[idx], "Unknown-${idx}")
      environment_type = try(local.remote_environment_types[idx], "Sandbox")
      suffix           = try(local.remote_environment_suffixes[idx], "-${idx}")

      # Determine Azure subscription based on environment type
      subscription_id = try(local.remote_environment_types[idx], "Sandbox") == "Production" ? var.production_subscription_id : var.non_production_subscription_id

      # Generate environment-specific configuration
      is_production = try(local.remote_environment_types[idx] == "Production", false)

      # WHY: Dual region support - determine primary region based on environment classification
      # CONTEXT: Production environments get primary region, non-production can use either
      # IMPACT: Provides regional placement strategy while supporting dual VNet architecture
      primary_region  = var.network_configuration.primary.location
      failover_region = var.network_configuration.failover.location
    }
  }

  # Filter environments that are ready for VNet integration
  # WHY: Only managed environments can have enterprise policies applied
  # CONTEXT: Enterprise policies require managed environments as prerequisite
  # IMPACT: Prevents policy application failures for non-managed environments
  vnet_ready_environments = {
    for idx, env in local.processed_environments : idx => env
    # NOTE: In Phase 2, add managed environment filtering when res-environment supports it
    # if try(env.is_managed, false) == true
  }
}

# ============================================================================
# CLOUD ADOPTION FRAMEWORK (CAF) NAMING CONVENTIONS
# ============================================================================

# WHY: Consistent naming following Microsoft Cloud Adoption Framework guidelines
# CONTEXT: CAF naming ensures predictable, governance-compliant resource names
# IMPACT: All Azure resources follow enterprise naming standards
locals {
  # Azure region abbreviations for CAF-compliant naming
  region_abbreviations = {
    "East US"              = "eus"
    "East US 2"            = "eus2"
    "West US"              = "wus"
    "West US 2"            = "wus2"
    "West US 3"            = "wus3"
    "Central US"           = "cus"
    "North Central US"     = "ncus"
    "South Central US"     = "scus"
    "West Europe"          = "weu"
    "North Europe"         = "neu"
    "UK South"             = "uks"
    "UK West"              = "ukw"
    "France Central"       = "frc"
    "Germany West Central" = "gwc"
    "Switzerland North"    = "szn"
    "Southeast Asia"       = "sea"
    "East Asia"            = "ea"
    "Australia East"       = "aue"
    "Australia Southeast"  = "ause"
    "Japan East"           = "jpe"
    "Japan West"           = "jpw"
    "Canada Central"       = "cac"
    "Canada East"          = "cae"
    "Brazil South"         = "brs"
    "South Africa North"   = "san"
    "UAE North"            = "uan"
    "Korea Central"        = "krc"
    "India Central"        = "inc"
  }

  # Azure region to Power Platform region mapping
  # WHY: Enterprise policies use Power Platform regions, not Azure regions
  # CONTEXT: Power Platform has different region names than Azure
  # IMPACT: Enables correct enterprise policy creation with proper region mapping
  azure_to_power_platform_regions = {
    # United States regions
    "East US"          = "unitedstates"
    "East US 2"        = "unitedstates"
    "West US"          = "unitedstates"
    "West US 2"        = "unitedstates"
    "West US 3"        = "unitedstates"
    "Central US"       = "unitedstates"
    "North Central US" = "unitedstates"
    "South Central US" = "unitedstates"

    # Europe regions
    "West Europe"          = "europe"
    "North Europe"         = "europe"
    "UK South"             = "uk"
    "UK West"              = "uk"
    "France Central"       = "france"
    "Germany West Central" = "germany"
    "Switzerland North"    = "switzerland"

    # Asia-Pacific regions
    "Southeast Asia"      = "asia"
    "East Asia"           = "asia"
    "Australia East"      = "australia"
    "Australia Southeast" = "australia"
    "Japan East"          = "japan"
    "Japan West"          = "japan"
    "Korea Central"       = "korea"

    # Other regions
    "Canada Central"     = "canada"
    "Canada East"        = "canada"
    "Brazil South"       = "southamerica"
    "South Africa North" = "southafrica"
    "UAE North"          = "uae"
    "India Central"      = "india"
    "Norway East"        = "norway"
  }

  # Base naming components for Cloud Adoption Framework (CAF) compliance
  base_name_components = {
    project   = "ppcc25"
    workspace = lower(local.remote_workspace_name)

    # WHY: Support primary region as default for naming consistency
    # CONTEXT: Most resources use primary region unless specifically failover-targeted
    # IMPACT: Maintains consistent naming patterns while supporting dual regions
    location = local.region_abbreviations[var.network_configuration.primary.location]
  }

  # CAF-compliant naming patterns - Single RG per environment architecture
  naming_patterns = {
    resource_group    = "rg-${local.base_name_components.project}-${local.base_name_components.workspace}-{env_suffix}-vnet-${local.base_name_components.location}"
    virtual_network   = "vnet-${local.base_name_components.project}-${local.base_name_components.workspace}-{env_suffix}-${local.base_name_components.location}"
    subnet            = "snet-powerplatform-${local.base_name_components.project}-${local.base_name_components.workspace}-{env_suffix}"
    enterprise_policy = "ep-vnet-${local.base_name_components.project}-${local.base_name_components.workspace}-{env_suffix}"
  }
}

# ============================================================================
# RESOURCE NAMING - Environment-Specific Name Generation
# ============================================================================

# WHY: Generate actual resource names for each environment using CAF patterns
# CONTEXT: Each environment gets dedicated Azure resources with consistent naming
# IMPACT: Predictable resource names for governance, monitoring, and management
locals {
  # Generate environment-specific resource names
  environment_resource_names = {
    for idx, env in local.processed_environments : idx => {
      # Clean environment suffix for use in resource names
      env_suffix_clean = lower(replace(replace(env.suffix, " ", ""), "-", ""))

      # Resource names following CAF patterns
      resource_group_name = replace(
        local.naming_patterns.resource_group,
        "{env_suffix}",
        lower(replace(replace(env.suffix, " ", ""), "-", ""))
      )

      virtual_network_name = replace(
        local.naming_patterns.virtual_network,
        "{env_suffix}",
        lower(replace(replace(env.suffix, " ", ""), "-", ""))
      )

      subnet_name = replace(
        local.naming_patterns.subnet,
        "{env_suffix}",
        lower(replace(replace(env.suffix, " ", ""), "-", ""))
      )

      enterprise_policy_name = replace(
        local.naming_patterns.enterprise_policy,
        "{env_suffix}",
        lower(replace(replace(env.suffix, " ", ""), "-", ""))
      )

      # Display name variants (for resources supporting display names)
      resource_group_display_name    = "${local.remote_workspace_name}${env.suffix} - VNet Infrastructure"
      virtual_network_display_name   = "${local.remote_workspace_name}${env.suffix} - Power Platform VNet"
      enterprise_policy_display_name = "${local.remote_workspace_name}${env.suffix} - VNet Integration Policy"
    }
  }
}

# ============================================================================
# SUBSCRIPTION MAPPING - Multi-Subscription Configuration
# ============================================================================

# WHY: Map environments to appropriate Azure subscriptions based on environment type
# CONTEXT: Production and non-production environments should be in separate subscriptions
# IMPACT: Supports enterprise subscription governance and isolation requirements
locals {
  # Subscription mapping per environment
  subscription_mapping = {
    for idx, env in local.processed_environments : idx => {
      subscription_id            = env.subscription_id
      environment_classification = env.is_production ? "production" : "non-production"
      subscription_alias         = env.is_production ? "prod-subscription" : "non-prod-subscription"

      # Subscription-level tagging strategy
      subscription_tags = merge(
        var.tags,
        {
          Environment    = env.environment_type
          Workspace      = local.remote_workspace_name
          Pattern        = "ptn-azure-vnet-extension"
          Classification = env.is_production ? "production" : "non-production"
        }
      )
    }
  }
}

# ============================================================================
# NETWORK CONFIGURATION - Dynamic Per-Environment IP Allocation
# ============================================================================

# Create numeric index mapping for CIDR calculations
# WHY: cidrsubnet() requires numeric indices, but environment keys are names
# CONTEXT: Maps "dev"->0, "test"->1, "prod"->2 for deterministic IP allocation
# IMPACT: Enables stable IP calculation regardless of environment naming
locals {
  # Generate numeric indices for environments in alphabetical order (deterministic)
  environment_numeric_mapping = {
    for i, env_name in sort(keys(local.processed_environments)) : env_name => i
  }
}

# WHY: Calculate unique IP ranges for each environment to prevent conflicts
# CONTEXT: Each environment gets dedicated /16 subnet from base address space
# IMPACT: Supports 2-N environments with automatic non-overlapping IP allocation
locals {
  # Dynamic network configuration per environment - supporting dual VNet architecture
  network_configuration = {
    for idx, env in local.processed_environments : idx => {
      # WHY: Calculate per-environment /16 from base /12 address space
      # CONTEXT: Environment 0 gets 10.100.0.0/16, env 1 gets 10.101.0.0/16, etc.
      # IMPACT: Each environment gets 65,536 IPs with guaranteed non-overlap
      primary_vnet_address_space  = cidrsubnet(var.network_configuration.primary.vnet_address_space_base, 4, local.environment_numeric_mapping[idx])
      failover_vnet_address_space = cidrsubnet(var.network_configuration.failover.vnet_address_space_base, 4, local.environment_numeric_mapping[idx])

      # WHY: Calculate consistent subnet layout within each environment's /16
      # CONTEXT: Power Platform gets .1.0/24, private endpoints get .2.0/24
      # IMPACT: Standardized addressing across all environments
      primary_power_platform_subnet_cidr = cidrsubnet(
        cidrsubnet(var.network_configuration.primary.vnet_address_space_base, 4, local.environment_numeric_mapping[idx]),
        var.network_configuration.subnet_allocation.power_platform_subnet_size - 16,
        var.network_configuration.subnet_allocation.power_platform_offset
      )
      primary_private_endpoint_subnet_cidr = cidrsubnet(
        cidrsubnet(var.network_configuration.primary.vnet_address_space_base, 4, local.environment_numeric_mapping[idx]),
        var.network_configuration.subnet_allocation.private_endpoint_subnet_size - 16,
        var.network_configuration.subnet_allocation.private_endpoint_offset
      )

      # WHY: Mirror subnet calculation for failover region
      # CONTEXT: Same subnet layout pattern in different IP range
      # IMPACT: Consistent network architecture across regions
      failover_power_platform_subnet_cidr = cidrsubnet(
        cidrsubnet(var.network_configuration.failover.vnet_address_space_base, 4, local.environment_numeric_mapping[idx]),
        var.network_configuration.subnet_allocation.power_platform_subnet_size - 16,
        var.network_configuration.subnet_allocation.power_platform_offset
      )
      failover_private_endpoint_subnet_cidr = cidrsubnet(
        cidrsubnet(var.network_configuration.failover.vnet_address_space_base, 4, local.environment_numeric_mapping[idx]),
        var.network_configuration.subnet_allocation.private_endpoint_subnet_size - 16,
        var.network_configuration.subnet_allocation.private_endpoint_offset
      )

      # Regional locations (static)
      primary_location  = var.network_configuration.primary.location
      failover_location = var.network_configuration.failover.location

      # Subnet delegation for Power Platform enterprise policies (both regions)
      subnet_delegation = {
        name = "PowerPlatformEnterprisePolicy"
        service_delegation = {
          name    = "Microsoft.PowerPlatform/enterprisePolicies"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }

      # Network security considerations
      network_security_group_rules = {
        allow_power_platform = {
          name                       = "AllowPowerPlatformTraffic"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "PowerPlatform"
          destination_address_prefix = "*"
        }
      }
    }
  }
}

# ============================================================================
# VALIDATION LOCALS - Configuration Validation and Error Checking
# ============================================================================

# ============================================================================
# NETWORK VALIDATION - Dual VNet Architecture Validation  
# ============================================================================

# WHY: Validate network configuration before resource deployment
# CONTEXT: Dual VNet architecture requires validation of both regions
# IMPACT: Prevents deployment failures and ensures proper network design
locals {
  # Network validation helpers for dynamic IP allocation
  # WHY: Validate that base address spaces are large enough for environment scaling
  # CONTEXT: /12 base allows 16 environments, each with /16 VNet containing /24 subnets
  # IMPACT: Prevents IP conflicts and ensures sufficient capacity
  base_address_capacity_valid = (
    # Primary base address space must be /12 or larger (supports 16 environments)
    tonumber(split("/", var.network_configuration.primary.vnet_address_space_base)[1]) <= 12 &&
    tonumber(split("/", var.network_configuration.failover.vnet_address_space_base)[1]) <= 12
  )

  # Check that base address spaces don't overlap  
  base_address_ranges_non_overlapping = (
    # Validate that primary and failover base addresses are different
    var.network_configuration.primary.vnet_address_space_base != var.network_configuration.failover.vnet_address_space_base &&
    # For /12 ranges, check that they don't overlap
    # Primary range: starts at primary_octet, covers 16 values (primary_octet to primary_octet+15)
    # Failover range: starts at failover_octet, covers 16 values (failover_octet to failover_octet+15)
    # No overlap if: primary_end < failover_start OR failover_end < primary_start
    (tonumber(split(".", var.network_configuration.primary.vnet_address_space_base)[1]) + 15 <
    tonumber(split(".", var.network_configuration.failover.vnet_address_space_base)[1])) ||
    (tonumber(split(".", var.network_configuration.failover.vnet_address_space_base)[1]) + 15 <
    tonumber(split(".", var.network_configuration.primary.vnet_address_space_base)[1]))
  )
}

# ============================================================================
# CONFIGURATION VALIDATION - Comprehensive Validation Checks
# ============================================================================

# WHY: Validate configuration consistency and catch errors early
# CONTEXT: Complex multi-environment, multi-subscription configuration needs validation
# IMPACT: Prevents deployment failures and configuration drift
locals {
  # Configuration validation checks
  configuration_validation = {
    # Remote state validation (from data.tf)
    remote_state_valid = local.remote_state_valid

    # Environment count validation
    environments_found = length(local.processed_environments) > 0

    # Subscription validation
    subscriptions_different = var.production_subscription_id != var.non_production_subscription_id

    # Network validation - updated for dynamic IP allocation
    primary_subnet_within_vnet  = local.base_address_capacity_valid
    failover_subnet_within_vnet = local.base_address_ranges_non_overlapping

    # Naming validation
    names_generated = length(local.environment_resource_names) > 0
  }

  # Overall validation status (separate to avoid self-reference)
  configuration_valid = alltrue([
    local.configuration_validation.remote_state_valid,
    local.configuration_validation.environments_found,
    local.configuration_validation.subscriptions_different,
    local.configuration_validation.primary_subnet_within_vnet,
    local.configuration_validation.failover_subnet_within_vnet,
    local.configuration_validation.names_generated
  ])

  # Validation error messages for debugging  
  validation_errors = [
    !local.configuration_validation.remote_state_valid ? "Remote state from ptn-environment-group is invalid or incomplete" : "",
    !local.configuration_validation.environments_found ? "No environments found in remote state" : "",
    !local.configuration_validation.subscriptions_different ? "Production and non-production subscriptions must be different" : "",
    !local.configuration_validation.primary_subnet_within_vnet ? "Base address spaces are too small (must be /12 or larger to support multiple environments)" : "",
    !local.configuration_validation.failover_subnet_within_vnet ? "Primary and failover base address spaces overlap (must use non-overlapping ranges)" : "",
    !local.configuration_validation.names_generated ? "Resource names could not be generated" : ""
  ]

  # Filter out empty error messages
  actual_validation_errors = [for err in local.validation_errors : err if err != ""]
}