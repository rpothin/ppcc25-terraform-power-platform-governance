<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Application Admin Configuration

This configuration automates the assignment of application admin permissions within Power Platform environments, enabling service principals and applications to manage environment resources programmatically while maintaining proper governance and security controls following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Automated Service Principal Permissions**: Grant Terraform service principals the necessary admin permissions for environment management and resource deployment automation without manual intervention
2. **Application Integration Security**: Securely assign application-specific admin roles to custom applications requiring environment-level access for integration scenarios
3. **Multi-Environment Governance**: Standardize permission assignments across development, staging, and production environments using consistent, auditable Infrastructure as Code practices
4. **Compliance and Audit Requirements**: Maintain comprehensive audit trails and compliance reporting for application admin permissions through version-controlled configuration management

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment-application-admin'
  tfvars-file: 'environment_id = "12345678-1234-1234-1234-123456789012"
application_id = "87654321-4321-4321-4321-210987654321"'
```

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) | ~> 3.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) | ~> 3.8 |

## Resources

| Name | Type |
|------|------|
| [powerplatform_environment_application_admin.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_application_admin) | resource |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_id"></a> [application\_id](#input\_application\_id) | The Azure AD application (client) ID that will receive admin permissions in the Power Platform environment.<br/><br/>This GUID identifies the Azure AD application registration that will be granted<br/>System Administrator privileges within the specified Power Platform environment.<br/>The application must be properly registered and configured for Power Platform access.<br/><br/>Format: GUID (e.g., '87654321-4321-4321-4321-210987654321')<br/>Usage: Application that will receive admin permissions<br/>Source: Azure AD App Registration or PowerShell cmdlets<br/><br/>Example:<br/>application\_id = "87654321-4321-4321-4321-210987654321"<br/><br/>Validation Rules:<br/>- Must be valid GUID format for Azure AD compatibility<br/>- Application must be registered in Azure AD<br/>- Application must have Power Platform service principal permissions<br/>- Application must not already have conflicting role assignments<br/><br/>Important: The System Administrator role is automatically assigned by Power Platform<br/>and provides full administrative access to the environment. This is required for<br/>Terraform service principals and automated environment management scenarios.<br/><br/>Note: Lifecycle protection (prevent\_destroy) is always enabled for production safety. | `string` | n/a | yes |
| <a name="input_environment_id"></a> [environment\_id](#input\_environment\_id) | The unique identifier of the target Power Platform environment where admin permissions will be assigned.<br/><br/>This GUID identifies the specific Power Platform environment that will receive the application<br/>admin assignment. The environment must exist and be accessible by the service principal<br/>executing the Terraform configuration.<br/><br/>Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')<br/>Usage: Target environment for application admin permission assignment<br/>Source: Power Platform Admin Center or PowerShell cmdlets<br/><br/>Example:<br/>environment\_id = "12345678-1234-1234-1234-123456789012"<br/><br/>Validation Rules:<br/>- Must be valid GUID format for Power Platform compatibility<br/>- Environment must exist and be accessible by the service principal<br/>- Environment must allow application user assignments<br/><br/>Note: The System Administrator role is automatically assigned by Power Platform<br/>and cannot be customized. This ensures the application has full administrative<br/>permissions required for environment management operations. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | The Azure AD application ID that received the admin permissions.<br/><br/>This output identifies which application was granted admin access,<br/>essential for security auditing and permission management workflows.<br/><br/>Format: GUID identifier of the Azure AD application<br/>Usage: Security audits and permission inventory reporting |
| <a name="output_assignment_id"></a> [assignment\_id](#output\_assignment\_id) | The unique identifier of the environment application admin assignment.<br/><br/>This output provides the primary key for referencing this permission assignment<br/>in other Terraform configurations or external systems. The ID can be used for<br/>dependency management and cross-configuration references.<br/><br/>Format: Resource-specific identifier from Power Platform<br/>Usage: Reference in downstream configurations requiring this assignment |
| <a name="output_assignment_summary"></a> [assignment\_summary](#output\_assignment\_summary) | Summary of the environment application admin assignment for validation and compliance reporting.<br/><br/>This consolidated output provides key assignment details in a structured format<br/>suitable for governance dashboards, audit reports, and operational monitoring.<br/><br/>Contents:<br/>- assignment\_id: Unique identifier of the permission assignment<br/>- environment\_id: Target environment identifier<br/>- application\_id: Application that received permissions<br/>- security\_role: Security role automatically assigned (System Administrator)<br/>- resource\_type: Type of resource deployed (for reporting)<br/>- deployment\_timestamp: When the assignment was created<br/>- lifecycle\_protection: Whether prevent\_destroy is enabled<br/><br/>Usage: Governance reporting, audit trails, operational dashboards |
| <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id) | The Power Platform environment ID where the admin assignment was created.<br/><br/>This output confirms the target environment for the permission assignment,<br/>useful for validation and audit trails in multi-environment deployments.<br/><br/>Format: GUID identifier of the Power Platform environment<br/>Usage: Environment validation and cross-reference in governance reports |

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

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting resource IDs and computed attributes as discrete outputs
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
- Verify admin permissions for environment application admin assignment management
- Check for tenant-level restrictions on automation

**Permission Assignment Failures**
- Verify target environment exists and is accessible
- Confirm application ID is valid and registered in tenant
- Check security role ID exists in target environment
- Ensure service principal has Power Platform Service Admin permissions

**Application Not Found Errors**
- Validate application registration in Azure AD
- Confirm application has Power Platform service principal
- Check application permissions and consent status

## Additional Links

- [Power Platform Environment Application Admin Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_application_admin)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->