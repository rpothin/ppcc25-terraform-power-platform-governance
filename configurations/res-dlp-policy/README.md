<!-- BEGIN_TF_DOCS -->
# res-dlp-policy

This configuration deploys and manages a Power Platform Data Loss Prevention (DLP) policy following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Enforce strict data boundaries**: Prevent data exfiltration by classifying connectors and blocking risky actions.
2. **Automate DLP policy deployment**: Use Infrastructure as Code to standardize DLP policy rollout across environments.
3. **Support compliance initiatives**: Ensure consistent DLP enforcement for regulatory and internal compliance.
4. **Enable rapid policy updates**: Quickly adapt to new business or regulatory requirements with version-controlled policies.

## Connector ID Validation

This module validates that all provided business connector IDs exist in your Power Platform tenant. If you provide an invalid connector ID, Terraform will fail during the plan phase with a clear error message.

**To see available connectors:**

```bash
terraform plan -target=data.powerplatform_connectors.all
```

**Example error when using an invalid connector ID:**

```
Error: Invalid business connector IDs detected: /providers/Microsoft.PowerApps/apis/shared_invalid
To see available connectors, run:
  terraform plan -target=data.powerplatform_connectors.all
```

**Troubleshooting:**
- Use the `available_connectors` output to find valid connector IDs
- Connector IDs are case-sensitive and must match exactly
- Some connectors may not be available in all tenants

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-dlp-policy'
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [powerplatform_data_loss_prevention_policy.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/data_loss_prevention_policy) (resource)
- [powerplatform_connectors.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/connectors) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_business_connectors"></a> [business\_connectors](#input\_business\_connectors)

Description: List of business connectors for sensitive data. Each object must match the provider schema and allows full configuration of connector DLP rules.

Example:  
business\_connectors = [
  {  
    id                           = "/providers/Microsoft.PowerApps/apis/shared\_sql"  
    default\_action\_rule\_behavior = "Allow"  
    action\_rules = [
      {  
        action\_id = "DeleteItem\_V2"  
        behavior  = "Block"
      }
    ]  
    endpoint\_rules = [
      {  
        endpoint = "contoso.com"  
        behavior = "Allow"  
        order    = 1
      }
    ]
  }
]

Type:

```hcl
list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
```

### <a name="input_display_name"></a> [display\_name](#input\_display\_name)

Description: The display name of the DLP policy.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_blocked_connectors"></a> [blocked\_connectors](#input\_blocked\_connectors)

Description: Set of blocked connectors. Each object must match the provider schema and allows full configuration of connector DLP rules.

Example:  
blocked\_connectors = [
  {  
    id                           = "/providers/Microsoft.PowerApps/apis/shared\_dropbox"  
    default\_action\_rule\_behavior = "Block"  
    action\_rules                 = []  
    endpoint\_rules               = []
  }
]

Type:

```hcl
list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
```

Default: `[]`

### <a name="input_custom_connectors_patterns"></a> [custom\_connectors\_patterns](#input\_custom\_connectors\_patterns)

Description: Set of custom connector patterns for advanced DLP scenarios. Each pattern must specify order, host\_url\_pattern, and data\_group.

By default, blocks all custom connectors following security-first principles. Override this variable to allow specific URL patterns for approved custom connectors.

Example with specific allowances:  
custom\_connectors\_patterns = [
  {  
    order            = 1  
    host\_url\_pattern = "https://*.contoso.com"  
    data\_group       = "Business"
  },
  {  
    order            = 2  
    host\_url\_pattern = "*"  
    data\_group       = "Blocked"
  }
]

Type:

```hcl
list(object({
    order            = number
    host_url_pattern = string
    data_group       = string
  }))
```

Default:

```json
[
  {
    "data_group": "Blocked",
    "host_url_pattern": "*",
    "order": 1
  }
]
```

### <a name="input_default_connectors_classification"></a> [default\_connectors\_classification](#input\_default\_connectors\_classification)

Description: Default classification for connectors ("General", "Confidential", "Blocked").

Type: `string`

Default: `"Blocked"`

### <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type)

Description: Default environment handling for the policy ("AllEnvironments", "ExceptEnvironments", "OnlyEnvironments").

Type: `string`

Default: `"OnlyEnvironments"`

### <a name="input_environments"></a> [environments](#input\_environments)

Description: List of environment IDs to which the policy is applied. Leave empty for all environments.

Type: `list(string)`

Default: `[]`

### <a name="input_non_business_connectors"></a> [non\_business\_connectors](#input\_non\_business\_connectors)

Description: Set of non-business connectors for non-sensitive data. Each object must match the provider schema and allows full configuration of connector DLP rules.

Example:  
non\_business\_connectors = [
  {  
    id                           = "/providers/Microsoft.PowerApps/apis/shared\_twitter"  
    default\_action\_rule\_behavior = "Allow"  
    action\_rules                 = []  
    endpoint\_rules               = []
  }
]

Type:

```hcl
list(object({
    id                           = string
    default_action_rule_behavior = string
    action_rules = list(object({
      action_id = string
      behavior  = string
    }))
    endpoint_rules = list(object({
      endpoint = string
      behavior = string
      order    = number
    }))
  }))
```

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_dlp_policy_display_name"></a> [dlp\_policy\_display\_name](#output\_dlp\_policy\_display\_name)

Description: The display name of the DLP policy.

### <a name="output_dlp_policy_environment_type"></a> [dlp\_policy\_environment\_type](#output\_dlp\_policy\_environment\_type)

Description: The environment type for the DLP policy.

### <a name="output_dlp_policy_id"></a> [dlp\_policy\_id](#output\_dlp\_policy\_id)

Description: The unique identifier of the DLP policy.  
This output provides the primary key for referencing this resource in other Terraform configurations or external systems. The ID format follows Power Platform standards.

## Modules

No modules.

## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role
- **State Backend**: Azure Storage with OIDC authentication

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and is only accessible through your authenticated Terraform execution environment.

## ⚠️ AVM Compliance

### Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting resource IDs and computed attributes as discrete outputs
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Resource Deployment**: Deploys primary Power Platform resources following WAF best practices

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal has Power Platform Service Admin role
- Confirm OIDC configuration in GitHub repository secrets
- Check tenant ID and client ID configuration

**Permission Errors**
- Ensure service principal is not blocked by conditional access policies
- Verify admin permissions for DLP policy management
- Check for tenant-level restrictions on automation

If you encounter issues with DLP policy creation, ensure the target environment is supported and the connectors are classified correctly. Refer to the [official documentation](https://learn.microsoft.com/power-platform/admin/prevent-data-loss) for more troubleshooting tips.

## Additional Links

- [Data Loss Prevention Policy Resource](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/data_loss_prevention_policy)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->