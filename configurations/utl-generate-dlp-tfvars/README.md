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

The following input variables are required:

### <a name="input_source_policy_name"></a> [source\_policy\_name](#input\_source\_policy\_name)

Description: Name of the DLP policy to onboard or generate tfvars for.

- Used to select an existing policy from exported data.
- Must match a policy name present in the exported JSON file.

Example: "Copilot Studio Autonomous Agents"

Type: `string`

### <a name="input_template_type"></a> [template\_type](#input\_template\_type)

Description: Type of tfvars template to generate for new policies.

- Options: "strict-security", "balanced", "development"
- Used when creating a new policy tfvars from a governance template.

Example: "strict-security"

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_output_file"></a> [output\_file](#input\_output\_file)

Description: Path and filename for the generated tfvars output.

- Should end with .tfvars
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

## Outputs

The following outputs are exported:

### <a name="output_generated_tfvars_content"></a> [generated\_tfvars\_content](#output\_generated\_tfvars\_content)

Description: The generated tfvars content for the selected or templated DLP policy.

### <a name="output_generation_summary"></a> [generation\_summary](#output\_generation\_summary)

Description: Summary of the tfvars generation process, including input parameters and validation results.

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