## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role
- **State Backend**: Azure Storage with OIDC authentication

### Service Principal Permission Requirements

The service principal used for testing requires:
- **Power Platform Service Admin**: For environment and managed environment management
- **Azure AD Group Member**: Must be member of or owner of the security group specified in `security_group_id`
- **Environment Creator**: Permission to create sandbox environments in the target location

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and is only accessible through your authenticated Terraform execution environment.

## ⚠️ AVM Compliance

### Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`). 

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by providing discrete test result outputs and resource identifiers
- **Security-First**: Sensitive data properly marked and segregated in outputs 
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Testing and Validation**: Provides testing utilities for validating deployment patterns and provider behavior

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal has Power Platform Service Admin role
- Confirm OIDC configuration in GitHub repository secrets
- Check tenant ID and client ID configuration

**Permission Errors** 
- Ensure service principal is not blocked by conditional access policies
- Verify admin permissions for test environment and managed environment management
- Check for tenant-level restrictions on automation

**Sequential Deployment Errors**
- If "Request url must be an absolute url" error occurs, increase environment_wait_duration
- Check environment_id output for empty or malformed values
- Verify res-environment and res-managed-environment modules are up to date

**Test Execution Issues**
- Ensure test_name is unique to avoid conflicts with existing resources
- Use different security_group_id if permission issues occur
- Enable comprehensive_logging for detailed debugging information

### Debugging Sequential Deployment Issues

1. **Check Environment Readiness**: Verify environment_id is populated before managed environment creation
2. **Timing Adjustments**: Increase environment_wait_duration if timing-related errors occur
3. **Module Compatibility**: Ensure both res-environment and res-managed-environment modules are latest versions
4. **Dependency Validation**: Review validation_checkpoints output to identify which phase failed

## Additional Links

- [Power Platform Managed Environment Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)