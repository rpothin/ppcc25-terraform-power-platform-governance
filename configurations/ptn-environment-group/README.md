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

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

No providers.

## Modules

The following Modules are called:

### <a name="module_environment_group"></a> [environment\_group](#module\_environment\_group)

Source: ../res-environment-group

Version:

### <a name="module_environments"></a> [environments](#module\_environments)

Source: ../res-environment

Version:

## Resources

No resources.

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_description"></a> [description](#input\_description)

Description: Description of the workspace and its purpose.

This description will be used for the environment group and provides  
context for the workspace's governance and business purpose.

Example:  
description = "Project workspace for customer portal development"

Validation Rules:
- Must be 1-200 characters
- Cannot be empty or contain only whitespace
- Should describe business purpose and governance approach

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Power Platform geographic region for all environments in this workspace.

All environments created by the template will be deployed to this region.  
The location must be supported by the selected workspace template.

Example:  
location = "unitedstates"

Supported locations:
- unitedstates, europe, asia, australia, unitedkingdom, india
- canada, southamerica, france, unitedarabemirates, southafrica
- germany, switzerland, norway, korea, japan

Validation Rules:
- Must be a valid Power Platform geographic region
- Will be validated against template-specific allowed locations
- Cannot be changed after workspace creation without recreation

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: Workspace name used as the base for all environment names.

This name will be combined with environment suffixes defined in the  
selected workspace template to create individual environment names.

Example:  
name = "MyProject"

With "basic" template, this creates:
- "MyProject - Dev"
- "MyProject - Test"
- "MyProject - Prod"

Validation Rules:
- Must be 1-50 characters to allow for suffixes
- Cannot be empty or contain only whitespace
- Should follow organizational naming conventions

Type: `string`

### <a name="input_workspace_template"></a> [workspace\_template](#input\_workspace\_template)

Description: Workspace template that defines the environments to create.

Predefined templates provide standardized environment configurations  
for different use cases and governance requirements.

Available templates:
- "basic": Creates Dev, Test, and Prod environments
- "simple": Creates Dev and Prod environments only  
- "enterprise": Creates Dev, Staging, Test, and Prod environments

Example:  
workspace\_template = "basic"

Validation Rules:
- Must be one of the supported template names
- Template definitions are managed in locals.tf
- Each template includes environment types and naming conventions

Type: `string`

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_environment_group_id"></a> [environment\_group\_id](#output\_environment\_group\_id)

Description: The unique identifier of the created Power Platform Environment Group.

This output provides the primary key for referencing the environment group  
created by this template-driven pattern. Use this ID to:
- Configure additional governance policies targeting this group
- Reference the group in external configuration management systems
- Set up environment routing rules and rule sets
- Integrate with monitoring and compliance reporting systems

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)

### <a name="output_environment_group_name"></a> [environment\_group\_name](#output\_environment\_group\_name)

Description: The display name of the created environment group.

Generated from workspace name with " - Environment Group" suffix.  
Useful for validation, reporting, and cross-reference with environment IDs.

### <a name="output_environment_ids"></a> [environment\_ids](#output\_environment\_ids)

Description: Map of environment identifiers created by the template.

Provides unique identifiers for all environments created based on the  
selected workspace template. Map keys correspond to template environment  
indices, values are the Power Platform environment GUIDs.

Usage: Reference specific environments for additional configuration

### <a name="output_environment_names"></a> [environment\_names](#output\_environment\_names)

Description: Map of environment display names generated by the template.

Shows the actual environment names created by combining the workspace  
name with template-defined suffixes (e.g., " - Dev", " - Test", " - Prod").

### <a name="output_environment_suffixes"></a> [environment\_suffixes](#output\_environment\_suffixes)

Description: Map of environment name suffixes used by the template.

Shows the suffixes (e.g., " - Dev", " - Test", " - Prod") that were  
applied to the workspace name to generate environment names.

### <a name="output_environment_types"></a> [environment\_types](#output\_environment\_types)

Description: Map of environment types as defined by the template.

Shows the environment types (Sandbox, Production, Trial) for each  
environment as specified in the workspace template configuration.

### <a name="output_governance_ready_resources"></a> [governance\_ready\_resources](#output\_governance\_ready\_resources)

Description: Map of resources ready for governance configuration and policy application

### <a name="output_orchestration_summary"></a> [orchestration\_summary](#output\_orchestration\_summary)

Description: Summary of template-driven pattern deployment status and results

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this template-driven pattern module.

### <a name="output_pattern_configuration_summary"></a> [pattern\_configuration\_summary](#output\_pattern\_configuration\_summary)

Description: Comprehensive summary of template-driven pattern configuration

### <a name="output_template_metadata"></a> [template\_metadata](#output\_template\_metadata)

Description: Metadata about the workspace template and its configuration

### <a name="output_workspace_name"></a> [workspace\_name](#output\_workspace\_name)

Description: The workspace name used as the base for environment naming.

This is the user-provided workspace name that gets combined with  
template-defined suffixes to create individual environment names.

### <a name="output_workspace_template"></a> [workspace\_template](#output\_workspace\_template)

Description: The workspace template used for this deployment.

Indicates which predefined template was used to create the environment  
structure. Available templates: basic, simple, enterprise.

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