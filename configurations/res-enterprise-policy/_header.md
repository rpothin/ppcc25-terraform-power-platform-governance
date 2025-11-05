# res-enterprise-policy

This module deploys Microsoft.PowerPlatform/enterprisePolicies resources using the Azure API provider (azapi). Enterprise policies enable advanced Power Platform governance capabilities including Azure VNet integration and customer-managed key encryption.

## Key Features

- **Network Injection Support**: Configure VNet integration for secure Power Platform connectivity
- **Customer-Managed Encryption**: Deploy encryption policies using Azure Key Vault keys
- **AVM Compliance**: Child module design compatible with meta-arguments (for_each, count)
- **Comprehensive Validation**: Strong typing with extensive input validation
- **Anti-Corruption Layer**: Clean outputs that abstract azapi implementation details
- **Lifecycle Management**: Production-ready resource lifecycle and timeout configuration

## Policy Types

### NetworkInjection
Enables Azure VNet integration for Power Platform environments, allowing secure connectivity to Azure resources while maintaining network isolation.

### Encryption
Configures customer-managed key encryption for Power Platform data, providing enhanced security control over data encryption keys.

## Prerequisites

- Azure subscription with PowerPlatform resource provider registered
- For NetworkInjection: Azure VNet with Microsoft.PowerPlatform/environments subnet delegation
- For Encryption: Azure Key Vault with encryption keys and appropriate RBAC permissions
- azapi Terraform provider ~> 2.6
