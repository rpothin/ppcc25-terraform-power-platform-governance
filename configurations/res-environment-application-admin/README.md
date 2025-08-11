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
  tfvars-file: 'environment_application_admin = {
  environment_id   = "12345678-1234-1234-1234-123456789012"
  application_id   = "87654321-4321-4321-4321-210987654321"
  security_role_id = "11111111-2222-3333-4444-555555555555"
}'
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

- [powerplatform_environment_application_admin.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_application_admin) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_environment_application_admin_config"></a> [environment\_application\_admin\_config](#input\_environment\_application\_admin\_config)

Description: Configuration object for environment application admin permission assignment.

This variable consolidates core settings for granting application admin permissions  
within a Power Platform environment, enabling programmatic access and management.

Properties:
- environment\_id: The unique identifier of the target Power Platform environment (GUID format)
- application\_id: The Azure AD application (client) ID that will receive admin permissions (GUID format)
- security\_role\_id: The Power Platform security role ID to assign (GUID format, typically System Administrator)

Example:  
environment\_application\_admin\_config = {  
  environment\_id   = "12345678-1234-1234-1234-123456789012"  
  application\_id   = "87654321-4321-4321-4321-210987654321"  
  security\_role\_id = "11111111-2222-3333-4444-555555555555"
}

Validation Rules:
- All IDs must be valid GUID format for Power Platform compatibility
- Environment must exist and be accessible by the service principal
- Application must be registered in Azure AD with Power Platform service principal
- Security role must exist within the target environment

Note: Lifecycle protection (prevent\_destroy) is always enabled for production safety.

Type:

```hcl
object({
    environment_id   = string
    application_id   = string
    security_role_id = string
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_application_id"></a> [application\_id](#output\_application\_id)

Description: The Azure AD application ID that received the admin permissions.

This output identifies which application was granted admin access,  
essential for security auditing and permission management workflows.

Format: GUID identifier of the Azure AD application  
Usage: Security audits and permission inventory reporting

### <a name="output_assignment_id"></a> [assignment\_id](#output\_assignment\_id)

Description: The unique identifier of the environment application admin assignment.

This output provides the primary key for referencing this permission assignment  
in other Terraform configurations or external systems. The ID can be used for  
dependency management and cross-configuration references.

Format: Resource-specific identifier from Power Platform  
Usage: Reference in downstream configurations requiring this assignment

### <a name="output_assignment_summary"></a> [assignment\_summary](#output\_assignment\_summary)

Description: Summary of the environment application admin assignment for validation and compliance reporting.

This consolidated output provides key assignment details in a structured format  
suitable for governance dashboards, audit reports, and operational monitoring.

Contents:
- assignment\_id: Unique identifier of the permission assignment
- environment\_id: Target environment identifier
- application\_id: Application that received permissions
- security\_role\_id: Assigned security role identifier
- resource\_type: Type of resource deployed (for reporting)
- deployment\_timestamp: When the assignment was created
- lifecycle\_protection: Whether prevent\_destroy is enabled

Usage: Governance reporting, audit trails, operational dashboards

### <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id)

Description: The Power Platform environment ID where the admin assignment was created.

This output confirms the target environment for the permission assignment,  
useful for validation and audit trails in multi-environment deployments.

Format: GUID identifier of the Power Platform environment  
Usage: Environment validation and cross-reference in governance reports

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