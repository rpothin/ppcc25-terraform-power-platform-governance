<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Group Rule Set Configuration

This configuration creates and manages Power Platform Environment Group Rule Sets for applying consistent governance policies across environments within a group following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Centralized Governance**: Apply consistent policies and rules across multiple environments within an environment group, ensuring standardized governance without manual configuration of each environment
2. **Sharing Control**: Enforce sharing limits and modes for apps and flows within environment groups to maintain security boundaries and prevent unauthorized access
3. **Solution Quality**: Implement solution checker enforcement to maintain code quality standards and prevent deployment of solutions that don't meet organizational requirements
4. **Backup Management**: Configure standardized backup retention policies across environments to ensure data protection and compliance with organizational retention requirements
5. **AI Governance**: Control AI features and data movement settings consistently across environments to meet compliance requirements and organizational AI policies

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment-group-rule-set'
  tfvars-file: 'environment_group_id = "12345678-1234-1234-1234-123456789012"
    rules = {
      sharing_controls = {
        share_mode = "exclude sharing with security groups"
        share_max_limit = 25
      }
      solution_checker_enforcement = {
        solution_checker_mode = "block"
        send_emails_enabled = true
      }
    }'
```

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) | ~> 3.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) | ~> 3.8 |

## Resources

| Name | Type |
|------|------|
| [powerplatform_environment_group_rule_set.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_group_rule_set) | resource |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment_group_id"></a> [environment\_group\_id](#input\_environment\_group\_id) | Unique identifier of the Power Platform Environment Group to apply rules to.<br/><br/>This GUID identifies the target environment group where governance rules will be<br/>applied. The environment group must already exist and be accessible with current<br/>authentication permissions.<br/><br/>Example: "12345678-1234-1234-1234-123456789012"<br/><br/>Validation Rules:<br/>- Must be a valid GUID format (32 hexadecimal digits in 8-4-4-4-12 pattern)<br/>- Cannot be empty or contain only whitespace characters<br/>- Must reference an existing environment group in the tenant<br/><br/>Integration Requirements:<br/>- Environment group must exist (created via res-environment-group or manually)<br/>- Must have appropriate permissions to modify group rules<br/>- Rules will be published automatically upon successful application | `string` | n/a | yes |
| <a name="input_rules"></a> [rules](#input\_rules) | Comprehensive rule configuration for the environment group governance.<br/><br/>This object defines all available governance rules that can be applied to environments<br/>within the group. Each rule type controls specific aspects of environment behavior<br/>and enforces organizational policies consistently across environments.<br/><br/>Rule Categories:<br/>- sharing\_controls: Controls app and flow sharing within the group<br/>- usage\_insights: Enables usage analytics and reporting<br/>- maker\_welcome\_content: Customizes onboarding experience for makers<br/>- solution\_checker\_enforcement: Enforces solution quality standards<br/>- backup\_retention: Manages backup retention policies<br/>- ai\_generated\_descriptions: Controls AI-generated content features<br/>- ai\_generative\_settings: Manages AI capabilities and data movement<br/><br/>Example:<br/>rules = {<br/>  sharing\_controls = {<br/>    share\_mode      = "exclude sharing with security groups"<br/>    share\_max\_limit = 25<br/>  }<br/>  usage\_insights = {<br/>    insights\_enabled = true<br/>  }<br/>  solution\_checker\_enforcement = {<br/>    solution\_checker\_mode = "block"<br/>    send\_emails\_enabled   = true<br/>  }<br/>  backup\_retention = {<br/>    period\_in\_days = 21<br/>  }<br/>  ai\_generative\_settings = {<br/>    move\_data\_across\_regions\_enabled = false<br/>    bing\_search\_enabled              = true<br/>  }<br/>}<br/><br/>Validation Rules:<br/>- sharing\_controls.share\_mode: Must be valid sharing mode string<br/>- sharing\_controls.share\_max\_limit: Must be positive integer<br/>- backup\_retention.period\_in\_days: Must be 7, 14, 21, or 28 days<br/>- solution\_checker\_enforcement.solution\_checker\_mode: Must be "block" or "audit"<br/>- All boolean values must be explicitly set (no implicit conversions) | <pre>object({<br/>    sharing_controls = optional(object({<br/>      share_mode      = optional(string, "exclude sharing with security groups")<br/>      share_max_limit = optional(number, 10)<br/>    }))<br/>    usage_insights = optional(object({<br/>      insights_enabled = optional(bool, false)<br/>    }))<br/>    maker_welcome_content = optional(object({<br/>      maker_onboarding_url      = string<br/>      maker_onboarding_markdown = string<br/>    }))<br/>    solution_checker_enforcement = optional(object({<br/>      solution_checker_mode = optional(string, "block")<br/>      send_emails_enabled   = optional(bool, true)<br/>    }))<br/>    backup_retention = optional(object({<br/>      period_in_days = number<br/>    }))<br/>    ai_generated_descriptions = optional(object({<br/>      ai_description_enabled = optional(bool, false)<br/>    }))<br/>    ai_generative_settings = optional(object({<br/>      move_data_across_regions_enabled = optional(bool, false)<br/>      bing_search_enabled              = optional(bool, false)<br/>    }))<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment_group_id"></a> [environment\_group\_id](#output\_environment\_group\_id) | The environment group ID that this rule set is applied to.<br/><br/>This output provides the target environment group identifier for validation<br/>and integration purposes. Useful for:<br/>- Confirming successful deployment to the correct group<br/>- Integration with environment group management workflows<br/>- Validation in CI/CD pipelines<br/>- Cross-reference with environment routing configurations |
| <a name="output_environment_group_rule_set_id"></a> [environment\_group\_rule\_set\_id](#output\_environment\_group\_rule\_set\_id) | The unique identifier of the created Power Platform Environment Group Rule Set.<br/><br/>This output provides the primary key for referencing this rule set in other<br/>Terraform configurations or external systems. Use this ID to:<br/>- Reference the rule set in monitoring and compliance systems<br/>- Integrate with governance reporting workflows<br/>- Coordinate with environment management automations<br/>- Track rule set deployment status and configuration<br/><br/>Format: GUID (e.g., 12345678-1234-1234-1234-123456789012) |
| <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version) | The version of the output schema for this module. |
| <a name="output_rule_set_configuration_summary"></a> [rule\_set\_configuration\_summary](#output\_rule\_set\_configuration\_summary) | Summary of deployed environment group rule set configuration for validation and compliance reporting |

## Modules

No modules.

## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role or Environment Admin role for the target environment group
- **State Backend**: Azure Storage with OIDC authentication

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and is only accessible through your authenticated Terraform execution environment.

## ⚠️ AVM Compliance

### Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting rule set IDs and computed attributes as discrete outputs
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Resource Deployment**: Deploys primary Power Platform environment group rule set resources following WAF best practices

## Troubleshooting

### Common Issues

1. **Environment Group Not Found**: Ensure the environment group ID exists and is accessible with your current permissions
2. **Permission Denied**: Verify you have Power Platform Service Admin or appropriate Environment Admin permissions
3. **Rule Conflicts**: Check if rules are already configured at the environment level that conflict with group rules
4. **Validation Errors**: Review variable validation messages for specific guidance on acceptable values

### Provider Limitations

- This resource is available as **preview** and may have limited functionality
- Service principal authentication is not supported for this resource
- Manual changes in the admin center may cause drift (use lifecycle ignore_changes)

## Additional Links

- [Power Platform Environment Group Rule Set Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_group_rule_set)
- [Power Platform Environment Groups Documentation](https://learn.microsoft.com/power-platform/admin/environment-groups)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END\_TF\_DOCS -->
<!-- END_TF_DOCS -->