<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Group Pattern with Settings Management

This pattern creates a complete environment group setup with multiple environments and comprehensive environment settings management for demonstrating Power Platform governance through Infrastructure as Code. It orchestrates the creation of an environment group, multiple environments, and applies template-driven settings configuration that balances workspace-level defaults with environment-specific requirements.

## Key Features

- **Template-Driven**: Workspace templates (basic, simple, enterprise) with predefined environment configurations
- **Hybrid Settings Management**: Workspace-level defaults with environment-specific overrides
- **AVM Module Orchestration**: Uses res-environment-group, res-environment (with managed environment capabilities), res-environment-settings, and res-environment-application-admin modules
- **Multi-Resource Orchestration**: Coordinated deployment of environment groups, environments, and settings
- **Settings Governance**: Comprehensive audit, security, feature, and email configuration per environment
- **Template Flexibility**: Different templates support different organizational workflows

## Use Cases

This pattern is designed for organizations that need to:

1. **Governance at Scale**: Implement consistent governance policies across multiple environments through centralized environment group management with standardized settings
2. **Environment Lifecycle**: Demonstrate complete environment provisioning patterns with template-driven settings that vary by environment purpose (Dev/Test/Prod)
3. **Settings Standardization**: Apply workspace-level defaults while allowing environment-specific security, audit, and feature configurations
4. **Multi-Resource Orchestration**: Show how to coordinate multiple Power Platform resources with proper dependency management and settings application
5. **Development Team Organization**: Set up structured environment groups with appropriate settings for different environments in the development lifecycle
6. **Compliance Automation**: Automate the creation of governable environment structures with comprehensive audit and security settings
7. **Service Principal Integration**: Assign a monitoring service principal as an application admin to all environments for tenant-level governance.

## Pattern Components

- **Environment Group**: Central governance container for organizing environments
- **Template-Driven Environments**: Environments created based on workspace templates (basic: 3 envs, simple: 2 envs, enterprise: 4 envs)
- **Managed Environment**: Configuration of managed environment settings for enhanced governance.
- **Workspace Settings**: Global settings applied to all environments (features, email, security baseline)
- **Environment-Specific Settings**: Targeted settings that vary by environment purpose (audit levels, security restrictions, file limits)
- **Automatic Assignment**: Environments are automatically assigned to the group during creation
- **Settings Application**: Environment settings are applied after environment creation with proper dependency management
- **Application Admin Assignment**: Assigns the monitoring service principal as an application admin to each environment.
- **Dependency Management**: Proper orchestration ensures environment group → environments → managed environment → settings → application admin assignment deployment order

## Template-Driven Configuration

### Available Templates

- **basic**: Standard three-tier lifecycle (Dev, Test, Prod) with balanced settings
- **simple**: Minimal two-tier lifecycle (Dev, Prod) with conservative settings
- **enterprise**: Four-tier lifecycle (Dev, Staging, Test, Prod) with comprehensive security

### Settings Management Approach

1. **Workspace Settings**: Common configurations applied to all environments
   - Global feature enablement
   - Default email settings
   - Security baseline

2. **Environment-Specific Settings**: Overrides that vary by environment:
   - **Dev**: Full debugging, open access, larger file limits
   - **Test**: Balanced security, moderate auditing
   - **Prod**: Strict security, comprehensive auditing, compliance focus

## Usage with Template Selection

```hcl
# Template-driven configuration
workspace_template = "basic"
name               = "ProjectAlpha"
description        = "Project Alpha development workspace"
location           = "unitedstates"

# Results in:
# - ProjectAlpha - Environment Group
# - ProjectAlpha - Dev (Sandbox, full debugging, open access)
# - ProjectAlpha - Test (Sandbox, moderate security, balanced auditing)
# - ProjectAlpha - Prod (Production, strict security, comprehensive audit)
```

## Usage with GitHub Actions Workflows

```yaml
# GitHub Actions workflow input for template-driven deployment
inputs:
  configuration: 'ptn-environment-group'
  tfvars-file: 'basic-example.tfvars'  # Or simple-example.tfvars, enterprise-example.tfvars
# Example tfvars content:
# workspace_template = "enterprise"
# name               = "CriticalBusinessApp"
# description        = "Critical business application with full enterprise governance"
# location           = "unitedstates"
#
# Results in:
# - CriticalBusinessApp - Environment Group
# - CriticalBusinessApp - Dev (Sandbox, full debugging, comprehensive settings)
# - CriticalBusinessApp - Staging (Sandbox, pre-prod validation, controlled access)
# - CriticalBusinessApp - Test (Sandbox, UAT focused, moderate security)
# - CriticalBusinessApp - Prod (Production, maximum security, full compliance)
```

<!-- markdownlint-disable MD033 -->

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_null"></a> [null](#requirement\_null) (~> 3.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.13)

## Providers

The following providers are used by this module:

- <a name="provider_null"></a> [null](#provider\_null) (~> 3.0)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.13)

## Resources

The following resources are used by this module:

- [null_resource.managed_environment_deployment_control](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [time_sleep.environment_provisioning_buffer](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)

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

### <a name="output_environment_settings_summary"></a> [environment\_settings\_summary](#output\_environment\_settings\_summary)

Description: Comprehensive summary of environment settings applied by template configuration.

Shows how workspace-level defaults and environment-specific overrides were  
processed and applied to each environment. Useful for governance validation  
and compliance reporting.

### <a name="output_environment_suffixes"></a> [environment\_suffixes](#output\_environment\_suffixes)

Description: Map of environment name suffixes used by the template.

Shows the suffixes (e.g., " - Dev", " - Test", " - Prod") that were  
applied to the workspace name to generate environment names.

### <a name="output_environment_types"></a> [environment\_types](#output\_environment\_types)

Description: Map of environment types as defined by the template.

Shows the environment types (Sandbox, Production, Trial) for each  
environment as specified in the workspace template configuration.

### <a name="output_governance_ready_resources"></a> [governance\_ready\_resources](#output\_governance\_ready\_resources)

Description: Map of resources ready for governance configuration and policy application including environment settings

### <a name="output_managed_environment_deployment_status"></a> [managed\_environment\_deployment\_status](#output\_managed\_environment\_deployment\_status)

Description: Deployment status of the managed environment settings.

### <a name="output_orchestration_summary"></a> [orchestration\_summary](#output\_orchestration\_summary)

Description: Summary of template-driven pattern deployment status and results including environment settings

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this template-driven pattern module.

### <a name="output_pattern_configuration_summary"></a> [pattern\_configuration\_summary](#output\_pattern\_configuration\_summary)

Description: Comprehensive summary of template-driven pattern configuration

### <a name="output_settings_deployment_status"></a> [settings\_deployment\_status](#output\_settings\_deployment\_status)

Description: Deployment status and validation of environment settings modules.

Provides detailed information about the successful deployment of settings  
to each environment, including module references and configuration status.

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

## Modules

The following Modules are called:

### <a name="module_environment_application_admin"></a> [environment\_application\_admin](#module\_environment\_application\_admin)

Source: ../res-environment-application-admin

Version:

### <a name="module_environment_group"></a> [environment\_group](#module\_environment\_group)

Source: ../res-environment-group

Version:

### <a name="module_environment_settings"></a> [environment\_settings](#module\_environment\_settings)

Source: ../res-environment-settings

Version:

### <a name="module_environments"></a> [environments](#module\_environments)

Source: ../res-environment

Version:

### <a name="module_managed_environment"></a> [managed\_environment](#module\_managed\_environment)

Source: ../res-managed-environment

Version:

## Authentication

This pattern uses OIDC authentication for both the Power Platform provider and the Azure backend. Ensure the following environment variables are configured:

- `POWER_PLATFORM_CLIENT_ID`
- `POWER_PLATFORM_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### Service Principal Permission Requirements

This pattern creates multiple resources requiring comprehensive permissions:

**Recommended Setup:**
```bash
# Ensure service principal has permissions for all created environments
./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve
```

## Pattern Orchestration

The pattern implements the following orchestration sequence:

1. **Environment Group Creation**: Creates the central governance container
2. **Environment Provisioning**: Creates multiple environments with Dataverse enabled
3. **Automatic Group Assignment**: Environments are automatically assigned to the group
4. **Settings Application**: Environment-specific settings applied based on template
5. **Validation**: Confirms all resources are created and properly linked

### Template-Driven Deployment Patterns

**Basic Template (3 environments):**
- Development → Testing → Production lifecycle
- Balanced security and audit settings
- Standard compliance requirements

**Simple Template (2 environments):**
- Development → Production lifecycle
- Minimal overhead, faster deployment
- Cost-optimized for smaller projects

**Enterprise Template (4 environments):**
- Development → Staging → Testing → Production
- Maximum security and audit controls
- Comprehensive compliance automation

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
- [Power Platform Managed Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->