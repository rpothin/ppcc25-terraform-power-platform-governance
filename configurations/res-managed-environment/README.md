<!-- BEGIN_TF_DOCS -->
# Power Platform Managed Environment Configuration

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

This configuration creates and manages Power Platform Managed Environments to provide enhanced governance, control, and administrative capabilities following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

**Last Updated**: 2025-01-17  
**Estimated Reading Time**: 8 minutes  
**Prerequisites**: Power Platform Environment Admin role, Premium licensing for managed environment features

## Use Cases

This module enables managed environment capabilities for Power Platform environments, providing:

- **Enhanced Governance**: Sharing controls, usage insights, and solution validation
- **Quality Assurance**: Automated solution checker enforcement with configurable rules
- **Maker Support**: Customizable onboarding content and learning resources
- **Compliance**: Advanced security features and administrative controls

## Usage with Resource Deployment Workflows

```hcl
module "managed_environment" {
  source = "./configurations/res-managed-environment"

  environment_id          = "12345678-1234-1234-1234-123456789012"
  usage_insights_disabled = false

  sharing_settings = {
    is_group_sharing_disabled = true
    limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
    max_limit_user_sharing    = 10
  }

  solution_checker = {
    mode                      = "Warn"
    suppress_validation_emails = true
    rule_overrides            = ["meta-avoid-reg-no-attribute"]
  }

  maker_onboarding = {
    markdown_content = "## Welcome\\n\\nPlease follow our guidelines."
    learn_more_url   = "https://company.com/power-platform-resources"
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.13)

## Providers

The following providers are used by this module:

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [powerplatform_managed_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_environment_id"></a> [environment\_id](#input\_environment\_id)

Description: GUID of the Power Platform environment to configure as a managed environment.

This is the primary identifier that links managed environment capabilities to the  
specific Power Platform environment instance.

Example:  
environment\_id = "12345678-1234-1234-1234-123456789012"

Requirements:
- Must be a valid GUID format for Power Platform compatibility
- Environment must exist before applying managed environment settings
- User must have Environment Admin privileges for the specified environment
- Environment must support managed environment capabilities (premium licensing required)

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_maker_onboarding"></a> [maker\_onboarding](#input\_maker\_onboarding)

Description: Maker onboarding configuration to provide guidance and resources for new Power Platform makers.

This configuration enables administrators to provide customized welcome content and  
learning resources that appear when makers first access Power Apps Studio in this environment.

Properties:
- markdown\_content: Rich text content displayed in Power Apps Studio (supports markdown)
- learn\_more\_url: URL for additional documentation, training, or support resources

Example:  
maker\_onboarding = {  
  markdown\_content = "## Welcome to Our Power Platform Environment\\n\\nPlease review our development guidelines before creating apps."  
  learn\_more\_url   = "https://company.com/power-platform-guidance"
}

Default Configuration:
- Provides basic welcome message with governance reminder
- Links to official Microsoft Power Platform documentation
- Can be customized for organization-specific guidance

Note: While maker onboarding can provide value, many organizations prefer to handle  
user guidance through separate training programs and documentation systems.

Validation Rules:
- markdown\_content must not be empty
- learn\_more\_url must be a valid HTTPS URL for security
- Content should follow organizational guidelines and branding

See: https://learn.microsoft.com/power-platform/admin/welcome-content

Type:

```hcl
object({
    # Markdown content displayed to first-time makers in Power Apps Studio
    markdown_content = string

    # URL for additional maker resources and guidance
    learn_more_url = string
  })
```

Default:

```json
{
  "learn_more_url": "https://learn.microsoft.com/power-platform/",
  "markdown_content": "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions."
}
```

### <a name="input_sharing_settings"></a> [sharing\_settings](#input\_sharing\_settings)

Description: Canvas app sharing controls and limitations for the managed environment.

This configuration manages how widely canvas apps can be shared within the organization,  
providing governance controls to prevent data exposure and maintain compliance.

Properties:
- is\_group\_sharing\_disabled: Prevents sharing with security groups when true
- limit\_sharing\_mode: Controls sharing scope ("NoLimit", "ExcludeSharingToSecurityGroups")
- max\_limit\_user\_sharing: Maximum users for individual sharing (-1 if group sharing enabled)

Example:  
sharing\_settings = {  
  is\_group\_sharing\_disabled = false  
  limit\_sharing\_mode        = "NoLimit"  
  max\_limit\_user\_sharing    = -1
}

Default Configuration (Governance Best Practice):
- Enables group sharing (is\_group\_sharing\_disabled = false)
- Allows unrestricted sharing (limit\_sharing\_mode = "NoLimit")
- Sets unlimited user sharing (max\_limit\_user\_sharing = -1)
- Encourages security group usage over individual user sharing

Validation Rules:
- If group sharing is disabled, max\_limit\_user\_sharing must be > 0
- If group sharing is enabled, max\_limit\_user\_sharing should be -1
- limit\_sharing\_mode must be a valid sharing mode value

See: https://learn.microsoft.com/power-platform/admin/managed-environment-sharing-limits

Type:

```hcl
object({
    # Control canvas app sharing across the organization
    is_group_sharing_disabled = bool

    # Define sharing scope and limitations  
    limit_sharing_mode = string

    # Maximum number of users for sharing (use -1 if group sharing is enabled)
    max_limit_user_sharing = number
  })
```

Default:

```json
{
  "is_group_sharing_disabled": false,
  "limit_sharing_mode": "NoLimit",
  "max_limit_user_sharing": -1
}
```

### <a name="input_solution_checker"></a> [solution\_checker](#input\_solution\_checker)

Description: Solution checker configuration for automated validation and quality control.

This configuration enables automatic verification of solution checker results for  
security and reliability issues before solution import, supporting governance  
and compliance requirements.

Properties:
- mode: Validation enforcement level (None, Warn, Block)
- suppress\_validation\_emails: When true, only sends emails for blocked solutions
- rule\_overrides: Set of solution checker rules to override/disable

Example:  
solution\_checker = {  
  mode                      = "Warn"  
  suppress\_validation\_emails = true  
  rule\_overrides            = ["meta-avoid-reg-no-attribute", "app-use-delayoutput-text-input"]
}

Default Configuration (Balanced Governance):
- Uses "Warn" mode for validation without blocking imports
- Suppresses validation emails to reduce noise
- No rule overrides (full validation suite)

Validation Rules:
- mode must be one of: None, Warn, Block
- rule\_overrides must contain valid solution checker rule names

See: https://learn.microsoft.com/power-platform/admin/managed-environment-solution-checker

Type:

```hcl
object({
    # Solution validation mode for imports
    mode = string

    # Email notification settings for validation results
    suppress_validation_emails = bool

    # Override specific solution checker rules
    rule_overrides = optional(set(string), [])
  })
```

Default:

```json
{
  "mode": "Warn",
  "rule_overrides": [],
  "suppress_validation_emails": true
}
```

### <a name="input_usage_insights_disabled"></a> [usage\_insights\_disabled](#input\_usage\_insights\_disabled)

Description: Controls whether weekly usage insights digest is disabled for the managed environment.

When set to false, administrators receive weekly email digests with usage  
insights for the environment. When set to true (default), these insights are disabled.

Example:  
usage\_insights\_disabled = false  # Enable weekly insights  
usage\_insights\_disabled = true   # Disable weekly insights (default)

Default: true (insights disabled to avoid spamming tenant administrators)

Note: While insights can provide governance visibility, they often generate excessive  
email volume. Consider enabling only for critical production environments or using  
alternative monitoring approaches.

See: https://learn.microsoft.com/power-platform/admin/managed-environment-usage-insights

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_deployment_validation"></a> [deployment\_validation](#output\_deployment\_validation)

Description: Comprehensive deployment validation and troubleshooting information for managed environment configuration

### <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id)

Description: The environment ID that was configured as a managed environment.

This output confirms which Power Platform environment was successfully  
configured with managed environment capabilities. Useful for:
- Validation in CI/CD pipelines
- Integration with other environment configurations
- Dependency management in complex deployments
- Audit and compliance reporting

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)

### <a name="output_managed_environment_id"></a> [managed\_environment\_id](#output\_managed\_environment\_id)

Description: The unique identifier of the managed environment configuration.

This output provides the primary key for referencing this managed environment  
in other Terraform configurations or external systems. Use this ID to:
- Reference in enterprise policy configurations
- Integrate with monitoring and reporting systems
- Set up advanced governance policies
- Configure environment-specific automation

Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)  
Note: This is the same as the environment\_id but confirms successful managed environment setup

### <a name="output_managed_environment_summary"></a> [managed\_environment\_summary](#output\_managed\_environment\_summary)

Description: Summary of deployed managed environment configuration for validation and compliance reporting

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this module.

### <a name="output_sharing_configuration"></a> [sharing\_configuration](#output\_sharing\_configuration)

Description: Current sharing configuration and limits for the managed environment.

This output provides visibility into the sharing controls that are currently  
active for the managed environment, useful for:
- Compliance auditing and reporting
- Integration with governance dashboards
- Validation of security posture
- Documentation of current policies

### <a name="output_solution_validation_status"></a> [solution\_validation\_status](#output\_solution\_validation\_status)

Description: Current solution validation and checker configuration for the managed environment.

This output provides visibility into the quality control measures that are  
currently active for solution imports, useful for:
- Quality assurance reporting
- Compliance verification
- Integration with ALM processes
- Validation of governance controls

## Modules

No modules.

## Authentication

This module requires authentication to Power Platform with appropriate permissions:

- **Environment Admin** role for the target environment
- **Power Platform Administrator** role for managed environment features
- **Premium licensing** for managed environment capabilities

## Data Collection

When using this configuration, Microsoft may collect usage data for:
- Environment governance and compliance reporting
- Solution validation and quality metrics
- Maker adoption and usage insights
- Administrative audit and security logs

## ⚠️ AVM Compliance

### Provider Exception

This module uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting resource IDs and computed attributes as discrete outputs
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Child Module**: Designed for composition and orchestration by pattern modules

## Troubleshooting

### Common Issues

**Issue**: "Environment does not support managed environment features"
**Solution**: Verify the environment has the required premium licensing and is not a developer environment.

**Issue**: "Invalid sharing configuration"
**Solution**: Ensure max\_limit\_user\_sharing is -1 when group sharing is enabled, or > 0 when disabled.

**Issue**: "Solution checker rule overrides not applied"
**Solution**: Verify rule names match the exact solution checker rule identifiers from Microsoft documentation.

### Performance Considerations

- Managed environment configuration changes may take several minutes to propagate
- Solution checker enforcement applies to future solution imports, not existing solutions
- Usage insights data is updated weekly, not in real-time

## Additional Links

- [Power Platform Managed Environments Documentation](https://learn.microsoft.com/power-platform/admin/managed-environment-overview)
- [Solution Checker Rule Reference](https://learn.microsoft.com/power-platform/admin/managed-environment-solution-checker)
- [Sharing Limits Configuration](https://learn.microsoft.com/power-platform/admin/managed-environment-sharing-limits)
- [Maker Welcome Content](https://learn.microsoft.com/power-platform/admin/welcome-content)

## Related Documentation

- [Environment Group Configuration](../res-environment-group/README.md) - Organize environments into logical groups
- [Environment Settings Configuration](../res-environment-settings/README.md) - Configure detailed environment behaviors
- [DLP Policy Configuration](../res-dlp-policy/README.md) - Implement data loss prevention policies
- [Pattern Environment Group](../ptn-environment-group/README.md) - Complete workspace orchestration
- [Power Platform Governance Guide](../../docs/guides/power-platform-governance.md) - Comprehensive governance strategy

---

\_This module is part of the PPCC25 Power Platform Governance demonstration repository, showcasing Infrastructure as Code best practices for Power Platform administration.\_
<!-- END_TF_DOCS -->