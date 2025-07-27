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

The following input variables are optional (have default values):

### <a name="input_filter_publishers"></a> [filter\_publishers](#input\_filter\_publishers)

Description: Optional list of connector publishers to include in the export. If set, only connectors whose publisher matches one of the provided values will be included.

Example:  
  filter\_publishers = ["Microsoft", "Troy Taylor"]

Validation:
- Each publisher must be a non-empty string.
- If empty or unset, no filtering by publisher is applied.

Type: `list(string)`

Default: `[]`

### <a name="input_filter_tiers"></a> [filter\_tiers](#input\_filter\_tiers)

Description: Optional list of connector tiers to include in the export. Valid values are "Standard" and "Premium". If set, only connectors whose tier matches one of the provided values will be included.

Example:  
  filter\_tiers = ["Standard", "Premium"]

Validation:
- Each tier must be either "Standard" or "Premium" (case-sensitive).
- If empty or unset, no filtering by tier is applied.

Type: `list(string)`

Default: `[]`

### <a name="input_filter_types"></a> [filter\_types](#input\_filter\_types)

Description: Optional list of connector types to include in the export. If set, only connectors whose type matches one of the provided values will be included.

Example:  
  filter\_types = ["Custom", "BuiltIn"]

Validation:
- Each type must be a non-empty string.
- If empty or unset, no filtering by type is applied.

Type: `list(string)`

Default: `[]`

### <a name="input_page_number"></a> [page\_number](#input\_page\_number)

Description: Optional page number for paginating connector results. Ignored if page\_size is 0. First page is 1.

Example:  
  page\_number = 1

Validation:
- Must be >= 1 if page\_size > 0

Type: `number`

Default: `1`

### <a name="input_page_size"></a> [page\_size](#input\_page\_size)

Description: Optional page size for paginating connector results. If set to 0 or unset, all filtered connectors are returned. For very large tenants, set to a reasonable value (e.g., 100) to limit output size.

Example:  
  page\_size = 100

Validation:
- Must be >= 0
- If 0, pagination is disabled (all results returned)

Type: `number`

Default: `0`

## Outputs

The following outputs are exported:

### <a name="output_connector_ids"></a> [connector\_ids](#output\_connector\_ids)

Description: List of all connector IDs in the tenant, after applying any filter criteria.  
Useful for downstream automation, reporting, and governance.

### <a name="output_connector_metrics"></a> [connector\_metrics](#output\_connector\_metrics)

Description: Performance metrics for connector export operation.  
Provides total, filtered, and paged counts for capacity planning and performance monitoring.

### <a name="output_connectors_by_publisher"></a> [connectors\_by\_publisher](#output\_connectors\_by\_publisher)

Description: Mapping of publisher name to list of connectors for that publisher (after filtering).  
Enables publisher-specific governance policies and risk assessment.

### <a name="output_connectors_csv"></a> [connectors\_csv](#output\_connectors\_csv)

Description: Paged connectors as a CSV string for integration with external tools.  
Tabular format for spreadsheet analysis and legacy governance systems.

### <a name="output_connectors_detailed"></a> [connectors\_detailed](#output\_connectors\_detailed)

Description: Comprehensive metadata for all connectors in the tenant, after applying any filter criteria.  
Includes certification status, capabilities, API information, and more (if available in provider schema).  
Performance note: For large tenants, this output may be large and impact plan/apply performance.

### <a name="output_connectors_json"></a> [connectors\_json](#output\_connectors\_json)

Description: Paged connectors as a JSON string for integration with external tools.  
Structured format for consumption by governance automation and reporting systems.

### <a name="output_connectors_summary"></a> [connectors\_summary](#output\_connectors\_summary)

Description: Summary of all connectors with key metadata for governance and reporting, after applying any filter criteria.

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this module.

### <a name="output_paged_connector_ids"></a> [paged\_connector\_ids](#output\_paged\_connector\_ids)

Description: List of connector IDs after filtering and pagination.  
Use for incremental processing or large tenant scenarios where full dataset would impact performance.

### <a name="output_paged_connectors_detailed"></a> [paged\_connectors\_detailed](#output\_paged\_connectors\_detailed)

Description: Comprehensive metadata for paged connectors after filtering and pagination.  
Use when detailed analysis is needed for subset of connectors in large tenants.

### <a name="output_paged_connectors_summary"></a> [paged\_connectors\_summary](#output\_paged\_connectors\_summary)

Description: Summary of paged connectors with key metadata after filtering and pagination.  
Optimized for scenarios requiring batch processing of large connector inventories.

### <a name="output_publishers_present"></a> [publishers\_present](#output\_publishers\_present)

Description: Set of publishers present in the filtered connector set.  
Useful for governance analysis and publisher-based policy decisions.

### <a name="output_tiers_present"></a> [tiers\_present](#output\_tiers\_present)

Description: Set of tiers present in the filtered connector set.  
Helps identify licensing implications and governance requirements.

### <a name="output_types_present"></a> [types\_present](#output\_types\_present)

Description: Set of types present in the filtered connector set.  
Supports classification and governance rule application.

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

## Known Limitations

- **Provider Schema Dependency**: Some advanced metadata fields may return null
- **Performance**: Large tenants (1000+ connectors) may impact performance
- **Filter Constraints**: Case-sensitive exact matching only

## Performance Recommendations

- For tenants with >500 connectors, consider using pagination
- Use filtering to reduce dataset size when possible
- Monitor plan/apply times for very large exports

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