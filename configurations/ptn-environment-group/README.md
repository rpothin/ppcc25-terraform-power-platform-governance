<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Group Pattern

This pattern creates a complete environment group setup with multiple environments for demonstrating Power Platform governance through Infrastructure as Code. It orchestrates the creation of an environment group and multiple environments that are automatically assigned to the group.

## Use Cases

This pattern is designed for organizations that need to:

1. **Governance at Scale**: Implement consistent governance policies across multiple environments through centralized environment group management
2. **Environment Lifecycle**: Demonstrate complete environment provisioning patterns with automatic group assignment and policy inheritance
3. **Multi-Resource Orchestration**: Show how to coordinate multiple Power Platform resources with proper dependency management
4. **Development Team Organization**: Set up structured environment groups for different teams, projects, or application lifecycles
5. **Compliance Automation**: Automate the creation of governable environment structures that support audit and compliance requirements

## Pattern Components

- **Environment Group**: Central governance container for organizing environments
- **Multiple Environments**: Demonstration environments with Dataverse enabled for group membership
- **Automatic Assignment**: Environments are automatically assigned to the group during creation
- **Dependency Management**: Proper orchestration ensures environment group exists before environment creation

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'ptn-environment-group'
  tfvars-file: 'environment_group_config = {
    display_name = "Development Team Environment Group"
    description  = "Centralized group for development team environments with standardized governance"
  }
  environments = [
    {
      display_name     = "Development Environment"
      location         = "unitedstates"
      environment_type = "Sandbox"
      domain           = "dev-env"
    },
    {
      display_name     = "Testing Environment"
      location         = "unitedstates"
      environment_type = "Sandbox"
      domain           = "test-env"
    }
  ]'
```

<!-- markdownlint-disable MD033 -->

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_null"></a> [null](#requirement\_null) (~> 3.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_null"></a> [null](#provider\_null) (3.2.4)

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [null_resource.environment_duplicate_guardrail](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [powerplatform_environment.environments](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) (resource)
- [powerplatform_environment_group.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_group) (resource)
- [powerplatform_environments.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/environments) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_environment_group_config"></a> [environment\_group\_config](#input\_environment\_group\_config)

Description: Configuration for the Power Platform Environment Group creation.

This object defines the environment group that will serve as the container  
for organizing multiple environments with consistent governance policies.

Properties:
- display\_name: Human-readable name for the environment group (1-100 chars)
- description: Detailed description of the group purpose and scope (1-500 chars)

Example:  
environment\_group\_config = {  
  display\_name = "Development Environment Group"  
  description  = "Centralized group for all development environments with standardized governance policies"
}

Validation Rules:
- Display name must be unique within tenant and follow naming conventions
- Description should explain group purpose and governance approach
- Both fields are required and cannot be empty or whitespace-only

Type:

```hcl
object({
    display_name = string
    description  = string
  })
```

### <a name="input_environments"></a> [environments](#input\_environments)

Description: List of environments to create and assign to the environment group.

Each environment object represents a Power Platform environment that will be  
created and automatically assigned to the environment group for consistent  
governance and policy application.

Properties:
- display\_name: Human-readable name for the environment (required, 1-100 chars)
- location: Azure region for the environment (required, valid Azure region)
- environment\_type: Type of environment - "Sandbox", "Production", or "Trial" (required)
- dataverse\_language: Language code for Dataverse database (optional, default: "en")
- dataverse\_currency: Currency code for Dataverse database (optional, default: "USD")
- domain: Custom domain name for the environment (optional, auto-generated if not provided)

Example:  
environments = [
  {  
    display\_name     = "Development Environment"  
    location         = "unitedstates"  
    environment\_type = "Sandbox"  
    domain           = "dev-environment"
  },
  {  
    display\_name     = "Testing Environment"  
    location         = "unitedstates"  
    environment\_type = "Sandbox"  
    dataverse\_language = "en"  
    dataverse\_currency = "USD"
  }
]

Validation Rules:
- At least one environment must be provided for the pattern to be meaningful
- Display names must be unique across the tenant
- Environment types are restricted to supported values for service principal authentication
- Locations must be valid Power Platform geographic regions

Type:

```hcl
list(object({
    display_name       = string
    location           = string
    environment_type   = string
    dataverse_language = optional(string, "en")
    dataverse_currency = optional(string, "USD")
    domain             = optional(string)
  }))
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_duplicate_protection"></a> [enable\_duplicate\_protection](#input\_enable\_duplicate\_protection)

Description: Enable duplicate protection to prevent creation of environments with duplicate names.

This setting controls whether the pattern validates against existing environments  
to prevent naming conflicts. In production scenarios, this should typically be  
enabled to maintain environment naming consistency.

Default: true (recommended for production use)

Validation Rules:
- When true: Validates environment names against existing tenant environments
- When false: Allows potential duplicate names (useful for testing scenarios)
- Always validates that environments within the pattern have unique names

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_environment_group_id"></a> [environment\_group\_id](#output\_environment\_group\_id)

Description: The unique identifier of the created Power Platform Environment Group.

This output provides the primary key for referencing the environment group  
created by this pattern. Use this ID to:
- Configure additional governance policies targeting this group
- Reference the group in external configuration management systems
- Set up environment routing rules and rule sets
- Integrate with monitoring and compliance reporting systems

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)

### <a name="output_environment_group_name"></a> [environment\_group\_name](#output\_environment\_group\_name)

Description: The display name of the created environment group.

This output provides the human-readable name for validation and reporting purposes.  
Useful for:
- Confirming successful pattern deployment with expected naming
- Integration with external documentation and governance systems
- Validation in CI/CD pipelines and automated testing
- User-facing reports and operational dashboards

### <a name="output_environment_ids"></a> [environment\_ids](#output\_environment\_ids)

Description: Map of environment identifiers created by this pattern.

This output provides the unique identifiers for all environments created  
and assigned to the environment group. The map uses the array index as the  
key and the environment ID as the value.

Format: Map where each value is a GUID  
Usage: Reference specific environments by index for additional configuration

### <a name="output_environment_names"></a> [environment\_names](#output\_environment\_names)

Description: Map of environment display names created by this pattern.

This output provides the human-readable names for all environments  
created as part of this pattern, useful for validation and reporting.

Format: Map where each value is the environment display name  
Usage: Validation, reporting, and cross-reference with environment IDs

### <a name="output_governance_ready_resources"></a> [governance\_ready\_resources](#output\_governance\_ready\_resources)

Description: Map of resources ready for governance configuration and policy application

### <a name="output_orchestration_summary"></a> [orchestration\_summary](#output\_orchestration\_summary)

Description: Summary of pattern deployment status and multi-resource orchestration results

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this pattern module.

### <a name="output_pattern_configuration_summary"></a> [pattern\_configuration\_summary](#output\_pattern\_configuration\_summary)

Description: Comprehensive summary of pattern configuration for audit and compliance reporting

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
<!-- END_TF_DOCS -->