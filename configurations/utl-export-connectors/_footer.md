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