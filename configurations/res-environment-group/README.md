<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Group Configuration

This configuration creates and manages Power Platform Environment Groups for organizing environments with consistent governance policies following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Environment Organization**: Group related environments (dev, test, prod) into logical units for streamlined administration and consistent policy application across the environment lifecycle
2. **Governance at Scale**: Apply standardized rules and policies to multiple environments simultaneously, reducing manual configuration overhead and ensuring compliance across large Power Platform estates
3. **Environment Routing**: Configure automatic routing of new developer environments to specific environment groups, ensuring consistent governance from environment creation
4. **Lifecycle Management**: Organize environments by function, project, or business unit to support structured application lifecycle management and controlled deployment patterns

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment-group'
  tfvars-file: 'environment_group_config = {
    display_name = "Development Environment Group"
    description  = "Group for all development environments"
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

- [powerplatform_environment_group.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_group) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_description"></a> [description](#input\_description)

Description: Detailed description of the environment group purpose and scope.

This description provides context about what environments belong to this group,  
what governance policies apply, and how it fits into the organization's Power  
Platform strategy.

Example: "Centralized group for all development environments with standardized governance policies"

Validation Rules:
- Must be 1-500 characters to provide meaningful context
- Cannot be empty or contain only whitespace characters  
- Should explain the group's purpose and governance approach

Type: `string`

### <a name="input_display_name"></a> [display\_name](#input\_display\_name)

Description: Human-readable name for the Power Platform Environment Group.

This name appears in the Power Platform admin center and is used for identification  
and management purposes. It should clearly indicate the purpose and scope of the  
environment group.

Example: "Development Environment Group"

Validation Rules:
- Must be 1-100 characters for Power Platform compatibility  
- Cannot be empty or contain only whitespace characters
- Should be descriptive and follow organizational naming conventions

Type: `string`

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_environment_group_id"></a> [environment\_group\_id](#output\_environment\_group\_id)

Description: The unique identifier of the created Power Platform Environment Group.

This output provides the primary key for referencing this environment group  
in other Terraform configurations or external systems. Use this ID to:
- Configure environment routing settings in tenant configuration
- Reference the group in environment creation resources
- Integrate with environment group rule set configurations
- Set up governance policies that target this specific group

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)

### <a name="output_environment_group_name"></a> [environment\_group\_name](#output\_environment\_group\_name)

Description: The display name of the created environment group.

This output provides the human-readable name for validation and reporting purposes.  
Useful for:
- Confirming successful deployment with expected naming
- Integration with external documentation systems
- Validation in CI/CD pipelines
- User-facing reports and dashboards

### <a name="output_environment_group_summary"></a> [environment\_group\_summary](#output\_environment\_group\_summary)

Description: Summary of deployed environment group configuration for validation and compliance reporting

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this module.

## Modules

No modules.

## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role
- **State Backend**: Azure Storage with OIDC authentication

### Service Principal Permission Requirements

For comprehensive environment group management, ensure the service principal has appropriate permissions. While environment group creation requires Service Admin role, downstream environment management may require additional permissions:

**Optional Script for Multi-Environment Workflows:**
```bash
# If using with environment creation workflows
./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve
```

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
- Verify admin permissions for environment group management
- Check for tenant-level restrictions on automation

**Environment Group Creation Failures**
- Ensure display name is unique within the tenant
- Verify description meets character limit requirements  
- Confirm proper authentication scope for Power Platform resources
- Check for existing environment groups with similar names

## Additional Links

- [Environment Groups Documentation](https://learn.microsoft.com/en-us/power-platform/admin/environment-groups)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->