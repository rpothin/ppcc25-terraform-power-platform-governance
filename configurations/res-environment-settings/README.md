<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Settings Configuration

This configuration manages Power Platform environment settings to control various aspects of Power Platform features and behaviors after environment creation, enabling standardized governance and compliance controls through Infrastructure as Code following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Post-Environment Configuration Management**: Apply standardized governance settings to environments after creation, ensuring consistent security policies, feature controls, and compliance requirements across development, staging, and production environments
2. **Environment Settings Standardization**: Deploy consistent environment configuration policies across multiple Power Platform environments with automated validation and drift detection for governance compliance
3. **Automated Governance Controls**: Implement organization-wide governance policies through Infrastructure as Code, reducing manual configuration overhead and ensuring audit-ready compliance reporting
4. **Environment Lifecycle Management**: Complete the environment management lifecycle from creation through permission assignment to settings configuration, demonstrating end-to-end IaC governance patterns

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment-settings'
  tfvars-file: 'environment_settings = {
    environment_id = "12345678-1234-1234-1234-123456789012"
    settings = {
      # Environment-specific settings configuration
    }
  }'
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [powerplatform_environment_settings.this](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_settings) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_environment_settings_config"></a> [environment\_settings\_config](#input\_environment\_settings\_config)

Description: Comprehensive configuration object for Power Platform environment settings.

This variable consolidates all environment settings to reduce complexity while  
ensuring proper governance and compliance controls are applied consistently.

Required Properties:
- environment\_id: GUID of the Power Platform environment to configure

Optional Properties:
- audit\_and\_logs: Audit and logging configuration for compliance tracking
  - plugin\_trace\_log\_setting: Plugin trace level ("Off", "Exception", "All")
  - audit\_settings: Detailed audit configuration
    - is\_audit\_enabled: Enable general auditing
    - is\_user\_access\_audit\_enabled: Enable user access auditing
    - is\_read\_audit\_enabled: Enable read operation auditing  
    - log\_retention\_period\_in\_days: Log retention (31-24855 days, -1 for forever)

- email\_settings: Email and file handling configuration
  - email\_settings: Email-specific settings
    - max\_upload\_file\_size\_in\_bytes: Maximum file upload size in bytes

- product\_settings: Power Platform feature and behavior controls
  - behavior\_settings: User interface behaviors
    - show\_dashboard\_cards\_in\_expanded\_state: Dashboard card display preference
  - features: Power Platform feature enablement
    - power\_apps\_component\_framework\_for\_canvas\_apps: Enable PCF for canvas apps
  - security: Access control and network protection
    - allow\_application\_user\_access: Allow service principal access
    - allow\_microsoft\_trusted\_service\_tags: Allow Microsoft service tags
    - allowed\_ip\_range\_for\_firewall: Permitted IP ranges for firewall
    - allowed\_service\_tags\_for\_firewall: Permitted service tags for firewall
    - enable\_ip\_based\_firewall\_rule: Enable IP-based firewall
    - enable\_ip\_based\_firewall\_rule\_in\_audit\_mode: Enable firewall audit mode
    - reverse\_proxy\_ip\_addresses: Reverse proxy IP addresses

Example:  
environment\_settings\_config = {  
  environment\_id = "12345678-1234-1234-1234-123456789012"  
  audit\_and\_logs = {  
    plugin\_trace\_log\_setting = "Exception"  
    audit\_settings = {  
      is\_audit\_enabled             = true  
      is\_user\_access\_audit\_enabled = true  
      is\_read\_audit\_enabled        = false  
      log\_retention\_period\_in\_days = 90
    }
  }  
  product\_settings = {  
    security = {  
      allow\_application\_user\_access     = true  
      enable\_ip\_based\_firewall\_rule     = true  
      allowed\_ip\_range\_for\_firewall     = ["10.0.0.0/8", "192.168.1.0/24"]  
      allowed\_service\_tags\_for\_firewall = ["ApiManagement"]
    }
  }
}

Validation Rules:
- Environment ID must be a valid GUID format for Power Platform compatibility
- Plugin trace log setting must be valid option if specified
- Log retention period must be within Power Platform limits
- IP ranges and service tags must follow Azure networking standards
- File size limits must be within Power Platform constraints

Type:

```hcl
object({
    # Required: Environment identifier for settings application
    environment_id = string

    # Optional: Audit and logging configuration for compliance tracking
    audit_and_logs = optional(object({
      plugin_trace_log_setting = optional(string)
      audit_settings = optional(object({
        is_audit_enabled             = optional(bool)
        is_user_access_audit_enabled = optional(bool)
        is_read_audit_enabled        = optional(bool)
        log_retention_period_in_days = optional(number)
      }))
    }))

    # Optional: Email configuration for file handling
    email_settings = optional(object({
      email_settings = optional(object({
        max_upload_file_size_in_bytes = optional(number)
      }))
    }))

    # Optional: Product-specific settings for Power Platform features
    product_settings = optional(object({
      behavior_settings = optional(object({
        show_dashboard_cards_in_expanded_state = optional(bool)
      }))
      features = optional(object({
        power_apps_component_framework_for_canvas_apps = optional(bool)
      }))
      security = optional(object({
        allow_application_user_access               = optional(bool)
        allow_microsoft_trusted_service_tags        = optional(bool)
        allowed_ip_range_for_firewall               = optional(set(string))
        allowed_service_tags_for_firewall           = optional(set(string))
        enable_ip_based_firewall_rule               = optional(bool)
        enable_ip_based_firewall_rule_in_audit_mode = optional(bool)
        reverse_proxy_ip_addresses                  = optional(set(string))
      }))
    }))
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_applied_settings_summary"></a> [applied\_settings\_summary](#output\_applied\_settings\_summary)

Description: Summary of applied environment settings for validation and compliance reporting.

This output provides a consolidated view of the settings that were successfully  
applied to the environment, including which categories were configured and  
their high-level status. Useful for governance dashboards and audit reports.

### <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id)

Description: The Power Platform environment ID where settings were applied.

This output confirms which environment received the settings configuration,  
useful for validation and linking with other environment-related resources  
like res-environment and res-environment-application-admin configurations.

### <a name="output_environment_settings_id"></a> [environment\_settings\_id](#output\_environment\_settings\_id)

Description: The unique identifier of the environment settings configuration.

This output provides the primary key for referencing this environment settings  
configuration in other Terraform configurations or external systems. This ID  
represents the computed identifier for the settings applied to the environment.

### <a name="output_settings_configuration_summary"></a> [settings\_configuration\_summary](#output\_settings\_configuration\_summary)

Description: Detailed summary of environment settings configuration for operational teams.

This output provides operational visibility into the specific settings categories  
that were configured, enabling support teams to understand the environment's  
governance posture and troubleshoot configuration-related issues.

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

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting environment settings IDs and computed attributes as discrete outputs
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
- Verify admin permissions for Requires System Administrator or Environment Admin permissions in the target Power Platform environment. Service principal must have appropriate permissions assigned via res-environment-application-admin configuration or manual assignment. management
- Check for tenant-level restrictions on automation

Common issues include insufficient permissions for environment settings modification, configuration drift from manual admin center changes, and settings conflicts with existing environment policies. Verify service principal permissions and environment admin access before applying configuration.

## Additional Links

- [Power Platform Environment Settings Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment_settings)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->