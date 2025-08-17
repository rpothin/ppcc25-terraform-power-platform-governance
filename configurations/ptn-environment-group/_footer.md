## Authentication

This pattern uses OIDC authentication for both the Power Platform provider and the Azure backend. Ensure the following environment variables are configured:

- `POWER_PLATFORM_CLIENT_ID`
- `POWER_PLATFORM_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## Pattern Orchestration

The pattern implements the following orchestration sequence:

1. **Environment Group Creation**: Creates the central governance container
2. **Environment Provisioning**: Creates multiple environments with Dataverse enabled
3. **Automatic Group Assignment**: Environments are automatically assigned to the group
4. **Validation**: Confirms all resources are created and properly linked

## Data Collection

This pattern requires access to existing environments for duplicate protection validation (when enabled). The pattern queries:

- Existing Power Platform environments (for duplicate name detection)
- Environment group assignment validation

## ⚠️ AVM Compliance

### Provider Exception

This pattern uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting resource IDs and computed attributes as discrete outputs
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Pattern Deployment**: Orchestrates multiple Power Platform resources following WAF best practices
- **Multi-Resource Coordination**: Demonstrates proper dependency management and resource orchestration

## Troubleshooting

### Common Issues

1. **Environment Group Assignment Failures**
   - Ensure Dataverse is enabled for all environments
   - Verify environment group exists before environment creation
   - Check that service principal has appropriate permissions

2. **Duplicate Name Detection**
   - Enable duplicate protection to avoid naming conflicts
   - Ensure environment names are unique across the tenant
   - Use descriptive naming conventions for clarity

3. **Authentication Issues**
   - Verify OIDC configuration is correct
   - Ensure service principal has Power Platform permissions
   - Check Azure AD app registration settings

4. **Provider Limitations**
   - Developer environments are not supported with service principal authentication
   - Environment group assignment requires Dataverse configuration
   - Some environment settings may require manual configuration

## Additional Links

- [Power Platform Environment Group Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_group)
- [Power Platform Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)