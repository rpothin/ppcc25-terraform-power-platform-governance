<!-- BEGIN_TF_DOCS -->
# Power Platform DLP Policies Export Configuration

This configuration provides a standardized way to export Data Loss Prevention (DLP) policies from Microsoft Power Platform for analysis and migration planning. It demonstrates how to create single-purpose Terraform configurations that target specific data sources while following Azure Verified Module (AVM) best practices.

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
  configuration: 'utl-export-dlp-policies'
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

- [powerplatform_data_loss_prevention_policies.current](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/data_loss_prevention_policies) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_policy_filter"></a> [policy\_filter](#input\_policy\_filter)

Description: (Optional) List of DLP policy display names to export. If set, only policies whose display names match any value in this list will be exported.  
Filtering is case-sensitive and matches exact display names. Improves performance for large tenants.  
Example:  
	policy\_filter = ["Corporate DLP", "Finance DLP"]

Type: `list(string)`

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_dlp_policies"></a> [dlp\_policies](#output\_dlp\_policies)

Description: DLP policies structured for migration analysis with complete configuration data.  
Each policy includes all necessary information to recreate via IaC without regressions.  

Structure:
- policy\_count: Total number of DLP policies exported (after filtering)
- policies: Array of policy objects with complete configuration
  - Basic metadata (id, display\_name, environment\_type, environments)
  - Connector classifications (business, non\_business, blocked)
  - Custom connector patterns for migration accuracy
  - Summary counts for quick analysis

### <a name="output_dlp_policies_detailed_rules"></a> [dlp\_policies\_detailed\_rules](#output\_dlp\_policies\_detailed\_rules)

Description: Detailed connector action and endpoint rules for DLP policies.  

This output includes complete rule configurations which may contain:
- Specific action IDs and their allow/block behaviors
- Endpoint URLs and access patterns
- Custom rule configurations  

Use this data for:
- Complete policy recreation with exact rule preservation
- Advanced migration scenarios requiring granular rule control
- Compliance auditing of specific connector behaviors  

Note: Marked as sensitive due to potential exposure of internal endpoints and detailed security configurations.

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this module. Consumers should check this value for compatibility.

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

- **Anti-Corruption Layer**: Implements TFFR2 compliance by exposing discrete attributes instead of complete resource objects
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Single Purpose**: Focused data source configuration for DLP policy export

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
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->