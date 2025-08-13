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

## Pre-requisites - Granting Service Principal System Administrator Permissions

To ensure the service principal used by Terraform has the necessary permissions to manage Power Platform environments, you must assign it the **System Administrator** role in each target environment. This is required for successful resource provisioning and lifecycle management.

Use the provided script to automate this process:

```bash
./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve
```

**Script Purpose:**
- Adds the service principal (configured in `config.env`) as System Administrator on all Power Platform environments.
- Supports targeting specific environments, dry-run mode, and interactive confirmation.

**Requirements:**
- Power Platform CLI (`pac`) installed and authenticated
- Service principal configured in Azure AD and `config.env`
- Power Platform Administrator privileges for the executing user

**Example:**
```bash
# Assign permissions to all environments automatically
./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve

# Assign permissions to a specific environment
./scripts/utils/assign-sp-power-platform-envs.sh --environment "<environment-id>" --auto-approve
```

> **Note:** This step is mandatory before running Terraform to avoid permission errors during environment creation or management.

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) | ~> 3.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |
| <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) | ~> 3.8 |

## Resources

| Name | Type |
|------|------|
| [null_resource.environment_duplicate_guardrail](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [powerplatform_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) | resource |
| [powerplatform_environments.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/environments) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Power Platform environment configuration using ONLY real provider arguments.<br/><br/>This variable includes exclusively the arguments that actually exist in the <br/>microsoft/power-platform provider to ensure 100% compatibility.<br/><br/>Required Properties:<br/>- display\_name: Human-readable environment name<br/>- location: Power Platform region (e.g., "unitedstates", "europe")<br/>- environment\_type: Environment classification (Sandbox, Production, Trial)<br/>  ⚠️  Developer environments are NOT SUPPORTED with service principal authentication<br/>- environment\_group\_id: GUID for environment group membership (REQUIRED for governance)<br/><br/>Optional Properties:<br/>- description: Environment description<br/>- azure\_region: Specific Azure region (westeurope, eastus, etc.)<br/>- cadence: Update cadence ("Frequent" or "Moderate")<br/>- allow\_bing\_search: Enable Bing search in the environment<br/>- allow\_moving\_data\_across\_regions: Allow data movement across regions<br/>- billing\_policy\_id: GUID for pay-as-you-go billing policy<br/>- release\_cycle: Early release participation<br/><br/>Examples:<br/><br/># Production Environment<br/>environment = {<br/>  display\_name                     = "Production Finance Environment"<br/>  location                        = "unitedstates"<br/>  environment\_type               = "Production"<br/>  environment\_group\_id           = "12345678-1234-1234-1234-123456789012"<br/>  description                    = "Production environment for Finance applications"<br/>  azure\_region                   = "eastus"<br/>  cadence                        = "Moderate"<br/>  allow\_bing\_search              = false<br/>  allow\_moving\_data\_across\_regions = false<br/>}<br/><br/># Sandbox Environment<br/>environment = {<br/>  display\_name         = "Development Sandbox"<br/>  location             = "unitedstates"<br/>  environment\_type     = "Sandbox"<br/>  environment\_group\_id = "87654321-4321-4321-4321-210987654321"<br/>  cadence              = "Frequent"<br/>}<br/><br/>Limitations:<br/>- Developer environments require user authentication (not service principal)<br/>- This module only supports Sandbox, Production, and Trial environment types<br/>- environment\_group\_id is now REQUIRED to ensure proper organizational governance | <pre>object({<br/>    # Required Arguments - ✅ REAL<br/>    display_name         = string<br/>    location             = string<br/>    environment_type     = string<br/>    environment_group_id = string # ✅ NOW REQUIRED for proper governance<br/><br/>    # Optional Arguments - ✅ REAL<br/>    description                      = optional(string)<br/>    azure_region                     = optional(string)<br/>    cadence                          = optional(string) # "Frequent" or "Moderate" only<br/>    allow_bing_search                = optional(bool)<br/>    allow_moving_data_across_regions = optional(bool)<br/>    billing_policy_id                = optional(string)<br/>    release_cycle                    = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_dataverse"></a> [dataverse](#input\_dataverse) | Dataverse database configuration for the Power Platform environment.<br/><br/>Required Properties when Dataverse is enabled:<br/>- language\_code: LCID integer (e.g., 1033 for English US) <br/>- currency\_code: ISO currency code string (e.g., "USD", "EUR", "GBP")<br/>- security\_group\_id: Azure AD security group GUID (REQUIRED for governance)<br/><br/>Optional Properties:<br/>- domain: Custom domain name for the Dataverse instance (auto-calculated from display\_name if not provided)<br/>- administration\_mode\_enabled: Enable admin mode for the environment<br/>- background\_operation\_enabled: Enable background operations<br/>- template\_metadata: Additional D365 template metadata as string<br/>- templates: List of D365 template names<br/><br/>Examples:<br/><br/># Production/Sandbox/Trial Dataverse (security\_group\_id REQUIRED)<br/>dataverse = {<br/>  language\_code     = 1033<br/>  currency\_code     = "USD"<br/>  security\_group\_id = "12345678-1234-1234-1234-123456789012"<br/>  domain            = "contoso-prod" # Optional: Will auto-calculate if not provided<br/>}<br/><br/># Auto-calculated domain (recommended)<br/>dataverse = {<br/>  language\_code     = 1033<br/>  currency\_code     = "USD"<br/>  security\_group\_id = "12345678-1234-1234-1234-123456789012"<br/>  # domain will be auto-calculated from environment.display\_name<br/>}<br/><br/># No Dataverse<br/>dataverse = null<br/><br/>Domain Auto-calculation:<br/>When domain is not provided, it will be automatically generated from environment.display\_name:<br/>- "Production Finance Environment" → "production-finance-environment"<br/>- "Dev Test 123" → "dev-test-123"<br/>- Handles special characters, spaces, and length limits correctly<br/><br/>Provider Requirements:<br/>- security\_group\_id is MANDATORY when dataverse object is provided<br/>- domain is auto-calculated if not specified (recommended for consistency) | <pre>object({<br/>    # Required Arguments when Dataverse is enabled - ✅ REAL<br/>    language_code     = number # LCID integer, not string!<br/>    currency_code     = string<br/>    security_group_id = string # ✅ NOW REQUIRED when dataverse is provided<br/><br/>    # Optional Arguments - ✅ REAL<br/>    domain                       = optional(string) # Auto-calculated from display_name if null<br/>    administration_mode_enabled  = optional(bool)<br/>    background_operation_enabled = optional(bool)<br/>    template_metadata            = optional(string) # String, not object!<br/>    templates                    = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_enable_duplicate_protection"></a> [enable\_duplicate\_protection](#input\_enable\_duplicate\_protection) | Enable duplicate environment detection and prevention. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dataverse_configuration"></a> [dataverse\_configuration](#output\_dataverse\_configuration) | Dataverse database configuration details when enabled, null otherwise |
| <a name="output_dataverse_organization_url"></a> [dataverse\_organization\_url](#output\_dataverse\_organization\_url) | The organization URL for the Dataverse database, if enabled.<br/><br/>Returns the base URL for Dataverse API access and application integrations.<br/>Will be null if Dataverse is not configured for this environment. |
| <a name="output_domain_calculation_summary"></a> [domain\_calculation\_summary](#output\_domain\_calculation\_summary) | Summary of domain calculation logic and results for transparency |
| <a name="output_enterprise_policies"></a> [enterprise\_policies](#output\_enterprise\_policies) | Enterprise policies applied to the environment (read-only from provider) |
| <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id) | The unique identifier of the Power Platform environment.<br/><br/>This output provides the primary key for referencing this environment<br/>in other Terraform configurations, DLP policies, or external systems.<br/>The ID is stable across environment updates and safe for external consumption. |
| <a name="output_environment_metadata"></a> [environment\_metadata](#output\_environment\_metadata) | Additional environment metadata for operational monitoring and compliance |
| <a name="output_environment_summary"></a> [environment\_summary](#output\_environment\_summary) | Summary of deployed environment configuration for validation and compliance reporting |
| <a name="output_environment_url"></a> [environment\_url](#output\_environment\_url) | The web URL for accessing the Power Platform environment.<br/><br/>This URL can be used for:<br/>- Direct admin center access<br/>- Power Apps maker portal links<br/>- Power Automate environment access<br/>- API endpoint construction<br/><br/>Note: Returns Dataverse URL when Dataverse is enabled, otherwise null. |

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