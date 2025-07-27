<!-- BEGIN_TF_DOCS -->
# Export Power Platform Connectors Utility

This configuration exports a comprehensive list of connectors from your Power Platform tenant, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Inventory All Connectors**: Generate an up-to-date inventory of all standard and custom connectors available in the tenant.
2. **Support Governance Audits**: Provide evidence for compliance and governance reviews by exporting connector metadata.
3. **Enable DLP Policy Planning**: Supply input data for Data Loss Prevention (DLP) policy design and enforcement.
4. **Facilitate Integration Analysis**: Help architects and developers analyze available integration options for Power Platform solutions.

## Usage with Data Export Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-export-connectors'
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

- [powerplatform_connectors.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/connectors) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_connector_ids"></a> [connector\_ids](#output\_connector\_ids)

Description: List of all connector IDs in the tenant.  
Useful for downstream automation, reporting, and governance.

### <a name="output_connectors_detailed"></a> [connectors\_detailed](#output\_connectors\_detailed)

Description: Comprehensive metadata for all connectors in the tenant, including all available properties from the provider.  
Includes certification status, capabilities, API information, and more (if available in provider schema).  
Performance note: For large tenants, this output may be large and impact plan/apply performance.

### <a name="output_connectors_summary"></a> [connectors\_summary](#output\_connectors\_summary)

Description: Summary of all connectors with key metadata for governance and reporting.

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
- Verify admin permissions for connector inventory management
- Check for tenant-level restrictions on automation

If you encounter empty results, ensure your account has access to all connectors and that the Power Platform API is not restricted by tenant policies.

## Additional Links

- [Connector reference overview](https://learn.microsoft.com/en-us/connectors/connector-reference/)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->