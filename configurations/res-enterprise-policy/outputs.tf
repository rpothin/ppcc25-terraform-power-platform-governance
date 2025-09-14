# Enterprise Policy Outputs Configuration
#
# This file implements the anti-corruption layer pattern from AVM guidelines,
# providing clean, discrete outputs that abstract the underlying azapi implementation.
#
# Output Design Principles:
# - Anti-Corruption Layer: No direct exposure of azapi resource objects
# - Discrete Values: Specific, useful outputs for downstream consumption
# - Comprehensive Descriptions: HEREDOC documentation with usage examples
# - Integration-Ready: Outputs designed for Power Platform environment linking
# - Operational Visibility: Deployment summaries for monitoring and troubleshooting
#
# Key Outputs:
# - enterprise_policy_id: Azure Resource Manager ID for RBAC and governance
# - enterprise_policy_system_id: Power Platform system ID for environment linking
# - policy_deployment_summary: Comprehensive operational metadata
# - managed_identity_principal_id: For Azure RBAC assignments
#
# Integration Pattern:
# These outputs are specifically designed for use with powerplatform_enterprise_policy
# resources to link policies to Power Platform environments while maintaining
# clean separation between Azure resource management and Power Platform governance.

# Anti-corruption layer outputs following AVM patterns
# WHY: These outputs provide clean, discrete access to enterprise policy information
# without exposing internal azapi resource structure or Azure-specific details

output "enterprise_policy_id" {
  description = <<DESCRIPTION
The Azure resource ID of the deployed enterprise policy.

This ID uniquely identifies the enterprise policy within Azure Resource Manager
and can be used for:
- Azure RBAC permissions and access control
- Resource dependency management in other Terraform configurations
- Azure Resource Graph queries and compliance reporting

Format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PowerPlatform/enterprisePolicies/{policyName}
DESCRIPTION
  value       = azapi_resource.enterprise_policy.id
}

output "enterprise_policy_system_id" {
  description = <<DESCRIPTION
The Power Platform system ID for the enterprise policy.

This system ID is critical for linking the policy to Power Platform environments
via the powerplatform_enterprise_policy resource. The system ID is generated
automatically by Power Platform and represents the policy within the Power Platform
control plane (separate from Azure Resource Manager).

Format: /regions/{location}/providers/Microsoft.PowerPlatform/enterprisePolicies/{guid}

Usage in powerplatform_enterprise_policy:
```hcl
resource "powerplatform_enterprise_policy" "example" {
  location              = "europe"
  enterprise_policy_id  = module.res_enterprise_policy.enterprise_policy_system_id
  # ... other configuration
}
```
DESCRIPTION
  value       = azapi_resource.enterprise_policy.output.properties.systemId
}

output "policy_deployment_summary" {
  description = <<DESCRIPTION
Comprehensive summary of enterprise policy deployment for operational visibility.

This output aggregates all critical information about the deployed enterprise policy
including configuration details, resource identifiers, and deployment metadata.
Use this output for:
- Operational dashboards and monitoring
- Integration with external systems
- Audit trails and compliance reporting
- Troubleshooting and support scenarios

The summary adapts based on policy type (NetworkInjection vs Encryption) to provide
relevant configuration details without exposing sensitive information.
DESCRIPTION
  value = {
    # Core policy information
    policy_name     = var.policy_configuration.name
    policy_type     = var.policy_configuration.policy_type
    policy_location = var.policy_configuration.location

    # Azure resource details  
    azure_resource_id = azapi_resource.enterprise_policy.id
    resource_group_id = var.policy_configuration.resource_group_id

    # Power Platform integration details
    system_id = azapi_resource.enterprise_policy.output.properties.systemId

    # Managed identity information
    managed_identity_principal_id = azapi_resource.enterprise_policy.identity[0].principal_id
    managed_identity_tenant_id    = azapi_resource.enterprise_policy.identity[0].tenant_id

    # Configuration-specific details (dynamically populated)
    configuration_details = local.configuration_summary

    # Deployment metadata
    deployment_metadata = local.policy_metadata

    # Resource state information
    provisioning_state = azapi_resource.enterprise_policy.output.properties.provisioningState
    health_status      = try(azapi_resource.enterprise_policy.output.properties.healthStatus, "Unknown")
  }
}

# Additional discrete outputs for specific integration scenarios
output "managed_identity_principal_id" {
  description = <<DESCRIPTION
The principal ID of the system-assigned managed identity for the enterprise policy.

This principal ID is required for granting the enterprise policy's managed identity
access to Azure resources such as:
- Key Vault for encryption policy scenarios
- Virtual Network for network injection scenarios  
- Storage accounts for audit logging

Use this output to configure Azure RBAC assignments:
```hcl
resource "azurerm_role_assignment" "policy_key_vault_access" {
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = module.res_enterprise_policy.managed_identity_principal_id
}
```
DESCRIPTION
  value       = azapi_resource.enterprise_policy.identity[0].principal_id
}

output "policy_location" {
  description = <<DESCRIPTION
The Power Platform region where the enterprise policy is deployed.

This location must match the target Power Platform environments that will
be governed by this policy. The location affects:
- Data residency and compliance requirements
- Network latency for policy enforcement
- Available features and API versions
DESCRIPTION
  value       = var.policy_configuration.location
}

output "policy_ready_for_linking" {
  description = <<DESCRIPTION
Boolean indicator of whether the policy is ready for linking to environments.

This computed value checks the provisioning state and other readiness indicators
to determine if the enterprise policy can be safely linked to Power Platform
environments. Use this in conditional logic:

```hcl
resource "powerplatform_enterprise_policy" "link" {
  count = module.res_enterprise_policy.policy_ready_for_linking ? 1 : 0
  # ... configuration
}
```
DESCRIPTION
  value       = azapi_resource.enterprise_policy.output.properties.provisioningState == "Succeeded"
}