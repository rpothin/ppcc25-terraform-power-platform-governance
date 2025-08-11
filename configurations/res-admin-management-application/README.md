<!-- BEGIN_TF_DOCS -->
# Power Platform Admin Management Application

This configuration registers and manages service principals as Power Platform administrators for tenant governance following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Centralized Tenant Governance**: Register service principals for automated Power Platform administration and governance operations
2. **Service Principal Management**: Manage the lifecycle of admin service principals with proper registration and deregistration
3. **OIDC Authentication Setup**: Configure service principals for secure OIDC-based authentication in CI/CD pipelines
4. **Compliance and Audit**: Maintain auditable records of service principal registrations for governance compliance

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-admin-management-application'
  tfvars-file: 'prod.tfvars'
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [powerplatform_admin_management_application.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/admin_management_application) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_client_id"></a> [client\_id](#input\_client\_id)

Description: Service principal client ID (Application ID) to register as Power Platform administrator.

This variable specifies the Azure AD service principal that will be granted   
Power Platform administrator privileges for tenant governance operations.

The client ID must be:
- A valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
- An existing service principal in the Azure AD tenant
- Accessible to the current authentication context
- Not already registered as a Power Platform administrator (unless importing)

Example:  
client\_id = "12345678-1234-1234-1234-123456789012"

Validation Rules:
- Must be a valid UUID format for Azure AD compatibility
- Required field - cannot be empty or null
- Used as the primary identifier for the admin registration resource

Security Considerations:
- This value is not sensitive but should be managed through secure configuration
- Service principal should follow principle of least privilege
- Consider using dedicated service principals for governance automation

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_validation"></a> [enable\_validation](#input\_enable\_validation)

Description: Enable additional validation checks for service principal registration.

When enabled, this variable activates supplementary validation to ensure:
- Client ID format is valid UUID
- Service principal accessibility verification
- Registration prerequisite validation

Set to false to disable validation checks (not recommended for production).

Example:  
enable\_validation = true

Validation Rules:
- Must be a boolean value (true/false)
- Defaults to true for production safety
- Can be temporarily disabled for troubleshooting or import scenarios

Operational Impact:
- When true: Provides early detection of configuration issues
- When false: Skips validation but may result in deployment failures
- Recommended: Keep enabled except for specific troubleshooting scenarios

Type: `bool`

Default: `true`

### <a name="input_timeout_configuration"></a> [timeout\_configuration](#input\_timeout\_configuration)

Description: Timeout configuration for Power Platform admin management operations.

This variable configures operation timeouts to handle varying response times  
for Power Platform admin registration operations across different tenants.

Properties:
- create: Timeout for creating admin registration (default: "5m")
- delete: Timeout for removing admin registration (default: "5m")  
- read: Timeout for reading admin registration status (default: "2m")

Example:  
timeout\_configuration = {  
  create = "10m"  # Extended timeout for large tenants  
  delete = "5m"   # Standard timeout for deregistration  
  read   = "2m"   # Quick timeout for status checks
}

Validation Rules:
- All timeout values must be valid Go duration strings
- Minimum recommended: 1m for create/delete, 30s for read
- Maximum recommended: 30m for any operation
- Format: "1m", "2h30m", "45s" etc.

Operational Considerations:
- Larger tenants may require longer timeouts
- Network latency affects operation duration
- Power Platform service throttling may extend operation time

Type:

```hcl
object({
    create = optional(string, "5m")
    delete = optional(string, "5m")
    read   = optional(string, "2m")
  })
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_configuration_summary"></a> [configuration\_summary](#output\_configuration\_summary)

Description: Summary of deployed admin registration configuration for validation and compliance reporting.

This output provides a comprehensive overview of the admin registration  
deployment, including key configuration details, operational status,  
and metadata for governance and audit purposes.

The summary includes:
- Client ID of the registered service principal
- Resource type and classification information
- Deployment timestamp and validation status
- Configuration parameters used during deployment

This information supports compliance reporting, operational validation,  
and integration with downstream automation systems.

### <a name="output_registration_id"></a> [registration\_id](#output\_registration\_id)

Description: The client ID of the registered service principal.

This output provides the primary identifier for the Power Platform admin  
registration, which can be used for referencing this registration in other  
Terraform configurations or external systems.

The value represents the same client ID that was provided as input,  
confirming successful registration as a Power Platform administrator.

### <a name="output_registration_status"></a> [registration\_status](#output\_registration\_status)

Description: Status information about the admin registration operation.

This output provides operational details about the registration process,  
including confirmation that the service principal is successfully registered  
as a Power Platform administrator.

Value indicates successful completion of the registration process.

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

- **Anti-Corruption Layer**: Implements TFFR2 compliance by discrete service principal registration details and status information
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
- Verify admin permissions for Global Administrator or Power Platform Administrator role for service principal registration management
- Check for tenant-level restrictions on automation

**Service Principal Registration Issues**
- Verify client ID format is valid UUID
- Ensure service principal exists in the tenant
- Check that the service principal is not already registered as admin
- Confirm authentication has sufficient permissions for admin management

## Additional Links

- [powerplatform\_admin\_management\_application Resource](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/admin_management_application)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->