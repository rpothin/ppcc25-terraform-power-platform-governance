# Export Power Platform Connectors Utility

This configuration exports a comprehensive list of connectors from your Power Platform tenant, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Inventory All Connectors**: Generate an up-to-date inventory of all standard and custom connectors available in the tenant.
2. **Support Governance Audits**: Provide evidence for compliance and governance reviews by exporting connector metadata.
3. **Enable DLP Policy Planning**: Supply input data for Data Loss Prevention (DLP) policy design and enforcement.
4. **Facilitate Integration Analysis**: Help architects and developers analyze available integration options for Power Platform solutions.

## Usage with Data Export Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-export-connectors'
```