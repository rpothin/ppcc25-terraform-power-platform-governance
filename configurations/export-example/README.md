# DLP Policies Export Configuration

This configuration demonstrates how to export current Data Loss Prevention policies from Power Platform for migration planning. It serves as a reference for creating single-purpose Terraform configurations that target specific data sources.

## Purpose

This configuration is designed to:
- Query current DLP policies in the Power Platform tenant
- Export policy configurations in JSON format for analysis
- Support migration planning from manual to Infrastructure-as-Code management
- Demonstrate best practices for data source-only Terraform configurations

## Data Source

**Data Loss Prevention Policies** (`powerplatform_data_loss_prevention_policies`)
- Fetches all DLP policies in the tenant
- Includes policy details, connector classifications, and environment assignments
- Provides comprehensive policy configuration for migration analysis

## Usage with Terraform Output Workflow

This configuration is used with the Terraform Output workflow to:

1. **Execute Data Source Query**: Run Terraform to query current DLP policies
2. **Generate JSON Output**: Export policy data in structured JSON format
3. **Store for Analysis**: Save output for migration planning and comparison

### Workflow Usage

```yaml
# In the Terraform Output workflow
inputs:
  configuration: 'export-example'  # Uses this DLP policies configuration
```

## Output Format

The workflow produces a JSON file with this structure:

```json
{
  "output_metadata": {
    "timestamp": "20250719-143022",
    "configuration": "export-example",
    "exported_by": "GitHub Actions",
    "workflow_run": "123"
  },
  "outputs": {
    "dlp_policies": {
      "value": {
        "policies": [
          {
            "id": "policy-guid",
            "display_name": "Corporate DLP Policy",
            "environment_type": "AllEnvironments",
            "business_connectors": [...],
            "non_business_connectors": [...],
            "blocked_connectors": [...],
            "created_by": "admin@company.com",
            "created_time": "2024-01-15T10:30:00Z",
            "last_modified_time": "2024-03-20T14:45:00Z"
          }
        ]
      }
    }
  }
}
```

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
  description = "Current Power Platform environments"
  value       = data.powerplatform_environments.current
  sensitive   = false
}
```

### 2. Tenant Settings Export
```hcl
data "powerplatform_tenant_settings" "current" {}

output "tenant_settings" {
  description = "Current tenant settings"
  value       = data.powerplatform_tenant_settings.current
  sensitive   = false
}
```

### 3. Solutions Export (Environment-Specific)
```hcl
data "powerplatform_environments" "target" {}

data "powerplatform_solutions" "current" {
  environment_id = data.powerplatform_environments.target.environments[0].id
}

output "solutions" {
  description = "Solutions in the target environment"
  value       = data.powerplatform_solutions.current
  sensitive   = false
}
```

## Best Practices for Migration Configurations

1. **Single Purpose**: Focus on one data source per configuration
2. **Clear Naming**: Use descriptive names that indicate the export purpose
3. **Comprehensive Output**: Include all relevant attributes in outputs
4. **Documentation**: Document the migration context and use case
5. **Version Control**: Track changes to understand policy evolution

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
- Some policy details may be sensitive (review output marking)
- Custom connectors may require additional permissions

## Related Documentation

- [Power Platform DLP Policies](https://learn.microsoft.com/power-platform/admin/prevent-data-loss)
- [Power Platform Terraform Provider - DLP Data Source](/workspaces/terraform-provider-power-platform/docs/data-sources/data_loss_prevention_policies.md)
- [Terraform Output Workflow Guide](/workspaces/ppcc25-terraform-power-platform-governance/docs/guides/power-platform-export.md)
