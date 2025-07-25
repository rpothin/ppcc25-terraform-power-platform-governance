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
