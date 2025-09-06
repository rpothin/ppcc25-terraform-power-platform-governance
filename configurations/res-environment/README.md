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

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) | ~> 3.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) | ~> 3.8 |

## Resources

| Name | Type |
|------|------|
| [null_resource.environment_duplicate_guardrail](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [powerplatform_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) | resource |
| [powerplatform_managed_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment) | resource |
| [powerplatform_environments.all](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/environments) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dataverse"></a> [dataverse](#input\_dataverse) | Dataverse database configuration with opinionated default values.<br/><br/>**GOVERNANCE REQUIREMENT**: Dataverse is REQUIRED for proper Power Platform governance.<br/>This ensures all environments have proper data protection, security controls, and organizational structure.<br/><br/>⚙️ DEFAULT VALUES APPLIED:<br/>- language\_code = 1033 (English US - most tested and secure)<br/>- administration\_mode\_enabled = false (Power Platform creates operational environments)<br/>- background\_operation\_enabled = true (Power Platform enables background ops for initialization)<br/><br/>⚠️  POWER PLATFORM BEHAVIOR NOTE:<br/>These defaults reflect actual Power Platform creation behavior, not idealized security settings.<br/>Power Platform has opinionated defaults for environment lifecycle management:<br/>- New environments start in operational mode (admin\_mode = false)<br/>- Background operations are enabled to support environment initialization<br/>- These settings can be adjusted post-creation if needed for enhanced security<br/><br/>Required Properties:<br/>- currency\_code: ISO currency code string (EXPLICIT CHOICE - e.g., "USD", "EUR", "GBP")<br/>- security\_group\_id: Azure AD security group GUID (REQUIRED for governance)<br/><br/>Optional Properties with Default Values:<br/>- language\_code: LCID integer (default: 1033 for English US)<br/>- domain: Custom domain name (auto-calculated from display\_name if not provided)<br/>- administration\_mode\_enabled: Admin mode state (default: false - operational)<br/>- background\_operation\_enabled: Background operations (default: true - enabled)<br/>- template\_metadata: Additional D365 template metadata as string<br/>- templates: List of D365 template names<br/><br/>Examples:<br/><br/># Standard Environment (using default values)<br/>dataverse = {<br/>  currency\_code     = "USD"  # EXPLICIT CHOICE<br/>  security\_group\_id = "12345678-1234-1234-1234-123456789012"<br/>  # All other properties use default values:<br/>  # - language\_code = 1033 (English US)<br/>  # - administration\_mode\_enabled = false (operational)<br/>  # - background\_operation\_enabled = true (enabled)<br/>  # - domain will be auto-calculated<br/>}<br/><br/># European Environment with Localized Choices<br/>dataverse = {<br/>  language\_code     = 1036    # Override: French<br/>  currency\_code     = "EUR"   # EXPLICIT CHOICE<br/>  security\_group\_id = "12345678-1234-1234-1234-123456789012"<br/>  domain            = "contoso-eu"<br/>  # Default values maintained:<br/>  # - administration\_mode\_enabled = false (operational)<br/>  # - background\_operation\_enabled = true (enabled)<br/>}<br/><br/># High-Security Environment (explicit overrides for enhanced security)<br/>dataverse = {<br/>  currency\_code                = "USD"   # EXPLICIT CHOICE<br/>  security\_group\_id            = "12345678-1234-1234-1234-123456789012"<br/>  administration\_mode\_enabled  = true    # Override: Enable admin mode for security<br/>  background\_operation\_enabled = false   # Override: Disable background ops for review<br/>}<br/><br/>Governance Benefits:<br/>- Enforces consistent data protection across all environments<br/>- Ensures proper security group assignment for access control<br/>- Enables advanced governance features like DLP policies<br/>- Provides audit trail and compliance capabilities | <pre>object({<br/>    # Required Arguments when Dataverse is enabled - ✅ REAL<br/>    currency_code     = string # EXPLICIT CHOICE: Financial currency must be specified<br/>    security_group_id = string # ✅ NOW REQUIRED when dataverse is provided<br/><br/>    # Optional Arguments - ✅ REAL with SECURE DEFAULTS<br/>    language_code                = optional(number, 1033) # SECURE DEFAULT: English US (most tested)<br/>    domain                       = optional(string)       # Auto-calculated from display_name if null<br/>    administration_mode_enabled  = optional(bool, false)  # POWER PLATFORM DEFAULT: New environments start operational<br/>    background_operation_enabled = optional(bool, true)   # POWER PLATFORM DEFAULT: Background ops enabled for initialization<br/>    template_metadata            = optional(string)       # String, not object!<br/>    templates                    = optional(list(string))<br/>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Power Platform environment configuration with opinionated default values.<br/><br/>This variable includes exclusively the arguments that actually exist in the <br/>microsoft/power-platform provider to ensure 100% compatibility.<br/><br/>⚙️ DEFAULT VARIABLE VALUES:<br/>- environment\_type = "Sandbox" (lowest-privilege environment type)<br/>- cadence = "Moderate" (stable update cadence for production readiness)<br/>- AI settings (Bing search, cross-region data) controlled by environment group rules<br/><br/>Required Properties:<br/>- display\_name: Human-readable environment name<br/>- location: Power Platform region (EXPLICIT CHOICE - e.g., "unitedstates", "europe")<br/>- environment\_group\_id: GUID for environment group membership (REQUIRED for governance)<br/><br/>Optional Properties with Default Values:<br/>- environment\_type: Environment classification (default: "Sandbox" for least privilege)<br/>  ⚠️  Developer environments are NOT SUPPORTED with service principal authentication<br/>- description: Environment description<br/>- azure\_region: Specific Azure region (westeurope, eastus, etc.)<br/>- cadence: Update cadence (default: "Moderate" for stability)<br/>- billing\_policy\_id: GUID for pay-as-you-go billing policy<br/>- release\_cycle: Early release participation<br/><br/>🤖 AI SETTINGS GOVERNANCE:<br/>Bing search and cross-region data movement are controlled by environment group rules.<br/>Configure these settings through the environment group's ai\_generative\_settings rules.<br/><br/>Examples:<br/><br/># Standard Environment (using default variable values)<br/>environment = {<br/>  display\_name         = "Secure Finance Environment"<br/>  location             = "unitedstates"<br/>  environment\_group\_id = "12345678-1234-1234-1234-123456789012"<br/>  description          = "High-security environment with AI governance via group rules"<br/>  # All other properties use default values:<br/>  # - environment\_type = "Sandbox"<br/>  # - cadence = "Moderate"<br/>  # AI settings controlled by environment group rules<br/>}<br/><br/># Production Environment with Explicit Security Settings<br/>environment = {<br/>  display\_name                     = "Production Finance Environment"<br/>  location                         = "unitedstates"<br/>  environment\_type                 = "Production"  # Override default<br/>  environment\_group\_id             = "12345678-1234-1234-1234-123456789012"<br/>  description                      = "Production environment with strict data governance"<br/>  azure\_region                     = "eastus"<br/>  # Default values maintained:<br/>  # - cadence = "Moderate"<br/>  # AI settings controlled by environment group governance rules<br/>}<br/><br/># AI-Enabled Development Environment (via environment group)<br/>environment = {<br/>  display\_name                     = "AI Development Sandbox"<br/>  location                         = "unitedstates"            # EXPLICIT CHOICE<br/>  environment\_group\_id             = "87654321-4321-4321-4321-210987654321"<br/>  description                      = "Development environment with AI capabilities via group rules"<br/>  # AI settings configured through environment group's ai\_generative\_settings:<br/>  # - Environment group rule: bing\_search\_enabled = true<br/>  # - Environment group rule: move\_data\_across\_regions\_enabled = true<br/>}<br/><br/>🚨 AI CAPABILITY GOVERNANCE:<br/>AI capabilities are controlled by environment group rules, not individual environment settings.<br/>Configure ai\_generative\_settings in your environment group to enable/disable:<br/>- bing\_search\_enabled: Controls Copilot Studio, Power Pages Copilot, Dynamics 365 AI<br/>- move\_data\_across\_regions\_enabled: Controls Power Apps AI, Power Automate Copilot, AI Builder<br/><br/>Limitations:<br/>- Developer environments require user authentication (not service principal)<br/>- This module only supports Sandbox, Production, and Trial environment types<br/>- environment\_group\_id is now REQUIRED to ensure proper organizational governance | <pre>object({<br/>    # Required Arguments - ✅ REAL<br/>    display_name         = string<br/>    location             = string # EXPLICIT CHOICE: Geographic location must be specified<br/>    environment_group_id = string # ✅ NOW REQUIRED for proper governance<br/><br/>    # Optional Arguments - ✅ REAL with SECURE DEFAULTS<br/>    environment_type = optional(string, "Sandbox") # SECURE DEFAULT: Lowest-privilege environment type<br/>    description      = optional(string)<br/>    azure_region     = optional(string)             # Let Power Platform choose optimal region<br/>    cadence          = optional(string, "Moderate") # SECURE DEFAULT: Stable update cadence<br/>    # AI settings removed - controlled by environment group rules when environment_group_id is required<br/>    # allow_bing_search                = optional(bool, false)        # CONTROLLED BY ENVIRONMENT GROUP<br/>    # allow_moving_data_across_regions = optional(bool, false)        # CONTROLLED BY ENVIRONMENT GROUP<br/>    billing_policy_id = optional(string)<br/>    release_cycle     = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_enable_duplicate_protection"></a> [enable\_duplicate\_protection](#input\_enable\_duplicate\_protection) | Enable duplicate environment detection and prevention for operational safety. | `bool` | `true` | no |
| <a name="input_enable_managed_environment"></a> [enable\_managed\_environment](#input\_enable\_managed\_environment) | Enable managed environment features for enhanced governance and control.<br/>Default: true (following Power Platform best practices)<br/><br/>WHY: Managed environments are now best practice for production workloads.<br/>This default ensures governance features are enabled unless explicitly disabled.<br/><br/>When enabled (default):<br/>- Creates managed environment configuration automatically<br/>- Applies governance controls and policies<br/>- Enables solution checker validation<br/>- Provides enhanced sharing controls<br/>- Supports maker onboarding and guidance<br/><br/>When disabled:<br/>- Environment created without managed features<br/>- Standard environment capabilities only<br/>- Manual governance configuration required<br/>- Typically only used for basic development scenarios<br/><br/>Note: Developer environment types automatically disable managed environment<br/>features regardless of this setting due to provider limitations.<br/><br/>Examples:<br/>enable\_managed\_environment = true   # Default: Enable governance features<br/>enable\_managed\_environment = false  # Disable for basic development environments | `bool` | `true` | no |
| <a name="input_managed_environment_settings"></a> [managed\_environment\_settings](#input\_managed\_environment\_settings) | Managed environment configuration settings.<br/>Only applied when enable\_managed\_environment is true.<br/><br/>WHY: Provides flexible governance configuration while maintaining secure defaults.<br/>All settings follow Microsoft's recommended baseline for governed environments.<br/><br/>Configuration Groups:<br/><br/>1. SHARING SETTINGS: Controls app and flow sharing behavior<br/>   - is\_group\_sharing\_disabled: When false (default), enables security group sharing<br/>   - limit\_sharing\_mode: "NoLimit" (default) or "ExcludeSharingToSecurityGroups"<br/>   - max\_limit\_user\_sharing: -1 (default, unlimited when group sharing enabled)<br/><br/>2. USAGE INSIGHTS: Weekly usage reporting<br/>   - usage\_insights\_disabled: true (default) to avoid email spam<br/><br/>3. SOLUTION CHECKER: Quality validation for solution imports<br/>   - mode: "Warn" (default) provides validation without blocking<br/>   - suppress\_validation\_emails: true (default) reduces noise<br/>   - rule\_overrides: null (default) applies full validation suite<br/><br/>4. MAKER ONBOARDING: Welcome content for new makers<br/>   - markdown\_content: Default welcome message<br/>   - learn\_more\_url: Microsoft Learn documentation link<br/><br/>Examples:<br/><br/># Use defaults (recommended for most environments)<br/>managed\_environment\_settings = {}<br/><br/># Custom governance configuration<br/>managed\_environment\_settings = {<br/>  sharing\_settings = {<br/>    is\_group\_sharing\_disabled = false<br/>    limit\_sharing\_mode        = "NoLimit"<br/>    max\_limit\_user\_sharing    = -1<br/>  }<br/>  usage\_insights\_disabled = false<br/>  solution\_checker = {<br/>    mode                       = "Block"<br/>    suppress\_validation\_emails = false<br/>    rule\_overrides             = ["meta-avoid-reg-no-attribute"]<br/>  }<br/>  maker\_onboarding = {<br/>    markdown\_content = "Welcome to Production! Please review our development standards before creating solutions."<br/>    learn\_more\_url   = "https://contoso.com/powerplatform-guidelines"<br/>  }<br/>}<br/><br/># Strict production environment<br/>managed\_environment\_settings = {<br/>  sharing\_settings = {<br/>    is\_group\_sharing\_disabled = true<br/>    limit\_sharing\_mode        = "ExcludeSharingToSecurityGroups"<br/>    max\_limit\_user\_sharing    = 5<br/>  }<br/>  solution\_checker = {<br/>    mode = "Block"<br/>    suppress\_validation\_emails = false<br/>  }<br/>}<br/><br/>Validation Rules:<br/>- When group sharing is disabled, max\_limit\_user\_sharing must be > 0<br/>- When group sharing is enabled, max\_limit\_user\_sharing should be -1<br/>- Solution checker mode must be: None, Warn, or Block<br/>- Rule overrides must contain valid solution checker rule names<br/><br/>See: https://learn.microsoft.com/power-platform/admin/managed-environment-overview | <pre>object({<br/>    sharing_settings = optional(object({<br/>      is_group_sharing_disabled = optional(bool, false)<br/>      limit_sharing_mode        = optional(string, "NoLimit")<br/>      max_limit_user_sharing    = optional(number, -1)<br/>    }), {})<br/><br/>    usage_insights_disabled = optional(bool, true)<br/><br/>    solution_checker = optional(object({<br/>      mode                       = optional(string, "Warn")<br/>      suppress_validation_emails = optional(bool, true)<br/>      rule_overrides             = optional(set(string), null)<br/>    }), {})<br/><br/>    maker_onboarding = optional(object({<br/>      markdown_content = optional(string, "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions.")<br/>      learn_more_url   = optional(string, "https://learn.microsoft.com/power-platform/")<br/>    }), {})<br/>  })</pre> | `{}` | no |

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
| <a name="output_managed_environment_enabled"></a> [managed\_environment\_enabled](#output\_managed\_environment\_enabled) | Boolean indicating whether managed environment features are enabled for this environment |
| <a name="output_managed_environment_id"></a> [managed\_environment\_id](#output\_managed\_environment\_id) | The unique identifier of the managed environment configuration, if enabled.<br/><br/>This output provides the primary key for referencing this managed environment<br/>in other Terraform configurations or external systems when managed environment<br/>features are enabled. Returns null when managed environment is disabled.<br/><br/>Use this ID to:<br/>- Reference in enterprise policy configurations<br/>- Integrate with monitoring and reporting systems<br/>- Set up advanced governance policies<br/>- Configure environment-specific automation<br/><br/>Format: GUID (e.g., 12345678-1234-1234-1234-123456789012) or null<br/>Note: This is the same as the environment\_id but confirms successful managed environment setup |
| <a name="output_managed_environment_summary"></a> [managed\_environment\_summary](#output\_managed\_environment\_summary) | Summary of deployed managed environment configuration for validation and compliance reporting, null if disabled |

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