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

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting environment IDs and computed attributes as discrete outputs
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
- Verify admin permissions for environment creation and management
- Check for tenant-level restrictions on automation

**Environment Creation Failures**
- Verify the target region is supported for Power Platform environments
- Check Dataverse database requirements and capacity limits  
- Ensure unique environment names within the tenant
- Confirm sufficient Power Platform licensing for environment type

**Duplicate Environment Issues**
- Use duplicate detection feature to identify existing environments with same name
- Consider importing existing environments: `terraform import powerplatform_environment.this {environment-id}`
- Review environment naming conventions to avoid conflicts

## Additional Links

- [Power Platform Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)