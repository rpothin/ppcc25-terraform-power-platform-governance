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
