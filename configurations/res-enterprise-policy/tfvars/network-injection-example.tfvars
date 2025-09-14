# Network Injection Enterprise Policy Configuration Example
# This example configures an enterprise policy for Azure VNet integration with Power Platform environments

# WHY: Network injection policies enable secure connectivity between Power Platform and Azure resources
# This configuration allows Power Platform environments to access resources in specific Azure VNets
# while maintaining network isolation and compliance with corporate security policies

policy_configuration = {
  # Policy identification and location
  name              = "ep-powerplatform-vnet-integration"
  location          = "europe" # Must match Power Platform tenant region
  policy_type       = "NetworkInjection"
  resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-powerplatform-governance"

  # Network injection configuration
  # Configure VNet(s) and subnet(s) where Power Platform environments can be injected
  network_injection_config = {
    virtual_networks = [
      {
        # Primary VNet for Power Platform workloads
        id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-networking/providers/Microsoft.Network/virtualNetworks/vnet-powerplatform-prod"
        subnet = {
          name = "snet-powerplatform-environments" # Subnet must have Microsoft.PowerPlatform/environments delegation
        }
      },
      {
        # Secondary VNet for development/testing environments
        id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-networking/providers/Microsoft.Network/virtualNetworks/vnet-powerplatform-dev"
        subnet = {
          name = "snet-powerplatform-dev"
        }
      }
    ]
  }

  # Note: encryption_config is not used for NetworkInjection policies
}

# Common tags for governance, compliance, and cost management
common_tags = {
  project         = "PPCC25-Governance"
  environment     = "production"
  cost_center     = "IT-Infrastructure"
  owner           = "powerplatform-team"
  managed_by      = "Terraform"
  compliance      = "Required"
  backup_required = "false" # Enterprise policies are configuration, not data

  # Power Platform specific tags
  pp_region       = "europe"
  policy_type     = "NetworkInjection"
  governance_tier = "enterprise"
}

# Example usage in parent module:
# module "enterprise_policy_vnet" {
#   source = "./configurations/res-enterprise-policy"
#   
#   policy_configuration = var.policy_configuration
#   common_tags         = var.common_tags
# }
#
# # Link to Power Platform environments
# resource "powerplatform_enterprise_policy" "vnet_integration" {
#   location             = var.policy_configuration.location
#   enterprise_policy_id = module.enterprise_policy_vnet.enterprise_policy_system_id
# }