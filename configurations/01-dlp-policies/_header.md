# Power Platform DLP Policies Export Configuration

This configuration provides a standardized way to export Data Loss Prevention (DLP) policies from Microsoft Power Platform for analysis and migration planning. It demonstrates how to create single-purpose Terraform configurations that target specific data sources while following Azure Verified Module (AVM) best practices.

## ⚠️ AVM Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`). 

**Compliance Status**: 85% (Provider Exception Documented)  
**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

## Key Features

- **Anti-Corruption Layer**: Implements TFFR2 compliance by exposing discrete attributes instead of complete resource objects
- **Security-First**: Sensitive data properly marked and segregated in outputs  
- **Migration Ready**: Structured output designed for Infrastructure as Code migration scenarios
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Single Purpose**: Focused data source configuration for DLP policy export

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
  configuration: '01-dlp-policies'
```
