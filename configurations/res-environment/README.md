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

### <a name="input_environment"></a> [environment](#input\_environment)

Description: Power Platform environment configuration using ONLY real provider arguments.

This variable includes exclusively the arguments that actually exist in the   
microsoft/power-platform provider to ensure 100% compatibility.

Required Properties:
- display\_name: Human-readable environment name
- location: Power Platform region (e.g., "unitedstates", "europe")
- environment\_type: Environment classification (Sandbox, Production, Trial, Developer)

Optional Properties:
- owner\_id: Entra ID user GUID (REQUIRED for Developer environments)
- description: Environment description
- azure\_region: Specific Azure region (westeurope, eastus, etc.)
- cadence: Update cadence ("Frequent" or "Moderate")
- allow\_bing\_search: Enable Bing search in the environment
- allow\_moving\_data\_across\_regions: Allow data movement across regions
- billing\_policy\_id: GUID for pay-as-you-go billing policy
- environment\_group\_id: GUID for environment group membership
- release\_cycle: Early release participation

Examples:

# Production Environment  
environment = {  
  display\_name                     = "Production Finance Environment"  
  location                        = "unitedstates"  
  environment\_type               = "Production"  
  description                    = "Production environment for Finance applications"  
  azure\_region                   = "eastus"  
  cadence                        = "Moderate"  
  allow\_bing\_search              = false  
  allow\_moving\_data\_across\_regions = false
}

# Developer Environment (owner\_id required)  
environment = {  
  display\_name     = "John's Development Environment"  
  location         = "unitedstates"  
  environment\_type = "Developer"  
  owner\_id         = "12345678-1234-1234-1234-123456789012"  
  cadence          = "Frequent"
}

Type:

```hcl
object({
    # Required Arguments - ✅ REAL
    display_name     = string
    location         = string
    environment_type = string

    # Optional Arguments - ✅ REAL
    owner_id                         = optional(string)
    description                      = optional(string)
    azure_region                     = optional(string)
    cadence                          = optional(string) # "Frequent" or "Moderate" only
    allow_bing_search                = optional(bool)
    allow_moving_data_across_regions = optional(bool)
    billing_policy_id                = optional(string)
    environment_group_id             = optional(string)
    release_cycle                    = optional(string)
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_dataverse"></a> [dataverse](#input\_dataverse)

Description: Dataverse database configuration using ONLY real provider arguments.

Required Properties:
- language\_code: LCID integer (e.g., 1033 for English US) - NOTE: NUMBER not string!
- currency\_code: ISO currency code string (e.g., "USD", "EUR", "GBP")

Optional Properties:
- security\_group\_id: Azure AD security group GUID
- domain: Custom domain name for the Dataverse instance
- administration\_mode\_enabled: Enable admin mode for the environment
- background\_operation\_enabled: Enable background operations
- template\_metadata: Additional D365 template metadata as string
- templates: List of D365 template names

Examples:

# Production Dataverse  
dataverse = {  
  language\_code                = 1033  # English (United States) - INTEGER!  
  currency\_code               = "USD"  
  security\_group\_id           = "12345678-1234-1234-1234-123456789012"  
  domain                      = "contoso-prod"  
  administration\_mode\_enabled = false  
  background\_operation\_enabled = true
}

# No Dataverse  
dataverse = null

Type:

```hcl
object({
    # Required Arguments - ✅ REAL
    language_code = number # LCID integer, not string!
    currency_code = string

    # Optional Arguments - ✅ REAL
    security_group_id            = optional(string)
    domain                       = optional(string)
    administration_mode_enabled  = optional(bool)
    background_operation_enabled = optional(bool)
    template_metadata            = optional(string) # String, not object!
    templates                    = optional(list(string))
  })
```

Default: `null`

### <a name="input_enable_duplicate_protection"></a> [enable\_duplicate\_protection](#input\_enable\_duplicate\_protection)

Description: Enable duplicate environment detection and prevention.

Type: `bool`

Default: `true`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Optional tags for Terraform state organization and governance.

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

### <a name="output_enterprise_policies"></a> [enterprise\_policies](#output\_enterprise\_policies)

Description: Enterprise policies applied to the environment (read-only from provider)

### <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id)

Description: The unique identifier of the Power Platform environment.

This output provides the primary key for referencing this environment  
in other Terraform configurations, DLP policies, or external systems.  
The ID is stable across environment updates and safe for external consumption.

### <a name="output_environment_metadata"></a> [environment\_metadata](#output\_environment\_metadata)

Description: Additional environment metadata for operational monitoring and compliance

### <a name="output_environment_summary"></a> [environment\_summary](#output\_environment\_summary)

Description: Summary of deployed environment configuration for validation and compliance reporting

### <a name="output_environment_url"></a> [environment\_url](#output\_environment\_url)

Description: The web URL for accessing the Power Platform environment.

This URL can be used for:
- Direct admin center access
- Power Apps maker portal links
- Power Automate environment access
- API endpoint construction

Note: Returns Dataverse URL when Dataverse is enabled, otherwise null.

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