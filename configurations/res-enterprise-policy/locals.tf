# Enterprise Policy Local Values Configuration
#
# This file contains complex transformation logic for enterprise policy configuration,
# implementing dynamic policy body generation based on policy type.
#
# Local Value Functions:
# - Dynamic Configuration: Type-specific property injection for azapi body
# - Metadata Generation: Consistent deployment metadata across policy types
# - Configuration Summarization: Type-safe access to policy details for outputs
# - Conditional Logic: NetworkInjection vs Encryption property handling
#
# Architecture Decisions:
# - Single Configuration Object: Unified policy body regardless of type
# - Conditional Merging: Type-specific properties only when relevant
# - Computed Values: Consistent metadata generation for operational visibility
# - Anti-Corruption Support: Clean data structures for output consumption
#
# WHY: Separate complex logic from main.tf to maintain readability
# Following baseline principle of modularity over long complex files

locals {
  # WHY: Dynamic policy configuration based on type
  # This ensures only relevant properties are included in the azapi request
  # and provides clear separation between NetworkInjection and Encryption policies
  policy_body_configuration = {
    kind = var.policy_configuration.policy_type
    properties = merge(
      # Base properties always included
      {
        displayName = var.policy_configuration.name
        description = "Enterprise policy for Power Platform governance - managed by Terraform"
      },

      # Network injection properties (conditional)
      var.policy_configuration.policy_type == "NetworkInjection" ? {
        networkInjection = {
          virtualNetworks = [
            for vnet in var.policy_configuration.network_injection_config.virtual_networks : {
              id     = vnet.id
              subnet = vnet.subnet
            }
          ]
        }
      } : {},

      # Encryption properties (conditional) 
      var.policy_configuration.policy_type == "Encryption" ? {
        encryption = {
          keyVault = var.policy_configuration.encryption_config.key_vault
          state    = var.policy_configuration.encryption_config.state
        }
      } : {}
    )
  }

  # WHY: Computed values for outputs and lifecycle management
  # These locals help maintain consistency across outputs and reduce duplication
  policy_metadata = {
    deployment_timestamp = timestamp()
    terraform_managed    = true
    ready_for_linking    = true
    policy_family        = "PowerPlatform.EnterprisePolicy"
  }

  # WHY: Configuration-specific summary for comprehensive reporting
  # Provides type-safe access to configuration details in outputs
  configuration_summary = var.policy_configuration.policy_type == "NetworkInjection" ? {
    type                   = "NetworkInjection"
    virtual_networks_count = length(var.policy_configuration.network_injection_config.virtual_networks)
    virtual_network_ids = [
      for vnet in var.policy_configuration.network_injection_config.virtual_networks : vnet.id
    ]
    subnet_names = [
      for vnet in var.policy_configuration.network_injection_config.virtual_networks : vnet.subnet.name
    ]
    } : {
    type             = "Encryption"
    key_vault_id     = var.policy_configuration.encryption_config.key_vault.id
    key_name         = var.policy_configuration.encryption_config.key_vault.key.name
    key_version      = var.policy_configuration.encryption_config.key_vault.key.version
    encryption_state = var.policy_configuration.encryption_config.state
  }
}