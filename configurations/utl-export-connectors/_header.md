# Export Power Platform Connectors Utility

This configuration exports a comprehensive list of connectors from your Power Platform tenant, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Key Features

- **Live Tenant Data Access**: Real-time connector inventory directly from Power Platform APIs
- **Comprehensive Metadata Export**: Full connector details including names, IDs, tiers, and publisher information
- **Filtering Capabilities**: Filter by connector type, publisher, or tier for targeted analysis
- **Multiple Output Formats**: JSON and structured outputs for different consumption patterns
- **Zero Dependencies**: No external file dependencies or manual exports required
- **Audit-Ready Reports**: Generate compliance-ready connector inventories for governance reviews

## Data Export Capabilities

### Connector Information
- **Complete Inventory**: All standard and custom connectors in tenant
- **Metadata Details**: Publisher, tier, connector type, and certification status
- **Unique Identification**: Full connector IDs for DLP policy configuration
- **Real-Time Accuracy**: Always current data from live tenant APIs

### Export Formats
- **Structured JSON**: Machine-readable format for automation workflows
- **Terraform Outputs**: Direct integration with Infrastructure as Code workflows
- **Audit Reports**: Human-readable summaries for compliance documentation

### Filtering & Analysis
- **Publisher Filtering**: Microsoft vs third-party vs custom connectors
- **Tier Classification**: Premium vs standard connector identification
- **Custom Connector Detection**: Organization-specific integrations inventory

## Use Cases

This configuration is designed for organizations that need to:

1. **Inventory All Connectors**: Generate an up-to-date inventory of all standard and custom connectors available in the tenant.
2. **Support Governance Audits**: Provide evidence for compliance and governance reviews by exporting connector metadata.
3. **Enable DLP Policy Planning**: Supply input data for Data Loss Prevention (DLP) policy design and enforcement.
4. **Facilitate Integration Analysis**: Help architects and developers analyze available integration options for Power Platform solutions.
5. **License Optimization**: Identify premium connectors to optimize Power Platform licensing costs
6. **Security Assessment**: Audit third-party and custom connectors for security compliance
7. **Migration Planning**: Inventory current connectors before tenant migrations or consolidations

## Integration with DLP Policy Management

```hcl
# Use exported connector data for DLP policy creation
data "terraform_remote_state" "connectors" {
  backend = "azurerm"
  config = {
    # Reference connector export state
  }
}

# Filter for business-appropriate connectors
locals {
  microsoft_connectors = [
    for connector in data.terraform_remote_state.connectors.outputs.connectors_list :
    connector if contains(["Microsoft"], connector.publisher)
  ]
}
```

## Usage with Data Export Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-export-connectors'
```

## Performance Optimization

### Large Tenant Considerations
- **Tenant Size**: Optimized for tenants with 100-1000+ connectors
- **Pagination Support**: Efficient handling of large connector inventories
- **Filtering Options**: Reduce dataset size for targeted analysis
- **Caching Strategy**: Output caching for repeated analysis workflows