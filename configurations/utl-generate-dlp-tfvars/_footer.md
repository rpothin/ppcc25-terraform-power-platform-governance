## Authentication & Security

This configuration requires secure authentication to Microsoft Power Platform:

### Authentication Method
- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **No Client Secrets**: Keyless authentication for enhanced security
- **Required Permissions**: Power Platform Service Admin role or DLP Policy Read permissions
- **State Backend**: Azure Storage with OIDC authentication

### Security Best Practices
- **Principle of Least Privilege**: Service principal permissions limited to DLP policy read access
- **Secure State Management**: Terraform state encrypted at rest in Azure Storage
- **No Sensitive Data Storage**: Generated tfvars contain policy configuration only (no secrets)
- **Audit Logging**: All operations logged through Azure AD and Power Platform audit logs

## Data Handling & Privacy

This configuration prioritizes data security and privacy:

### Data Sources
- **Live API Access**: Connects directly to Power Platform Management APIs
- **No Data Export**: No intermediate file storage or data export requirements
- **Tenant Isolation**: All data remains within your Power Platform tenant boundaries
- **Real-time Queries**: Policy data retrieved at execution time only

### Data Collection Policy
- **No Telemetry**: This configuration does not collect or transmit telemetry data
- **Local Processing**: All data processing occurs in your execution environment
- **Temporary Access**: Policy data accessed only during terraform execution
- **No Third-party Storage**: No data stored outside your tenant and execution environment

## ⚠️ AVM Compliance & Standards

### Provider Exception Documentation

This configuration uses the `microsoft/power-platform` provider, which creates a documented exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### AVM Compliance Implementation

- **TFFR2 Anti-Corruption Layer**: Implements discrete outputs instead of exposing full resource objects
- **TFFR4 Security Standards**: Sensitive data properly marked and segregated in outputs
- **TFFR6 Validation**: Comprehensive input validation with clear error messages
- **TFFR9 Documentation**: Complete variable and output documentation with examples
- **AVM-Inspired Patterns**: Follows AVM standards where technically feasible with Power Platform

### Module Classification
- **Utility Module (`utl-*`)**: Provides data processing and file generation without deploying resources
- **Anti-Corruption Focus**: Transforms live API data into standardized tfvars format
- **Reusable Pattern**: Can be extended for other Power Platform resource onboarding scenarios

## Troubleshooting & Support

### Common Issues & Resolutions

**Authentication Failures**
```bash
# Verify service principal configuration
az ad sp show --id <service-principal-id>
# Check Power Platform permissions
az role assignment list --assignee <service-principal-id>