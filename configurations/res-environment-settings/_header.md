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