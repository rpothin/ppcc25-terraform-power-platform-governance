<!-- BEGIN_TF_DOCS -->
# Smart DLP tfvars Generator

This configuration automates the generation of tfvars files for DLP policy management by processing exported policy and connector data, supporting both new policy creation and onboarding of existing policies to IaC, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Onboard existing DLP policies to Terraform**: Converts exported DLP policy data into ready-to-use tfvars for infrastructure as code adoption.
2. **Generate new policy templates**: Creates tfvars files from governance templates (strict, balanced, development) for new DLP policies.
3. **Validate policy configuration completeness**: Ensures all required fields and connector classifications are present in generated tfvars.
4. **Integrate with automated workflows**: Enables GitHub Actions and CLI workflows to generate and validate tfvars as part of CI/CD.

## Usage with Data Export Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-generate-dlp-tfvars'
  terraform_variables: '-var="source_policy_name=Copilot Studio Autonomous Agents"'
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

No providers.

## Resources

No resources.

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_blocked_connectors"></a> [blocked\_connectors](#input\_blocked\_connectors)

Description: List of blocked connectors prohibited from use.

Blocked connectors represent high-risk services that are not permitted in the organization.  
These connectors will be completely blocked for users within the policy scope.

Used only in template mode for new policy creation. In onboarding mode,   
connector data is extracted from existing policy exports.

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

### <a name="input_business_connectors"></a> [business\_connectors](#input\_business\_connectors)

Description: List of business connectors for sensitive data (General classification).

Business connectors are typically used for corporate data and productivity scenarios.  
Each connector can have specific action rules and endpoint restrictions for granular control.

Used only in template mode for new policy creation. In onboarding mode,   
connector data is extracted from existing policy exports.

Example:  
business\_connectors = [
  {  
    id                           = "/providers/Microsoft.PowerApps/apis/shared\_sharepointonline"  
    default\_action\_rule\_behavior = "Allow"  
    action\_rules = [
      {  
        action\_id = "DeleteItem\_V2"  
        behavior  = "Block"
      }
    ]  
    endpoint\_rules = [
      {  
        endpoint = "contoso.sharepoint.com"  
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

Default: `[]`

### <a name="input_custom_connectors_patterns"></a> [custom\_connectors\_patterns](#input\_custom\_connectors\_patterns)

Description: Set of custom connector patterns for advanced DLP scenarios.

Each pattern must specify:
- order: Priority order for pattern evaluation (lower numbers evaluated first)
- host\_url\_pattern: URL pattern to match (supports wildcards)
- data\_group: Classification for matching connectors ("General", "Confidential", "Blocked")

Security Best Practice: Default blocks all custom connectors (*) unless explicitly allowed.

Example with specific allowances:  
custom\_connectors\_patterns = [
  {  
    order            = 1  
    host\_url\_pattern = "https://*.contoso.com"  
    data\_group       = "General"
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

This setting determines the fallback classification for connectors not explicitly  
configured in the business, non-business, or blocked connector lists.

Classification Meanings:
- General: Low-risk connectors suitable for business data
- Confidential: Medium-risk connectors requiring additional controls
- Blocked: High-risk connectors prohibited from use

Security Best Practice: Default to "Blocked" for security-first governance.

Type: `string`

Default: `"Blocked"`

### <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type)

Description: Environment scope for policy application ("AllEnvironments", "ExceptEnvironments", "OnlyEnvironments").

Environment Types:
- AllEnvironments: Apply policy to all environments in the tenant
- ExceptEnvironments: Apply policy to all environments except those specified in 'environments' list
- OnlyEnvironments: Apply policy only to environments specified in 'environments' list

Security Best Practice: Use "OnlyEnvironments" for targeted governance.

Type: `string`

Default: `"OnlyEnvironments"`

### <a name="input_environments"></a> [environments](#input\_environments)

Description: List of environment IDs to which the policy is applied.

- Required when environment\_type is "OnlyEnvironments" or "ExceptEnvironments"
- Leave empty when environment\_type is "AllEnvironments"
- Environment IDs must be valid GUIDs from Power Platform

Example: ["00000000-0000-0000-0000-000000000000", "11111111-1111-1111-1111-111111111111"]

Type: `list(string)`

Default: `[]`

### <a name="input_non_business_connectors"></a> [non\_business\_connectors](#input\_non\_business\_connectors)

Description: List of non-business connectors for non-sensitive data (Confidential classification).

Non-business connectors are typically used for external services or less sensitive scenarios.  
They require additional governance controls compared to business connectors.

Used only in template mode for new policy creation. In onboarding mode,   
connector data is extracted from existing policy exports.

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

### <a name="input_output_file"></a> [output\_file](#input\_output\_file)

Description: Path and filename for the generated tfvars output.

- Should end with .tfvars extension for Terraform compatibility
- Path is relative to the current working directory
- If not specified, defaults to "generated-dlp-policy.tfvars"

Example: "outputs/generated-policy.tfvars"

Type: `string`

Default: `"generated-dlp-policy.tfvars"`

### <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name)

Description: Name of the new DLP policy to generate tfvars for (used only when not onboarding from export).

If not specified, defaults to "New DLP Policy".

Example: "Production Security"

Type: `string`

Default: `null`

### <a name="input_source_policy_name"></a> [source\_policy\_name](#input\_source\_policy\_name)

Description: Name of the DLP policy to onboard and generate tfvars for.

- Used to select an existing policy from exported data (onboarding mode).
- If not specified, the generator will use template mode for new policy creation.
- Must match a policy name present in the exported JSON file if provided.

Example: "Copilot Studio Autonomous Agents"

Type: `string`

Default: `""`

### <a name="input_template_type"></a> [template\_type](#input\_template\_type)

Description: Type of tfvars template to generate for new policies.

- Options: "strict-security", "balanced", "development"
- Used when creating a new policy tfvars from a governance template.

Template Characteristics:
- strict-security: Most connectors classified as Confidential, minimal business connectors
- balanced: Common productivity connectors as General, others as Confidential
- development: Most connectors as General, only risky ones blocked

Example: "strict-security"

Type: `string`

Default: `"strict-security"`

## Outputs

The following outputs are exported:

### <a name="output_generated_tfvars_content"></a> [generated\_tfvars\_content](#output\_generated\_tfvars\_content)

Description: The generated tfvars content for the selected or templated DLP policy.

This output provides a ready-to-use tfvars block, suitable for direct use with the res-dlp-policy configuration. It is generated based on either onboarding an existing policy (from export) or creating a new policy from a governance template.

### <a name="output_generation_summary"></a> [generation\_summary](#output\_generation\_summary)

Description: Summary of the tfvars generation process, including input parameters, operational mode, and validation results.

This output provides operational context for the tfvars generation, including:
- The source policy name (if onboarding)
- The template type used (if template mode)
- The output file name
- Whether onboarding or template mode was used
- Validation status for generated tfvars
- Lists of business, non-business, and blocked connectors

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

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting discrete computed attributes instead of full resource objects
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Data Export and Analysis**: Provides reusable data sources without deploying resources

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal has Power Platform Service Admin role
- Confirm OIDC configuration in GitHub repository secrets
- Check tenant ID and client ID configuration

**Permission Errors**
- Ensure service principal is not blocked by conditional access policies
- Verify admin permissions for DLP policy and connector data export management
- Check for tenant-level restrictions on automation

- Ensure exported JSON files from `utl-export-dlp-policies` and `utl-export-connectors` are present and valid.
- Check for schema changes in export files if errors occur.

## Additional Links

- [Data Loss Prevention Policies (Power Platform)](https://learn.microsoft.com/power-platform/admin/wp-data-loss-prevention)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->