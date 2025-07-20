# DLP Policies Export Configuration

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

## ⚠️ AVM Compliance Notice

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements. This is necessary because Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Compliance Status**: 85% (Provider Exception)  
**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)  
**Quality Standards**: Equivalent to full AVM modules  
**TFFR2 Compliance**: ✅ Implements anti-corruption layer in outputs

## Purpose

This configuration demonstrates how to export current Data Loss Prevention policies from Power Platform for migration planning. It serves as a reference for creating single-purpose Terraform configurations that target specific data sources while following AVM best practices.

**Key Features:**
- **AVM-Inspired Structure**: Follows AVM patterns where technically feasible
- **Anti-Corruption Layer**: Outputs discrete attributes instead of complete resource objects
- **Security-First**: Sensitive data properly marked and segregated
- **Migration Ready**: Structured output for analysis and migration planning

## Data Source

**Data Loss Prevention Policies** (`powerplatform_data_loss_prevention_policies`)
- Fetches all DLP policies in the tenant
- Includes policy metadata, connector classifications, and environment assignments
- Provides structured policy configuration for migration analysis
- Uses anti-corruption layer to expose only necessary attributes

## Usage with Terraform Output Workflow

This configuration is used with the Terraform Output workflow to:

1. **Execute Data Source Query**: Run Terraform to query current DLP policies
2. **Generate Structured Output**: Export policy data using discrete attributes
3. **Store for Analysis**: Save output for migration planning and comparison

### Workflow Usage

```yaml
# In the Terraform Output workflow
inputs:
  configuration: '01-dlp-policies'  # Uses this DLP policies configuration
```

## Output Format

The workflow produces a JSON file with this structure (using anti-corruption layer pattern):

```json
{
  "output_metadata": {
    "timestamp": "20250720-143022",
    "configuration": "01-dlp-policies",
    "exported_by": "GitHub Actions",
    "workflow_run": "123"
  },
  "outputs": {
    "dlp_policies": {
      "value": {
        "policy_count": 3,
        "policy_ids": [
          "policy-guid-1",
          "policy-guid-2",
          "policy-guid-3"
        ],
        "policy_names": [
          "Corporate DLP Policy",
          "Finance Department Policy", 
          "HR Department Policy"
        ],
        "environment_types": [
          "AllEnvironments",
          "ExceptDefaultEnvironmentType", 
          "OnlyDefaultEnvironmentType"
        ],
        "created_by": [
          "admin@company.com",
          "finance-admin@company.com",
          "hr-admin@company.com"
        ],
        "last_modified_time": [
          "2024-01-15T10:30:00Z",
          "2024-03-20T14:45:00Z",
          "2024-02-10T09:15:00Z"
        ]
      }
    },
    "dlp_policies_sensitive": {
      "sensitive": true,
      "value": {
        "connector_configurations": [
          {
            "policy_id": "policy-guid-1",
            "policy_name": "Corporate DLP Policy",
            "business_connectors_count": 15,
            "non_business_connectors_count": 8,
            "blocked_connectors_count": 150,
            "default_classification": "General"
          }
        ]
      }
    }
  }
}
```

### Key Output Improvements

**✅ AVM TFFR2 Compliance:**
- **Anti-corruption layer**: Discrete attributes instead of complete resource objects
- **Security**: Sensitive connector details marked as sensitive
- **Schema independence**: No exposure to provider schema changes
- **Selective exposure**: Only necessary attributes exposed

**✅ Benefits:**
- **Reduced data size**: From 17,000+ lines to essential attributes only
- **Enhanced security**: Sensitive connector details properly protected
- **Better usability**: Clear, structured data for analysis
- **Future-proof**: Insulated from provider schema changes

## Migration Use Cases

### 1. Policy Inventory
- **Current State Analysis**: Understanding existing DLP policies
- **Coverage Assessment**: Identifying which environments have policies
- **Connector Classification**: Reviewing how connectors are classified

### 2. Migration Planning
- **Policy Comparison**: Comparing manual vs. IaC-managed policies
- **Configuration Gaps**: Identifying missing or inconsistent settings
- **Rollout Strategy**: Planning incremental IaC adoption

### 3. Compliance Documentation
- **Policy Documentation**: Generating policy documentation
- **Audit Trail**: Maintaining records of policy changes
- **Regulatory Compliance**: Supporting compliance requirements

## Creating Similar Configurations

To create configurations for other data sources:

### 1. Environments Export
```hcl
data "powerplatform_environments" "current" {}

output "environments" {
  description = "Current Power Platform environments summary"
  value = {
    environment_count = length(data.powerplatform_environments.current.environments)
    environment_ids   = [for env in data.powerplatform_environments.current.environments : env.id]
    environment_names = [for env in data.powerplatform_environments.current.environments : env.display_name]
    environment_types = [for env in data.powerplatform_environments.current.environments : env.environment_type]
  }
  sensitive = false
}
```

### 2. Tenant Settings Export
```hcl
data "powerplatform_tenant_settings" "current" {}

output "tenant_settings" {
  description = "Current tenant settings summary"
  value = {
    walk_me_opt_out                = data.powerplatform_tenant_settings.current.walk_me_opt_out
    disable_copilot               = data.powerplatform_tenant_settings.current.disable_copilot
    disable_community_url         = data.powerplatform_tenant_settings.current.disable_community_url
    disable_support_tickets_visible_by_all_users = data.powerplatform_tenant_settings.current.disable_support_tickets_visible_by_all_users
  }
  sensitive = false
}
```

## Best Practices for AVM-Inspired Configurations

1. **Anti-Corruption Layer**: Always use discrete outputs instead of complete resource objects
2. **Sensitive Data Handling**: Mark sensitive outputs appropriately
3. **Clear Documentation**: Document output structure and AVM compliance status
4. **Single Purpose**: Focus on one data source per configuration
5. **HEREDOC Descriptions**: Use multi-line descriptions for complex outputs

## Authentication

The configuration uses OIDC authentication with the Power Platform provider:

- **Provider**: Configured for OIDC authentication with Azure/Entra ID
- **Backend**: Uses Azure Storage for Terraform state
- **Permissions**: Requires appropriate Power Platform admin permissions

## Troubleshooting

Common issues when exporting DLP policies:

### Authentication Issues
- Verify service principal has Power Platform Service Admin role
- Check OIDC configuration in GitHub secrets
- Ensure tenant ID is correct

### Permission Issues
- Confirm admin permissions for DLP policy management
- Check if conditional access policies block automation
- Verify service principal is not blocked

### Data Issues
- Large tenants may have many policies (check for timeouts)
- Sensitive policy details are now properly segregated
- Custom connectors may require additional permissions

## Related Documentation

- [Power Platform DLP Policies](https://learn.microsoft.com/power-platform/admin/prevent-data-loss)
- [Power Platform Terraform Provider - DLP Data Source](/workspaces/terraform-provider-power-platform/docs/data-sources/data_loss_prevention_policies.md)
- [AVM Compliance Remediation Plan](../../docs/guides/avm-compliance-remediation-plan.md)
- [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

---

**Last Updated**: July 20, 2025  
**AVM Compliance**: 85% (Provider Exception)  
**TFFR2 Status**: ✅ Anti-corruption layer implemented
