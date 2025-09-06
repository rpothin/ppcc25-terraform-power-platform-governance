<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Configuration with Managed Environment Integration

This configuration creates and manages Power Platform environments with optional managed environment features, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## 🎯 Key Features

- **Consolidated Governance**: Environment and managed environment creation in a single atomic operation
- **Default Best Practices**: Managed environment features enabled by default for enhanced governance
- **Flexible Configuration**: Comprehensive settings for sharing, solution checking, and maker onboarding
- **Backward Compatibility**: Existing configurations continue to work unchanged
- **Provider Optimization**: Eliminates timing issues from separate module orchestration

## Use Cases

This configuration is designed for organizations that need to:

1. **Governed Environment Deployment**: Create environments with built-in governance controls, sharing policies, and solution validation
2. **Consolidated Management**: Manage both environment and governance features through a single Terraform configuration
3. **Enterprise Compliance**: Enforce organization-wide policies for maker onboarding, solution quality, and data sharing
4. **Migration from Separate Modules**: Transition from `res-environment` + `res-managed-environment` to consolidated pattern
5. **Production-Ready Governance**: Deploy environments with enterprise-grade controls enabled by default

## 🆕 What's New: Managed Environment Integration

This module now includes optional managed environment capabilities that provide:

- **Enhanced Sharing Controls**: Group-based sharing policies and user limits
- **Solution Quality Gates**: Automated solution checker validation before deployment
- **Maker Guidance**: Customizable onboarding content for new Power Platform makers
- **Usage Insights**: Optional weekly usage reporting for environment administrators
- **Enterprise Policies**: Advanced governance features for organizational compliance

### Default Behavior (Managed Environment Enabled)

```hcl
module "environment" {
  source = "./configurations/res-environment"
  environment = {
    display_name         = "Production Finance Environment"
    location             = "unitedstates"
    environment_group_id = "12345678-1234-1234-1234-123456789012"
  }
  dataverse = {
    currency_code     = "USD"
    security_group_id = "your-security-group-id"
  }
  # Managed environment enabled by default
  # enable_managed_environment = true (default)
  # managed_environment_settings = {} (uses secure defaults)
}
```

### Opt-Out for Basic Environments

```hcl
module "environment" {
  source = "./configurations/res-environment"
  environment = {
    display_name = "Development Sandbox"
    location     = "unitedstates"
  }
  # Disable managed features for basic development
  enable_managed_environment = false
}
```

### Custom Governance Configuration

```hcl
module "environment" {
  source = "./configurations/res-environment"
  environment = {
    display_name         = "Strict Production Environment"
    location             = "unitedstates"
    environment_type     = "Production"
    environment_group_id = "12345678-1234-1234-1234-123456789012"
  }
  dataverse = {
    currency_code     = "USD"
    security_group_id = "your-security-group-id"
  }
  managed_environment_settings = {
    sharing_settings = {
      is_group_sharing_disabled = true
      limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
      max_limit_user_sharing    = 5
    }
    solution_checker = {
      mode                       = "Block"
      suppress_validation_emails = false
    }
    maker_onboarding = {
      markdown_content = "Welcome to Production! Please review our development standards."
      learn_more_url   = "https://company.com/powerplatform-guidelines"
    }
  }
}
```

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

- <a name="provider_null"></a> [null](#provider\_null) (~> 3.0)

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [null_resource.environment_duplicate_guardrail](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [powerplatform_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) (resource)
- [powerplatform_managed_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment) (resource)
- [powerplatform_environments.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/environments) (data source)

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

The following input variables are optional (have default values):

### <a name="input_enable_duplicate_protection"></a> [enable\_duplicate\_protection](#input\_enable\_duplicate\_protection)

Description: Enable duplicate environment detection and prevention for operational safety.

Type: `bool`

Default: `true`

### <a name="input_enable_managed_environment"></a> [enable\_managed\_environment](#input\_enable\_managed\_environment)

Description: Enable managed environment features for enhanced governance and control.  
Default: true (following Power Platform best practices)

WHY: Managed environments are now best practice for production workloads.  
This default ensures governance features are enabled unless explicitly disabled.

When enabled (default):
- Creates managed environment configuration automatically
- Applies governance controls and policies
- Enables solution checker validation
- Provides enhanced sharing controls
- Supports maker onboarding and guidance

When disabled:
- Environment created without managed features
- Standard environment capabilities only
- Manual governance configuration required
- Typically only used for basic development scenarios

Note: Developer environment types automatically disable managed environment  
features regardless of this setting due to provider limitations.

Examples:  
enable\_managed\_environment = true   # Default: Enable governance features  
enable\_managed\_environment = false  # Disable for basic development environments

Type: `bool`

Default: `true`

### <a name="input_managed_environment_settings"></a> [managed\_environment\_settings](#input\_managed\_environment\_settings)

Description: Managed environment configuration settings.  
Only applied when enable\_managed\_environment is true.

WHY: Provides flexible governance configuration while maintaining secure defaults.  
All settings follow Microsoft's recommended baseline for governed environments.

Configuration Groups:

1. SHARING SETTINGS: Controls app and flow sharing behavior
   - is\_group\_sharing\_disabled: When false (default), enables security group sharing
   - limit\_sharing\_mode: "NoLimit" (default) or "ExcludeSharingToSecurityGroups"
   - max\_limit\_user\_sharing: -1 (default, unlimited when group sharing enabled)

2. USAGE INSIGHTS: Weekly usage reporting
   - usage\_insights\_disabled: true (default) to avoid email spam

3. SOLUTION CHECKER: Quality validation for solution imports
   - mode: "Warn" (default) provides validation without blocking
   - suppress\_validation\_emails: true (default) reduces noise
   - rule\_overrides: null (default) applies full validation suite

4. MAKER ONBOARDING: Welcome content for new makers
   - markdown\_content: Default welcome message
   - learn\_more\_url: Microsoft Learn documentation link

Examples:

# Use defaults (recommended for most environments)  
managed\_environment\_settings = {}

# Custom governance configuration  
managed\_environment\_settings = {  
  sharing\_settings = {  
    is\_group\_sharing\_disabled = false  
    limit\_sharing\_mode        = "NoLimit"  
    max\_limit\_user\_sharing    = -1
  }  
  usage\_insights\_disabled = false  
  solution\_checker = {  
    mode                       = "Block"  
    suppress\_validation\_emails = false  
    rule\_overrides             = ["meta-avoid-reg-no-attribute"]
  }  
  maker\_onboarding = {  
    markdown\_content = "Welcome to Production! Please review our development standards before creating solutions."  
    learn\_more\_url   = "https://contoso.com/powerplatform-guidelines"
  }
}

# Strict production environment  
managed\_environment\_settings = {  
  sharing\_settings = {  
    is\_group\_sharing\_disabled = true  
    limit\_sharing\_mode        = "ExcludeSharingToSecurityGroups"  
    max\_limit\_user\_sharing    = 5
  }  
  solution\_checker = {  
    mode = "Block"  
    suppress\_validation\_emails = false
  }
}

Validation Rules:
- When group sharing is disabled, max\_limit\_user\_sharing must be > 0
- When group sharing is enabled, max\_limit\_user\_sharing should be -1
- Solution checker mode must be: None, Warn, or Block
- Rule overrides must contain valid solution checker rule names

See: https://learn.microsoft.com/power-platform/admin/managed-environment-overview

Type:

```hcl
object({
    sharing_settings = optional(object({
      is_group_sharing_disabled = optional(bool, false)
      limit_sharing_mode        = optional(string, "NoLimit")
      max_limit_user_sharing    = optional(number, -1)
    }), {})

    usage_insights_disabled = optional(bool, true)

    solution_checker = optional(object({
      mode                       = optional(string, "Warn")
      suppress_validation_emails = optional(bool, true)
      rule_overrides             = optional(set(string), null)
    }), {})

    maker_onboarding = optional(object({
      markdown_content = optional(string, "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions.")
      learn_more_url   = optional(string, "https://learn.microsoft.com/power-platform/")
    }), {})
  })
```

Default: `{}`

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

### <a name="output_managed_environment_enabled"></a> [managed\_environment\_enabled](#output\_managed\_environment\_enabled)

Description: Boolean indicating whether managed environment features are enabled for this environment

### <a name="output_managed_environment_id"></a> [managed\_environment\_id](#output\_managed\_environment\_id)

Description: The unique identifier of the managed environment configuration, if enabled.

This output provides the primary key for referencing this managed environment  
in other Terraform configurations or external systems when managed environment  
features are enabled. Returns null when managed environment is disabled.

Use this ID to:
- Reference in enterprise policy configurations
- Integrate with monitoring and reporting systems
- Set up advanced governance policies
- Configure environment-specific automation

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012) or null  
Note: This is the same as the environment\_id but confirms successful managed environment setup

### <a name="output_managed_environment_summary"></a> [managed\_environment\_summary](#output\_managed\_environment\_summary)

Description: Summary of deployed managed environment configuration for validation and compliance reporting, null if disabled

## Modules

No modules.

## 🔄 Migration from Separate Modules

If you're currently using separate `res-environment` and `res-managed-environment` modules, this consolidated approach offers several benefits:

### Migration Benefits

- **Eliminates Timing Issues**: No more "Request url must be an absolute url" errors
- **Atomic Operations**: Environment and managed features created together
- **Simplified Dependencies**: Single module instead of complex orchestration
- **Better Performance**: Fewer API calls and state operations

### Migration Steps

#### Step 1: Backup Current State

```bash
# Export current Terraform state
terraform state pull > backup-state.json

# Document current environment IDs
terraform output -json > current-outputs.json
```

#### Step 2: Update Module References

**Before (Separate Modules):**
```hcl
module "environment" {
  source = "./configurations/res-environment"
  # ... environment configuration
}

module "managed_environment" {
  source = "./configurations/res-managed-environment"
  environment_id = module.environment.environment_id
  # ... managed environment configuration
}
```

**After (Consolidated Module):**
```hcl
module "environment" {
  source = "./configurations/res-environment"
  # ... existing environment configuration (unchanged)
  # Add managed environment settings
  enable_managed_environment = true
  managed_environment_settings = {
    # Transfer settings from old managed_environment module variables
    sharing_settings = {
      is_group_sharing_disabled = var.old_sharing_settings.is_group_sharing_disabled
      limit_sharing_mode        = var.old_sharing_settings.limit_sharing_mode
      max_limit_user_sharing    = var.old_sharing_settings.max_limit_user_sharing
    }
    # ... other settings
  }
}
```

#### Step 3: Remove Old Managed Environment Resources

```bash
# Remove the old managed environment from state
terraform state rm 'module.managed_environment.powerplatform_managed_environment.this'

# Plan with new configuration to see the import
terraform plan
```

#### Step 4: Import Existing Managed Environment (If Needed)

```bash
# Import the existing managed environment into the new resource
terraform import 'module.environment.powerplatform_managed_environment.this[0]' <environment-id>
```

### Compatibility Notes

- **Environment Configuration**: All existing environment settings remain unchanged
- **Variable Names**: Environment and Dataverse variables are identical
- **Outputs**: New managed environment outputs added, existing outputs preserved
- **Lifecycle**: Managed environments are protected by the same "No Touch Prod" policy

### Testing Migration

1. **Test in Development**: Migrate a development environment first
2. **Validate Outputs**: Confirm all required outputs are still available
3. **Check Dependencies**: Ensure downstream modules receive expected values
4. **Monitor Drift**: Verify no configuration drift after migration

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

**Managed Environment Issues**
- Verify the environment type supports managed features (Sandbox, Production, Trial)
- Check that Dataverse is configured (required for managed environments)
- Ensure proper sharing configuration: group sharing enabled requires max\_limit\_user\_sharing = -1
- Validate solution checker mode is one of: None, Warn, Block

### Migration Troubleshooting

**State Import Issues**
- Use `terraform state list` to verify resource paths
- Check environment ID format: must be valid GUID
- Ensure managed environment exists before import

**Configuration Conflicts**
- Review validation error messages for specific guidance
- Verify sharing settings combinations are valid
- Check that environment group ID is provided when needed

## Additional Links

- [Power Platform Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment)
- [Power Platform Managed Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [Managed Environment Overview](https://learn.microsoft.com/power-platform/admin/managed-environment-overview)
<!-- END_TF_DOCS -->