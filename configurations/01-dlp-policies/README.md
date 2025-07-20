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

This configuration provides comprehensive DLP policy data through two structured outputs:

### Primary Output: `dlp_policies`

Provides complete migration-ready policy data with anti-corruption layer compliance:

```hcl
{
  policy_count = 3
  policies = [
    {
      # Core policy metadata
      id                                 = "default-tenant-policy"
      display_name                       = "Default Tenant Policy"
      environment_type                   = "AllEnvironments"
      environments                       = []
      default_connectors_classification = "General"
      
      # Audit information
      created_by           = "admin@example.com"
      created_time         = "2024-01-15T10:30:00Z"
      last_modified_by     = "admin@example.com"
      last_modified_time   = "2024-03-20T14:15:00Z"
      
      # Connector classifications (essential for migration)
      business_connectors = [
        {
          id                           = "shared_sharepointonline"
          default_action_rule_behavior = "Allow"
          action_rules_count           = 0
          endpoint_rules_count         = 2
        }
      ]
      
      non_business_connectors = [
        {
          id                           = "shared_office365users"
          default_action_rule_behavior = "Allow"
          action_rules_count           = 1
          endpoint_rules_count         = 0
        }
      ]
      
      blocked_connectors = [
        {
          id                           = "shared_facebookforbusiness"
          default_action_rule_behavior = "Block"
          action_rules_count           = 0
          endpoint_rules_count         = 0
        }
      ]
      
      # Custom connector patterns (critical for custom connector policies)
      custom_connectors_patterns = [
        {
          data_group       = "Business"
          host_url_pattern = "https://internal.company.com/*"
          order           = 1
        }
      ]
      
      # Summary counts for validation
      connector_summary = {
        business_count        = 1
        non_business_count    = 1
        blocked_count         = 1
        custom_patterns_count = 1
        total_connectors      = 3
      }
    }
  ]
}
```

### Detailed Rules Output: `dlp_policies_detailed_rules`

Provides granular connector rules for advanced migration scenarios (marked sensitive):

```hcl
{
  policies_with_detailed_rules = [
    {
      policy_id   = "default-tenant-policy"
      policy_name = "Default Tenant Policy"
      
      business_connectors_detailed = [
        {
          connector_id = "shared_sharepointonline"
          default_action_rule_behavior = "Allow"
          action_rules = []
          endpoint_rules = [
            {
              endpoint = "https://specific-sharepoint-site.com"
              behavior = "Allow"
              order    = 1
            }
          ]
        }
      ]
      # ... similar structure for non_business_connectors_detailed and blocked_connectors_detailed
    }
  ]
}
```

## Migration Use Cases

### 1. Complete Policy Recreation
Use the primary output to recreate all DLP policies with identical configurations:
- All connector classifications preserved (`business_connectors`, `non_business_connectors`, `blocked_connectors`)
- Custom connector patterns maintained (`custom_connectors_patterns`)
- Environment assignments replicated (`environments`, `environment_type`)
- Default behaviors retained (`default_connectors_classification`)

### 2. Connector Analysis and Compliance
- `connector_summary` provides quick counts for validation
- Business vs non-business classification for compliance review
- Custom connector patterns for internal application governance
- Action and endpoint rule counts for complexity assessment

### 3. Granular Rule Migration
Use the detailed rules output for:
- Exact action rule preservation (specific connector actions allowed/blocked)
- Endpoint rule migration (URL patterns and access controls)
- Rule order preservation for policy consistency
- Complete connector behavior replication

### 4. Validation and Testing
- Compare connector counts before/after migration (`connector_summary`)
- Validate custom connector pattern preservation
- Ensure no policy regression during IaC adoption
- Verify rule completeness through detailed rules output

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
