<!-- BEGIN_TF_DOCS -->
# Power Platform Environment Settings Configuration

This configuration manages Power Platform environment settings to control various aspects of Power Platform features and behaviors after environment creation, enabling standardized governance and compliance controls through Infrastructure as Code following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Key Features

- **Comprehensive Settings Management**: Four distinct configuration categories (audit, security, feature, email) with granular control
- **Advanced Security Controls**: IP-based firewall with audit mode, service principal access management, and network restrictions
- **Compliance Automation**: SOX, GDPR, and regulatory compliance support with configurable audit retention and logging levels
- **Environment-Specific Governance**: Template-driven configurations for different environment types (Dev, Test, Prod) with appropriate security levels
- **Network Security**: CIDR-based IP filtering, Azure service tag integration, and reverse proxy support

## Configuration Categories

### Audit & Compliance Settings
- **Plugin Trace Logging**: Debug level control (Off/Exception/All)
- **Comprehensive Auditing**: User access, read operations, and general audit logging
- **Retention Management**: Configurable log retention (31-24855 days or forever)
- **Regulatory Compliance**: Support for SOX, GDPR, and industry-specific requirements

### Security & Access Controls
- **Network Security**: IP-based firewall with audit mode for testing
- **Service Principal Integration**: Application user access for automation workflows
- **Azure Integration**: Microsoft trusted service tags for seamless connectivity
- **Zero-Trust Architecture**: Comprehensive access control and network restrictions

### Feature Management
- **Modern Development**: Power Apps Component Framework (PCF) enablement
- **User Experience**: Dashboard behavior and interface customization
- **Progressive Enhancement**: Feature rollout control across environments

### Email & File Handling
- **Upload Limits**: Configurable file size restrictions by environment type
- **Resource Management**: Prevent abuse while supporting business needs

## Use Cases

This configuration is designed for organizations that need to:

1. **Post-Environment Configuration Management**: Apply standardized governance settings to environments after creation, ensuring consistent security policies, feature controls, and compliance requirements across development, staging, and production environments
2. **Environment Settings Standardization**: Deploy consistent environment configuration policies across multiple Power Platform environments with automated validation and drift detection for governance compliance
3. **Automated Governance Controls**: Implement organization-wide governance policies through Infrastructure as Code, reducing manual configuration overhead and ensuring audit-ready compliance reporting
4. **Environment Lifecycle Management**: Complete the environment management lifecycle from creation through permission assignment to settings configuration, demonstrating end-to-end IaC governance patterns
5. **Compliance Automation**: Automate audit configuration and security controls to meet regulatory requirements (SOX, GDPR, industry-specific)
6. **Network Security Enforcement**: Implement IP-based firewall rules and access controls to protect environments from unauthorized access

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

## Environment-Specific Configuration Patterns

### Development Environment
```hcl
# Open access for development and testing
audit_settings = {
  plugin_trace_log_setting = "All"  # Full debugging
  is_audit_enabled         = false   # Minimal auditing
}

security_settings = {
  enable_ip_based_firewall_rule = false  # Open access
  allow_application_user_access = true   # Enable automation
}
```

### Production Environment
```hcl
# Strict security and comprehensive auditing
audit_settings = {
  plugin_trace_log_setting     = "Exception"  # Balanced logging
  is_audit_enabled             = true         # Full auditing
  is_user_access_audit_enabled = true         # Security monitoring
  log_retention_period_in_days = 365          # Compliance retention
}

security_settings = {
  enable_ip_based_firewall_rule        = true            # Enforce security
  allowed_ip_range_for_firewall        = ["10.0.0.0/8"]  # Corporate only
  enable_ip_based_firewall_rule_in_audit_mode = false    # Enforce mode
}
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

### <a name="input_environment_id"></a> [environment\_id](#input\_environment\_id)

Description: GUID of the Power Platform environment to configure with settings.

This is the primary identifier that links all environment settings to the  
specific Power Platform environment instance.

Example:  
environment\_id = "12345678-1234-1234-1234-123456789012"

Requirements:
- Must be a valid GUID format for Power Platform compatibility
- Environment must exist before applying settings
- User must have Environment Admin privileges for the specified environment

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_audit_settings"></a> [audit\_settings](#input\_audit\_settings)

Description: Audit and logging configuration for compliance tracking and monitoring.

When provided, enables comprehensive audit capabilities for the Power Platform  
environment to support governance, compliance, and security monitoring requirements.

Properties:
- plugin\_trace\_log\_setting: Plugin trace level for debugging ("Off", "Exception", "All")
- is\_audit\_enabled: Enable general auditing for environment operations
- is\_user\_access\_audit\_enabled: Enable user access auditing for security monitoring
- is\_read\_audit\_enabled: Enable read operation auditing (high volume, use carefully)
- log\_retention\_period\_in\_days: Audit log retention period (31-24855 days, -1 for forever)

Example:  
audit\_settings = {  
  plugin\_trace\_log\_setting     = "Exception"  
  is\_audit\_enabled             = true  
  is\_user\_access\_audit\_enabled = true  
  is\_read\_audit\_enabled        = false  
  log\_retention\_period\_in\_days = 90
}

Compliance Benefits:
- Supports SOX, GDPR, and other regulatory requirements
- Enables security incident investigation and forensics
- Provides audit trail for environment configuration changes
- Facilitates compliance reporting and evidence collection

Type:

```hcl
object({
    # Plugin trace configuration for debugging and monitoring
    plugin_trace_log_setting = optional(string)

    # Comprehensive audit configuration for compliance
    is_audit_enabled             = optional(bool)
    is_user_access_audit_enabled = optional(bool)
    is_read_audit_enabled        = optional(bool)
    log_retention_period_in_days = optional(number)
  })
```

Default: `null`

### <a name="input_email_settings"></a> [email\_settings](#input\_email\_settings)

Description: Email and file handling configuration for Power Platform environment.

Controls file upload limits and email-related settings to ensure proper  
resource utilization and prevent abuse while supporting legitimate business needs.

Properties:
- max\_upload\_file\_size\_in\_bytes: Maximum file upload size in bytes (1 to 131,072,000 bytes / 125 MB)

Example:  
email\_settings = {  
  max\_upload\_file\_size\_in\_bytes = 52428800  # 50 MB limit
}

Business Benefits:
- Prevents excessive storage consumption from large file uploads
- Ensures consistent file size policies across environments
- Supports compliance with data governance policies
- Optimizes environment performance and resource utilization

Type:

```hcl
object({
    max_upload_file_size_in_bytes = optional(number)
  })
```

Default: `null`

### <a name="input_feature_settings"></a> [feature\_settings](#input\_feature\_settings)

Description: Power Platform feature enablement and user interface behavior configuration.

Controls advanced Power Platform features and user experience settings to optimize  
the environment for specific organizational needs and user preferences.

Properties:
- power\_apps\_component\_framework\_for\_canvas\_apps: Enable Power Apps Component Framework (PCF) for canvas apps
- show\_dashboard\_cards\_in\_expanded\_state: Display dashboard cards in expanded state by default

Example:  
feature\_settings = {  
  power\_apps\_component\_framework\_for\_canvas\_apps = true  
  show\_dashboard\_cards\_in\_expanded\_state         = false
}

Feature Benefits:
- PCF enables advanced custom components in canvas apps
- Dashboard settings improve user experience and productivity
- Provides consistent user interface behavior across the organization
- Supports modern app development patterns and best practices

Type:

```hcl
object({
    # Power Apps component framework
    power_apps_component_framework_for_canvas_apps = optional(bool)

    # User interface behaviors
    show_dashboard_cards_in_expanded_state = optional(bool)
  })
```

Default: `null`

### <a name="input_security_settings"></a> [security\_settings](#input\_security\_settings)

Description: Security and access control configuration for Power Platform environment protection.

⚠️  IMPORTANT LIMITATION: IP firewall settings are currently commented out in the resource  
due to Power Platform limitation where standard environments cannot have IP firewall rules.  
Only managed environments support IP firewall functionality.

PLATFORM DELAY: This limitation currently prevents seamless deployment of IP firewall rules.  
The settings are preserved in the variable definition for future use when:  
1. Power Platform adds support for IP firewall rules in standard environments, OR  
2. When using managed environments instead of standard environments

Currently Active Properties:
- allow\_application\_user\_access: Allow service principal (application) access to environment
- allow\_microsoft\_trusted\_service\_tags: Allow Microsoft trusted service tags for connectivity
- reverse\_proxy\_ip\_addresses: IP addresses of reverse proxy servers for proper client identification

Currently Inactive Properties (preserved for future use):
- enable\_ip\_based\_firewall\_rule: Enable IP-based firewall for network access control
- enable\_ip\_based\_firewall\_rule\_in\_audit\_mode: Enable firewall in audit mode (log only)
- allowed\_ip\_range\_for\_firewall: Permitted IP ranges in CIDR format (e.g., "10.0.0.0/8")
- allowed\_service\_tags\_for\_firewall: Permitted Azure service tags (e.g., "ApiManagement")

Example (current working configuration):  
security\_settings = {  
  allow\_application\_user\_access        = true  
  allow\_microsoft\_trusted\_service\_tags = true  
  reverse\_proxy\_ip\_addresses          = ["10.0.1.100", "10.0.1.101"]
}

Example (future configuration when IP firewall is supported):  
security\_settings = {  
  allow\_application\_user\_access        = true  
  allow\_microsoft\_trusted\_service\_tags = true  
  enable\_ip\_based\_firewall\_rule        = true  
  allowed\_ip\_range\_for\_firewall        = ["10.0.0.0/8", "192.168.1.0/24"]  
  allowed\_service\_tags\_for\_firewall    = ["ApiManagement", "PowerPlatformPlex"]
}

Type:

```hcl
object({
    # Application access controls
    allow_application_user_access        = optional(bool)
    allow_microsoft_trusted_service_tags = optional(bool)

    # Network security and firewall configuration
    # NOTE: IP firewall settings currently commented out in main.tf due to Power Platform limitation
    # Standard environments cannot have IP firewall rules - only managed environments support this
    enable_ip_based_firewall_rule               = optional(bool)
    enable_ip_based_firewall_rule_in_audit_mode = optional(bool)
    allowed_ip_range_for_firewall               = optional(set(string))
    allowed_service_tags_for_firewall           = optional(set(string))
    reverse_proxy_ip_addresses                  = optional(set(string))
  })
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_applied_settings_summary"></a> [applied\_settings\_summary](#output\_applied\_settings\_summary)

Description: Summary of applied environment settings for validation and compliance reporting.

This output provides a consolidated view of the settings that were successfully  
applied to the environment, including which categories were configured and  
their high-level status. Useful for governance dashboards and audit reports.

### <a name="output_audit_settings_applied"></a> [audit\_settings\_applied](#output\_audit\_settings\_applied)

Description: Confirmation of audit settings application with details

### <a name="output_email_settings_applied"></a> [email\_settings\_applied](#output\_email\_settings\_applied)

Description: Confirmation of email settings application with details

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

### <a name="output_feature_settings_applied"></a> [feature\_settings\_applied](#output\_feature\_settings\_applied)

Description: Confirmation of feature settings application with details

### <a name="output_security_settings_applied"></a> [security\_settings\_applied](#output\_security\_settings\_applied)

Description: Confirmation of security settings application with details

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

### Service Principal Permission Requirements

Environment settings management requires **System Administrator** or **Environment Admin** permissions in the target Power Platform environment. The service principal must have appropriate permissions assigned via:

- **Automated Assignment**: Use `res-environment-application-admin` configuration for Infrastructure as Code permission management
- **Manual Assignment**: Run the permission assignment script: `./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve`
- **Admin Center**: Manually assign permissions through Power Platform Admin Center

**Prerequisites Script:**
```bash
# Assign service principal as System Administrator on target environment
./scripts/utils/assign-sp-power-platform-envs.sh --environment "<environment-id>" --auto-approve
```

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