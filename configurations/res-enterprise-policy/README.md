<!-- BEGIN_TF_DOCS -->
# res-enterprise-policy

This module deploys Microsoft.PowerPlatform/enterprisePolicies resources using the Azure API provider (azapi). Enterprise policies enable advanced Power Platform governance capabilities including Azure VNet integration and customer-managed key encryption.

## Key Features

- **Network Injection Support**: Configure VNet integration for secure Power Platform connectivity
- **Customer-Managed Encryption**: Deploy encryption policies using Azure Key Vault keys
- **AVM Compliance**: Child module design compatible with meta-arguments (for\_each, count)
- **Comprehensive Validation**: Strong typing with extensive input validation
- **Anti-Corruption Layer**: Clean outputs that abstract azapi implementation details
- **Lifecycle Management**: Production-ready resource lifecycle and timeout configuration

## Policy Types

### NetworkInjection
Enables Azure VNet integration for Power Platform environments, allowing secure connectivity to Azure resources while maintaining network isolation.

### Encryption
Configures customer-managed key encryption for Power Platform data, providing enhanced security control over data encryption keys.

## Prerequisites

- Azure subscription with PowerPlatform resource provider registered
- For NetworkInjection: Azure VNet with Microsoft.PowerPlatform/environments subnet delegation
- For Encryption: Azure Key Vault with encryption keys and appropriate RBAC permissions
- azapi Terraform provider ~> 2.6

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.6)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.6)

## Resources

The following resources are used by this module:

- [azapi_resource.enterprise_policy](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_policy_configuration"></a> [policy\_configuration](#input\_policy\_configuration)

Description: Enterprise policy configuration for Power Platform governance.

This consolidated object defines all aspects of enterprise policy deployment  
including policy type, location, and type-specific settings.

Policy Types:
- NetworkInjection: Configures VNet integration for Power Platform environments
- Encryption: Configures customer-managed keys for data encryption

Example - Network Injection:  
policy\_configuration = {  
  name          = "ep-vnet-integration-policy"  
  location      = "europe"  
  policy\_type   = "NetworkInjection"  
  resource\_group\_id = "/subscriptions/.../resourceGroups/rg-governance"  

  network\_injection\_config = {  
    virtual\_networks = [{  
      id = "/subscriptions/.../virtualNetworks/vnet-powerplatform"  
      subnet = { name = "snet-powerplatform" }
    }]
  }
}

Example - Encryption:  
policy\_configuration = {  
  name          = "ep-encryption-policy"  
  location      = "europe"  
  policy\_type   = "Encryption"  
  resource\_group\_id = "/subscriptions/.../resourceGroups/rg-governance"  

  encryption\_config = {  
    key\_vault = {  
      id = "/subscriptions/.../vaults/kv-powerplatform"  
      key = {  
        name = "powerplatform-key"  
        version = "latest"
      }
    }  
    state = "Enabled"
  }
}

Type:

```hcl
object({
    name              = string
    location          = string
    policy_type       = string
    resource_group_id = string

    # Network injection configuration (required when policy_type = "NetworkInjection")
    network_injection_config = optional(object({
      virtual_networks = list(object({
        id = string
        subnet = object({
          name = string
        })
      }))
    }))

    # Encryption configuration (required when policy_type = "Encryption")  
    encryption_config = optional(object({
      key_vault = object({
        id = string
        key = object({
          name    = string
          version = string
        })
      })
      state = string
    }))
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags)

Description: Common tags to apply to the enterprise policy resource for governance and cost management.

These tags are applied at the Azure resource level and help with:
- Cost allocation and tracking across projects
- Resource organization and governance
- Compliance and audit requirements

Example:  
common\_tags = {  
  project     = "PPCC25-Governance"  
  environment = "production"  
  cost\_center = "IT-Infrastructure"  
  owner       = "powerplatform-team"  
  managed\_by  = "Terraform"
}

Tag Requirements:
- Keys and values must be alphanumeric with allowed special characters
- Maximum 50 tag pairs per resource (Azure limitation)
- Key length: 1-512 characters, Value length: 0-256 characters

Type: `map(string)`

Default:

```json
{
  "managed_by": "Terraform",
  "project": "PPCC25-Governance"
}
```

## Outputs

The following outputs are exported:

### <a name="output_enterprise_policy_id"></a> [enterprise\_policy\_id](#output\_enterprise\_policy\_id)

Description: The Azure resource ID of the deployed enterprise policy.

This ID uniquely identifies the enterprise policy within Azure Resource Manager  
and can be used for:
- Azure RBAC permissions and access control
- Resource dependency management in other Terraform configurations
- Azure Resource Graph queries and compliance reporting

Format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PowerPlatform/enterprisePolicies/{policyName}

### <a name="output_enterprise_policy_system_id"></a> [enterprise\_policy\_system\_id](#output\_enterprise\_policy\_system\_id)

Description: The Power Platform system ID for the enterprise policy.

This system ID is critical for linking the policy to Power Platform environments  
via the powerplatform\_enterprise\_policy resource. The system ID is generated  
automatically by Power Platform and represents the policy within the Power Platform  
control plane (separate from Azure Resource Manager).

Format: /regions/{location}/providers/Microsoft.PowerPlatform/enterprisePolicies/{guid}

Usage in powerplatform\_enterprise\_policy:
```hcl
resource "powerplatform_enterprise_policy" "example" {
  location              = "europe"
  enterprise_policy_id  = module.res_enterprise_policy.enterprise_policy_system_id
  # ... other configuration
}
```

### <a name="output_managed_identity_principal_id"></a> [managed\_identity\_principal\_id](#output\_managed\_identity\_principal\_id)

Description: The principal ID of the system-assigned managed identity for the enterprise policy.

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

### <a name="output_policy_deployment_summary"></a> [policy\_deployment\_summary](#output\_policy\_deployment\_summary)

Description: Comprehensive summary of enterprise policy deployment for operational visibility.

This output aggregates all critical information about the deployed enterprise policy  
including configuration details, resource identifiers, and deployment metadata.  
Use this output for:
- Operational dashboards and monitoring
- Integration with external systems
- Audit trails and compliance reporting
- Troubleshooting and support scenarios

The summary adapts based on policy type (NetworkInjection vs Encryption) to provide  
relevant configuration details without exposing sensitive information.

### <a name="output_policy_location"></a> [policy\_location](#output\_policy\_location)

Description: The Power Platform region where the enterprise policy is deployed.

This location must match the target Power Platform environments that will  
be governed by this policy. The location affects:
- Data residency and compliance requirements
- Network latency for policy enforcement
- Available features and API versions

### <a name="output_policy_ready_for_linking"></a> [policy\_ready\_for\_linking](#output\_policy\_ready\_for\_linking)

Description: Boolean indicator of whether the policy is ready for linking to environments.

This computed value checks the provisioning state and other readiness indicators  
to determine if the enterprise policy can be safely linked to Power Platform  
environments. Use this in conditional logic:

```hcl
resource "powerplatform_enterprise_policy" "link" {
  count = module.res_enterprise_policy.policy_ready_for_linking ? 1 : 0
  # ... configuration
}
```

## Modules

No modules.

## Usage Examples

### Network Injection Policy

```hcl
module "vnet_integration_policy" {
  source = "./configurations/res-enterprise-policy"

  policy_configuration = {
    name              = "ep-vnet-integration"
    location          = "europe"
    policy_type       = "NetworkInjection"
    resource_group_id = azurerm_resource_group.governance.id

    network_injection_config = {
      virtual_networks = [{
        id     = azurerm_virtual_network.powerplatform.id
        subnet = { name = "snet-powerplatform" }
      }]
    }
  }

  common_tags = {
    environment = "production"
    project     = "powerplatform-governance"
  }
}
```

### Encryption Policy

```hcl
module "encryption_policy" {
  source = "./configurations/res-enterprise-policy"

  policy_configuration = {
    name              = "ep-encryption"
    location          = "europe"
    policy_type       = "Encryption"
    resource_group_id = azurerm_resource_group.governance.id

    encryption_config = {
      key_vault = {
        id = azurerm_key_vault.powerplatform.id
        key = {
          name    = "powerplatform-key"
          version = "latest"
        }
      }
      state = "Enabled"
    }
  }

  common_tags = {
    environment = "production"
    project     = "powerplatform-governance"
  }
}
```

## Integration with Power Platform

After deploying the enterprise policy, link it to Power Platform environments:

```hcl
resource "powerplatform_enterprise_policy" "link" {
  location             = module.enterprise_policy.policy_location
  enterprise_policy_id = module.enterprise_policy.enterprise_policy_system_id
}
```

## Security Considerations

- Enterprise policies automatically create system-assigned managed identities
- For encryption policies, grant managed identity access to Key Vault (Key Vault Crypto Officer role)
- For network injection, ensure appropriate network security group rules
- Review and validate policy configuration before deployment to production environments
<!-- END_TF_DOCS -->