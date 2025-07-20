<!-- BEGIN_TF_DOCS -->
# Power Platform DLP Policies Export Configuration

This configuration provides a standardized way to export Data Loss Prevention (DLP) policies from Microsoft Power Platform for analysis and migration planning. It demonstrates how to create single-purpose Terraform configurations that target specific data sources while following Azure Verified Module (AVM) best practices.

## ⚠️ AVM Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Compliance Status**: 85% (Provider Exception Documented)  
**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

## Key Features

- **Anti-Corruption Layer**: Implements TFFR2 compliance by exposing discrete attributes instead of complete resource objects
- **Security-First**: Sensitive data properly marked and segregated in outputs  
- **Migration Ready**: Structured output designed for Infrastructure as Code migration scenarios
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Single Purpose**: Focused data source configuration for DLP policy export

## Use Cases

This configuration is designed for organizations that need to:

1. **Policy Inventory**: Understand current DLP policy landscape across Power Platform environments
2. **Migration Planning**: Export existing policies for Infrastructure as Code adoption
3. **Compliance Documentation**: Generate structured policy documentation for auditing
4. **Configuration Analysis**: Compare manual vs. IaC-managed policies for consistency

## Usage with Terraform Output Workflow

```yaml
# GitHub Actions workflow input
inputs:
  configuration: '01-dlp-policies'
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

## Providers

No providers.

## Resources

No resources.

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_test_input"></a> [test\_input](#input\_test\_input)

Description: Test input variable

Type: `string`

Default: `"default_value"`

## Outputs

The following outputs are exported:

### <a name="output_test_computed_values"></a> [test\_computed\_values](#output\_test\_computed\_values)

Description: Computed values for testing

### <a name="output_test_input_variable"></a> [test\_input\_variable](#output\_test\_input\_variable)

Description: The value of the test input variable

### <a name="output_test_message"></a> [test\_message](#output\_test\_message)

Description: A simple test message

### <a name="output_test_number"></a> [test\_number](#output\_test\_number)

Description: A simple test number

## Modules

No modules.

## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role
- **State Backend**: Azure Storage with OIDC authentication

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and is only accessible through your authenticated Terraform execution environment.

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

**Large Dataset Timeouts**
- Large tenants with many policies may experience longer query times
- Consider filtering strategies if performance issues occur

## Additional Links

- [Power Platform DLP Documentation](https://learn.microsoft.com/power-platform/admin/prevent-data-loss)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Compliance Documentation](../../docs/explanations/power-platform-provider-exception.md)
<!-- END_TF_DOCS -->