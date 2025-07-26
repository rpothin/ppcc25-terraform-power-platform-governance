# Power Platform DLP Policies Export Configuration

This configuration provides a standardized way to export Data Loss Prevention (DLP) policies from Microsoft Power Platform for analysis and migration planning. It demonstrates how to create single-purpose Terraform configurations that target specific data sources while following Azure Verified Module (AVM) best practices.

## Use Cases

This configuration is designed for organizations that need to:

1. **Policy Inventory**: Understand current DLP policy landscape across Power Platform environments
2. **Migration Planning**: Export existing policies for Infrastructure as Code adoption
3. **Compliance Documentation**: Generate structured policy documentation for auditing
4. **Configuration Analysis**: Compare manual vs. IaC-managed policies for consistency

## Usage with Terraform Output Workflow

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-export-dlp-policies'
```
