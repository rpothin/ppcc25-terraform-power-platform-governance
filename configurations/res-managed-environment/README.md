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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.5.0 |
| <a name="requirement_powerplatform"></a> [powerplatform](#requirement_powerplatform) | ~> 3.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_powerplatform"></a> [powerplatform](#provider_powerplatform) | ~> 3.8 |

## Resources

| Name | Type |
|------|------|
| [powerplatform_managed_environment.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment_id"></a> [environment_id](#input_environment_id) | GUID of the Power Platform environment to configure as a managed environment.<br/><br/>This is the primary identifier that links managed environment capabilities to the<br/>specific Power Platform environment instance.<br/><br/>Example:<br/>environment_id = "12345678-1234-1234-1234-123456789012"<br/><br/>Requirements:<br/>- Must be a valid GUID format for Power Platform compatibility<br/>- Environment must exist before applying managed environment settings<br/>- User must have Environment Admin privileges for the specified environment<br/>- Environment must support managed environment capabilities (premium licensing required) | `string` | n/a | yes |
| <a name="input_maker_onboarding"></a> [maker_onboarding](#input_maker_onboarding) | Maker onboarding configuration to provide guidance and resources for new Power Platform makers.<br/><br/>This configuration enables administrators to provide customized welcome content and<br/>learning resources that appear when makers first access Power Apps Studio in this environment.<br/><br/>Properties:<br/>- markdown_content: Rich text content displayed in Power Apps Studio (supports markdown)<br/>- learn_more_url: URL for additional documentation, training, or support resources<br/><br/>Example:<br/>maker_onboarding = {<br/>  markdown_content = "## Welcome to Our Power Platform Environment\\n\\nPlease review our development guidelines before creating apps."<br/>  learn_more_url   = "https://company.com/power-platform-guidance"<br/>}<br/><br/>Default Configuration:<br/>- Provides basic welcome message with governance reminder<br/>- Links to official Microsoft Power Platform documentation<br/>- Can be customized for organization-specific guidance<br/><br/>Note: While maker onboarding can provide value, many organizations prefer to handle<br/>user guidance through separate training programs and documentation systems.<br/><br/>Validation Rules:<br/>- markdown_content must not be empty<br/>- learn_more_url must be a valid HTTPS URL for security<br/>- Content should follow organizational guidelines and branding<br/><br/>See: https://learn.microsoft.com/power-platform/admin/welcome-content | <pre>object({<br/>    # Markdown content displayed to first-time makers in Power Apps Studio<br/>    markdown_content = string<br/><br/>    # URL for additional maker resources and guidance<br/>    learn_more_url = string<br/>  })</pre> | <pre>{<br/>  "learn_more_url": "https://learn.microsoft.com/power-platform/",<br/>  "markdown_content": "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions."<br/>}</pre> | no |
| <a name="input_sharing_settings"></a> [sharing_settings](#input_sharing_settings) | Canvas app sharing controls and limitations for the managed environment.<br/><br/>This configuration manages how widely canvas apps can be shared within the organization,<br/>providing governance controls to prevent data exposure and maintain compliance.<br/><br/>Properties:<br/>- is_group_sharing_disabled: Prevents sharing with security groups when true<br/>- limit_sharing_mode: Controls sharing scope ("No limit", "Exclude sharing with security groups")<br/>- max_limit_user_sharing: Maximum users for individual sharing (-1 if group sharing enabled)<br/><br/>Example:<br/>sharing_settings = {<br/>  is_group_sharing_disabled = false<br/>  limit_sharing_mode        = "No limit"<br/>  max_limit_user_sharing    = -1<br/>}<br/><br/>Default Configuration (Governance Best Practice):<br/>- Enables group sharing (is_group_sharing_disabled = false)<br/>- Allows unrestricted sharing (limit_sharing_mode = "No limit")<br/>- Sets unlimited user sharing (max_limit_user_sharing = -1)<br/>- Encourages security group usage over individual user sharing<br/><br/>Validation Rules:<br/>- If group sharing is disabled, max_limit_user_sharing must be > 0<br/>- If group sharing is enabled, max_limit_user_sharing should be -1<br/>- limit_sharing_mode must be a valid sharing mode value<br/><br/>See: https://learn.microsoft.com/power-platform/admin/managed-environment-sharing-limits | <pre>object({<br/>    # Control canvas app sharing across the organization<br/>    is_group_sharing_disabled = bool<br/><br/>    # Define sharing scope and limitations  <br/>    limit_sharing_mode = string<br/><br/>    # Maximum number of users for sharing (use -1 if group sharing is enabled)<br/>    max_limit_user_sharing = number<br/>  })</pre> | <pre>{<br/>  "is_group_sharing_disabled": false,<br/>  "limit_sharing_mode": "No limit",<br/>  "max_limit_user_sharing": -1<br/>}</pre> | no |
| <a name="input_solution_checker"></a> [solution_checker](#input_solution_checker) | Solution checker configuration for automated validation and quality control.<br/><br/>This configuration enables automatic verification of solution checker results for<br/>security and reliability issues before solution import, supporting governance<br/>and compliance requirements.<br/><br/>Properties:<br/>- mode: Validation enforcement level (None, Warn, Block)<br/>- suppress_validation_emails: When true, only sends emails for blocked solutions<br/>- rule_overrides: Set of solution checker rules to override/disable<br/><br/>Example:<br/>solution_checker = {<br/>  mode                      = "Warn"<br/>  suppress_validation_emails = true<br/>  rule_overrides            = ["meta-avoid-reg-no-attribute", "app-use-delayoutput-text-input"]<br/>}<br/><br/>Default Configuration (Balanced Governance):<br/>- Uses "Warn" mode for validation without blocking imports<br/>- Suppresses validation emails to reduce noise<br/>- No rule overrides (full validation suite)<br/><br/>Validation Rules:<br/>- mode must be one of: None, Warn, Block<br/>- rule_overrides must contain valid solution checker rule names<br/><br/>See: https://learn.microsoft.com/power-platform/admin/managed-environment-solution-checker | <pre>object({<br/>    # Solution validation mode for imports<br/>    mode = string<br/><br/>    # Email notification settings for validation results<br/>    suppress_validation_emails = bool<br/><br/>    # Override specific solution checker rules<br/>    rule_overrides = optional(set(string), [])<br/>  })</pre> | <pre>{<br/>  "mode": "Warn",<br/>  "rule_overrides": [],<br/>  "suppress_validation_emails": true<br/>}</pre> | no |
| <a name="input_usage_insights_disabled"></a> [usage_insights_disabled](#input_usage_insights_disabled) | Controls whether weekly usage insights digest is disabled for the managed environment.<br/><br/>When set to false, administrators receive weekly email digests with usage<br/>insights for the environment. When set to true (default), these insights are disabled.<br/><br/>Example:<br/>usage_insights_disabled = false  # Enable weekly insights<br/>usage_insights_disabled = true   # Disable weekly insights (default)<br/><br/>Default: true (insights disabled to avoid spamming tenant administrators)<br/><br/>Note: While insights can provide governance visibility, they often generate excessive<br/>email volume. Consider enabling only for critical production environments or using<br/>alternative monitoring approaches.<br/><br/>See: https://learn.microsoft.com/power-platform/admin/managed-environment-usage-insights | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment_id"></a> [environment_id](#output_environment_id) | The environment ID that was configured as a managed environment.<br/><br/>This output confirms which Power Platform environment was successfully<br/>configured with managed environment capabilities. Useful for:<br/>- Validation in CI/CD pipelines<br/>- Integration with other environment configurations<br/>- Dependency management in complex deployments<br/>- Audit and compliance reporting<br/><br/>Format: GUID (e.g., 12345678-1234-1234-1234-123456789012) |
| <a name="output_managed_environment_id"></a> [managed_environment_id](#output_managed_environment_id) | The unique identifier of the managed environment configuration.<br/><br/>This output provides the primary key for referencing this managed environment<br/>in other Terraform configurations or external systems. Use this ID to:<br/>- Reference in enterprise policy configurations<br/>- Integrate with monitoring and reporting systems<br/>- Set up advanced governance policies<br/>- Configure environment-specific automation<br/><br/>Format: GUID (e.g., 12345678-1234-1234-1234-123456789012)<br/>Note: This is the same as the environment_id but confirms successful managed environment setup |
| <a name="output_managed_environment_summary"></a> [managed_environment_summary](#output_managed_environment_summary) | Summary of deployed managed environment configuration for validation and compliance reporting |
| <a name="output_output_schema_version"></a> [output_schema_version](#output_output_schema_version) | The version of the output schema for this module. |
| <a name="output_sharing_configuration"></a> [sharing_configuration](#output_sharing_configuration) | Current sharing configuration and limits for the managed environment.<br/><br/>This output provides visibility into the sharing controls that are currently<br/>active for the managed environment, useful for:<br/>- Compliance auditing and reporting<br/>- Integration with governance dashboards<br/>- Validation of security posture<br/>- Documentation of current policies |
| <a name="output_solution_validation_status"></a> [solution_validation_status](#output_solution_validation_status) | Current solution validation and checker configuration for the managed environment.<br/><br/>This output provides visibility into the quality control measures that are<br/>currently active for solution imports, useful for:<br/>- Quality assurance reporting<br/>- Compliance verification<br/>- Integration with ALM processes<br/>- Validation of governance controls |

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
**Solution**: Ensure max_limit_user_sharing is -1 when group sharing is enabled, or > 0 when disabled.

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

_This module is part of the PPCC25 Power Platform Governance demonstration repository, showcasing Infrastructure as Code best practices for Power Platform administration._
<!-- END_TF_DOCS -->