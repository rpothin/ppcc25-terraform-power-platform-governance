<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Configuration

This configuration creates and manages Power Platform environments following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Environment Standardization**: Deploy consistent Power Platform environments with standardized naming, regions, and security settings across development, staging, and production
2. **Lifecycle Management**: Onboard existing environments to Infrastructure as Code management while preventing accidental deletion through lifecycle protection
3. **Governance Compliance**: Ensure environments meet organizational standards with validated configuration parameters and security-first defaults
4. **Multi-Environment Deployment**: Support scalable environment provisioning across multiple tenants and regions with environment-specific configurations

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment'
  tfvars-file: 'production'  # Uses tfvars/production.tfvars
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_null"></a> [null](#requirement\_null) (~> 3.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_null"></a> [null](#provider\_null) (~> 3.0)

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [null_resource.environment_duplicate_guardrail](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [powerplatform_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) (resource)
- [powerplatform_environments.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/environments) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_environment_config"></a> [environment\_config](#input\_environment\_config)

Description: Comprehensive configuration object for Power Platform environment.

This variable consolidates core environment settings to reduce complexity while  
ensuring all requirements are validated at plan time.

Properties:
- display\_name: Human-readable name for the environment (3-64 chars, alphanumeric with spaces/hyphens/underscores)
- location: Azure region where the environment will be created (e.g., "unitedstates", "europe", "asia")
- environment\_type: Type of environment determining capabilities ("Sandbox", "Production", "Trial", "Developer")

Example:  
environment\_config = {  
  display\_name     = "Development Environment"  
  location         = "unitedstates"  
  environment\_type = "Sandbox"
}

Validation Rules:
- Display name must be unique within tenant and follow organizational standards
- Location must be supported by Power Platform for environment creation
- Environment type determines available features and capacity limits

Type:

```hcl
object({
    display_name     = string
    location         = string
    environment_type = string
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_dataverse_config"></a> [dataverse\_config](#input\_dataverse\_config)

Description: Optional Dataverse database configuration for the environment.

When provided, creates a Dataverse database with the specified settings.  
Leave as null to create an environment without Dataverse.

Properties:
- language\_code: LCID code for the default language (e.g., "1033" for English US)
- currency\_code: ISO currency code for the default currency (e.g., "USD", "EUR", "GBP")
- security\_group\_id: Optional Azure AD security group ID for database access control
- domain: Optional custom domain name for the Dataverse instance (auto-generated if not provided)
- organization\_name: Optional organization name for the Dataverse instance (defaults to display\_name if not provided)

Example:  
dataverse\_config = {  
  language\_code     = "1033"  # English (United States)  
  currency\_code     = "USD"   # US Dollar  
  security\_group\_id = "12345678-1234-1234-1234-123456789012"  
  domain            = "contoso-dev"  
  organization\_name = "Contoso Development"
}

Set to null to create environment without Dataverse:  
dataverse\_config = null

Validation Rules:
- Language code must be valid LCID (see Microsoft documentation)
- Currency code must be supported by Power Platform  
- Security group ID must be valid Azure AD object ID format if provided
- Domain must be unique within tenant and follow naming conventions

Type:

```hcl
object({
    language_code     = string
    currency_code     = string
    security_group_id = optional(string)
    domain            = optional(string)
    organization_name = optional(string)
  })
```

Default: `null`

### <a name="input_enable_duplicate_protection"></a> [enable\_duplicate\_protection](#input\_enable\_duplicate\_protection)

Description: Enable duplicate environment detection and prevention.

When true, the module will query existing environments and fail the plan if a duplicate   
is detected (same display\_name). This is recommended for production to prevent  
accidental environment duplication.

Set to false to disable duplicate detection during environment import processes  
or when creating environments with potentially conflicting names.

Default: true (recommended for production)

Usage scenarios:
- Production deployments: true (prevent duplicates)
- Environment import: false (temporarily during import process)
- Development/testing: true (maintain consistency)

Type: `bool`

Default: `true`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Optional tags to apply to the environment for organization and cost tracking.

Note: Power Platform environments have limited native tagging support compared  
to Azure resources. These tags are primarily used for Terraform state organization  
and may be used by governance processes.

Example:  
tags = {  
  Environment = "Production"  
  Department  = "Finance"  
  CostCenter  = "CC-12345"  
  Owner       = "finance-team@contoso.com"
}

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_dataverse_configuration"></a> [dataverse\_configuration](#output\_dataverse\_configuration)

Description: Dataverse database configuration details when enabled, null otherwise

### <a name="output_dataverse_organization_url"></a> [dataverse\_organization\_url](#output\_dataverse\_organization\_url)

Description: The organization URL for the Dataverse database, if enabled.

Returns the base URL for Dataverse API access and application integrations.  
Will be null if Dataverse is not configured for this environment.

### <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id)

Description: The unique identifier of the Power Platform environment.

This output provides the primary key for referencing this environment  
in other Terraform configurations, DLP policies, or external systems.  
The ID is stable across environment updates and safe for external consumption.

### <a name="output_environment_summary"></a> [environment\_summary](#output\_environment\_summary)

Description: Summary of deployed environment configuration for validation and compliance reporting

### <a name="output_environment_url"></a> [environment\_url](#output\_environment\_url)

Description: The web URL for accessing the Power Platform environment.

This URL can be used for:
- Direct admin center access
- Power Apps maker portal links
- Power Automate environment access
- API endpoint construction

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
<!-- END_TF_DOCS -->