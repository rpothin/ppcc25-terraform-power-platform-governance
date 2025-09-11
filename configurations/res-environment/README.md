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

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_null"></a> [null](#requirement\_null) (~> 3.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [powerplatform_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_dataverse"></a> [dataverse](#input\_dataverse)

Description: Dataverse database configuration with opinionated default values.

**GOVERNANCE REQUIREMENT**: Dataverse is REQUIRED for proper Power Platform governance.  
This ensures all environments have proper data protection, security controls, and organizational structure.

⚙️ DEFAULT VALUES APPLIED:
- language\_code = 1033 (English US - most tested and secure)
- administration\_mode\_enabled = false (Power Platform creates operational environments)
- background\_operation\_enabled = true (Power Platform enables background ops for initialization)

⚠️  POWER PLATFORM BEHAVIOR NOTE:  
These defaults reflect actual Power Platform creation behavior, not idealized security settings.  
Power Platform has opinionated defaults for environment lifecycle management:
- New environments start in operational mode (admin\_mode = false)
- Background operations are enabled to support environment initialization
- These settings can be adjusted post-creation if needed for enhanced security

Required Properties:
- currency\_code: ISO currency code string (EXPLICIT CHOICE - e.g., "USD", "EUR", "GBP")
- security\_group\_id: Azure AD security group GUID (REQUIRED for governance)

Optional Properties with Default Values:
- language\_code: LCID integer (default: 1033 for English US)
- domain: Custom domain name (auto-calculated from display\_name if not provided)
- administration\_mode\_enabled: Admin mode state (default: false - operational)
- background\_operation\_enabled: Background operations (default: true - enabled)
- template\_metadata: Additional D365 template metadata as string
- templates: List of D365 template names

Examples:

# Standard Environment (using default values)  
dataverse = {  
  currency\_code     = "USD"  # EXPLICIT CHOICE  
  security\_group\_id = "12345678-1234-1234-1234-123456789012"
  # All other properties use default values:
  # - language\_code = 1033 (English US)
  # - administration\_mode\_enabled = false (operational)
  # - background\_operation\_enabled = true (enabled)
  # - domain will be auto-calculated
}

# European Environment with Localized Choices  
dataverse = {  
  language\_code     = 1036    # Override: French  
  currency\_code     = "EUR"   # EXPLICIT CHOICE  
  security\_group\_id = "12345678-1234-1234-1234-123456789012"  
  domain            = "contoso-eu"
  # Default values maintained:
  # - administration\_mode\_enabled = false (operational)
  # - background\_operation\_enabled = true (enabled)
}

# High-Security Environment (explicit overrides for enhanced security)  
dataverse = {  
  currency\_code                = "USD"   # EXPLICIT CHOICE  
  security\_group\_id            = "12345678-1234-1234-1234-123456789012"  
  administration\_mode\_enabled  = true    # Override: Enable admin mode for security  
  background\_operation\_enabled = false   # Override: Disable background ops for review
}

Governance Benefits:
- Enforces consistent data protection across all environments
- Ensures proper security group assignment for access control
- Enables advanced governance features like DLP policies
- Provides audit trail and compliance capabilities

Type:

```hcl
object({
    # Required Arguments when Dataverse is enabled - ✅ REAL
    currency_code     = string # EXPLICIT CHOICE: Financial currency must be specified
    security_group_id = string # ✅ NOW REQUIRED when dataverse is provided

    # Optional Arguments - ✅ REAL with SECURE DEFAULTS
    language_code                = optional(number, 1033) # SECURE DEFAULT: English US (most tested)
    domain                       = optional(string)       # Auto-calculated from display_name if null
    administration_mode_enabled  = optional(bool, false)  # POWER PLATFORM DEFAULT: New environments start operational
    background_operation_enabled = optional(bool, true)   # POWER PLATFORM DEFAULT: Background ops enabled for initialization
    template_metadata            = optional(string)       # String, not object!
    templates                    = optional(list(string))
  })
```

### <a name="input_environment"></a> [environment](#input\_environment)

Description: Power Platform environment configuration with opinionated default values.

This variable includes exclusively the arguments that actually exist in the   
microsoft/power-platform provider to ensure 100% compatibility.

⚙️ DEFAULT VARIABLE VALUES:
- environment\_type = "Sandbox" (lowest-privilege environment type)
- cadence = "Moderate" (stable update cadence for production readiness)
- AI settings (Bing search, cross-region data) controlled by environment group rules

Required Properties:
- display\_name: Human-readable environment name
- location: Power Platform region (EXPLICIT CHOICE - e.g., "unitedstates", "europe")
- environment\_group\_id: GUID for environment group membership (REQUIRED for governance)

Optional Properties with Default Values:
- environment\_type: Environment classification (default: "Sandbox" for least privilege)
  ⚠️  Developer environments are NOT SUPPORTED with service principal authentication
- description: Environment description
- azure\_region: Specific Azure region (westeurope, eastus, etc.)
- cadence: Update cadence (default: "Moderate" for stability)
- billing\_policy\_id: GUID for pay-as-you-go billing policy
- release\_cycle: Early release participation

🤖 AI SETTINGS GOVERNANCE:  
Bing search and cross-region data movement are controlled by environment group rules.  
Configure these settings through the environment group's ai\_generative\_settings rules.

Examples:

# Standard Environment (using default variable values)  
environment = {  
  display\_name         = "Secure Finance Environment"  
  location             = "unitedstates"  
  environment\_group\_id = "12345678-1234-1234-1234-123456789012"  
  description          = "High-security environment with AI governance via group rules"
  # All other properties use default values:
  # - environment\_type = "Sandbox"
  # - cadence = "Moderate"
  # AI settings controlled by environment group rules
}

# Production Environment with Explicit Security Settings  
environment = {  
  display\_name                     = "Production Finance Environment"  
  location                         = "unitedstates"  
  environment\_type                 = "Production"  # Override default  
  environment\_group\_id             = "12345678-1234-1234-1234-123456789012"  
  description                      = "Production environment with strict data governance"  
  azure\_region                     = "eastus"
  # Default values maintained:
  # - cadence = "Moderate"
  # AI settings controlled by environment group governance rules
}

# AI-Enabled Development Environment (via environment group)  
environment = {  
  display\_name                     = "AI Development Sandbox"  
  location                         = "unitedstates"            # EXPLICIT CHOICE  
  environment\_group\_id             = "87654321-4321-4321-4321-210987654321"  
  description                      = "Development environment with AI capabilities via group rules"
  # AI settings configured through environment group's ai\_generative\_settings:
  # - Environment group rule: bing\_search\_enabled = true
  # - Environment group rule: move\_data\_across\_regions\_enabled = true
}

🚨 AI CAPABILITY GOVERNANCE:  
AI capabilities are controlled by environment group rules, not individual environment settings.  
Configure ai\_generative\_settings in your environment group to enable/disable:
- bing\_search\_enabled: Controls Copilot Studio, Power Pages Copilot, Dynamics 365 AI
- move\_data\_across\_regions\_enabled: Controls Power Apps AI, Power Automate Copilot, AI Builder

Limitations:
- Developer environments require user authentication (not service principal)
- This module only supports Sandbox, Production, and Trial environment types
- environment\_group\_id is now REQUIRED to ensure proper organizational governance

Type:

```hcl
object({
    # Required Arguments - ✅ REAL
    display_name         = string
    location             = string # EXPLICIT CHOICE: Geographic location must be specified
    environment_group_id = string # ✅ NOW REQUIRED for proper governance

    # Optional Arguments - ✅ REAL with SECURE DEFAULTS
    environment_type = optional(string, "Sandbox") # SECURE DEFAULT: Lowest-privilege environment type
    description      = optional(string)
    azure_region     = optional(string)             # Let Power Platform choose optimal region
    cadence          = optional(string, "Moderate") # SECURE DEFAULT: Stable update cadence
    # AI settings removed - controlled by environment group rules when environment_group_id is required
    # allow_bing_search                = optional(bool, false)        # CONTROLLED BY ENVIRONMENT GROUP
    # allow_moving_data_across_regions = optional(bool, false)        # CONTROLLED BY ENVIRONMENT GROUP
    billing_policy_id = optional(string)
    release_cycle     = optional(string)
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_dataverse_configuration"></a> [dataverse\_configuration](#output\_dataverse\_configuration)

Description: Dataverse database configuration details when enabled, null otherwise

### <a name="output_dataverse_organization_url"></a> [dataverse\_organization\_url](#output\_dataverse\_organization\_url)

Description: The organization URL for the Dataverse database, if enabled.

Returns the base URL for Dataverse API access and application integrations.  
Will be null if Dataverse is not configured for this environment.

### <a name="output_domain_calculation_summary"></a> [domain\_calculation\_summary](#output\_domain\_calculation\_summary)

Description: Summary of domain calculation logic and results for transparency

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

### <a name="output_resource_summary"></a> [resource\_summary](#output\_resource\_summary)

Description: Summary information for pattern module orchestration and compliance reporting

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