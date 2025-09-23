# PPCC25 Demo Scripts: Key Vault Private Endpoints

This directory contains scripts for deploying and cleaning up Azure Key Vault with dual private endpoints for the PPCC25 Power Platform governance demonstration.

## 🎯 Purpose

These scripts complement the `ptn-azure-vnet-extension` Terraform pattern by adding Key Vault infrastructure that demonstrates Power Platform VNet integration through private endpoints.

## 📁 Files

| File                                    | Purpose                                      | Usage                  |
| --------------------------------------- | -------------------------------------------- | ---------------------- |
| `setup-keyvault-private-endpoints.sh`   | Deploy Key Vault with dual private endpoints | Main deployment script |
| `cleanup-keyvault-private-endpoints.sh` | Clean up demo resources after presentation   | Teardown script        |

## 🚀 Quick Start

### Prerequisites

1. **Terraform Infrastructure**: Deploy `ptn-azure-vnet-extension` first
2. **Azure CLI**: Authenticated and connected to correct subscription  
3. **Permissions**: Contributor access to resource group and Key Vault permissions

### Deploy Demo Environment

```bash
# Basic deployment
./scripts/demo/setup-keyvault-private-endpoints.sh

# Automated deployment (skip confirmations)
./scripts/demo/setup-keyvault-private-endpoints.sh --auto-approve
```

### Test Power Platform Connectivity

After deployment, create a Power Automate Cloud Flow:

1. **Flow Name**: "Key Vault VNet Connectivity Test"
2. **HTTP Action**:
   - Method: `GET`
   - URI: `https://kv-ppcc25-demo-dev-cac.vault.azure.net/secrets/vnet-connectivity-test?api-version=7.4`
   - Authentication: `Managed Identity` (System-assigned)
   - Audience: `https://vault.azure.net`

3. **Expected Success**: HTTP 200 with secret value

### Clean Up After Demo

```bash
# Remove all demo resources
./scripts/demo/cleanup-keyvault-private-endpoints.sh

# Keep Key Vault, remove only private endpoints  
./scripts/demo/cleanup-keyvault-private-endpoints.sh --keep-keyvault

# Automated cleanup
./scripts/demo/cleanup-keyvault-private-endpoints.sh --auto-approve
```

## 🏗️ Architecture

The scripts deploy this infrastructure:

```
┌─ Azure Key Vault (Canada Central) ─────────────────────┐
│  Name: kv-ppcc25-demo-dev-cac                          │
│  Public Access: Disabled                               │  
│  RBAC: Enabled                                         │
│  └─ Secrets: vnet-connectivity-test, demo-config, etc. │
└────────────────────────────────────────────────────────┘
                              │
                              │ Private Link Connections
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
┌─ Primary Private Endpoint ─┐    ┌─ Failover Private Endpoint ─┐
│ pe-kv-ppcc25-demo-dev-cac  │    │ pe-kv-ppcc25-demo-dev-cae   │
│ Canada Central             │    │ Canada East                  │
│ IP: 10.96.2.x             │    │ IP: 10.112.2.x              │
└────────────────────────────┘    └──────────────────────────────┘
              │                               │
              ▼                               ▼
┌─ Primary VNet ─────────────┐    ┌─ Failover VNet ─────────────┐
│ vnet-...-dev-cac-primary   │    │ vnet-...-dev-cae-failover   │
│ 10.96.0.0/16              │    │ 10.112.0.0/16               │
│ └─PrivateEndpoint Subnet   │    │ └─PrivateEndpoint Subnet    │
│   └─ Power Platform Subnet │    │   └─ Power Platform Subnet  │
└────────────────────────────┘    └──────────────────────────────┘
```

## 🔧 Configuration Details

### Key Vault Settings
- **SKU**: Standard
- **Location**: Canada Central  
- **RBAC**: Enabled (Azure role-based access control)
- **Public Access**: Disabled (private endpoints only)
- **Soft Delete**: Enabled (90 days retention)

### Private Endpoints
- **Primary**: Connected to Canada Central VNet private endpoint subnet
- **Failover**: Connected to Canada East VNet private endpoint subnet
- **DNS Integration**: Automatic A record creation in private DNS zone

### Demo Secrets
- `vnet-connectivity-test`: Test secret for Power Platform validation
- `demo-configuration`: Demo-specific configuration information
- `environment-info`: Environment and architecture details

## 🔍 Verification Commands

```bash
# Check Key Vault status
az keyvault show --name kv-ppcc25-demo-dev-cac --query "{name:name,publicAccess:properties.publicNetworkAccess}"

# Verify private endpoints
az network private-endpoint list --resource-group rg-ppcc25-demoworkspace-dev-vnet-cac --query "[].{name:name,state:provisioningState}" -o table

# Test DNS resolution (should show private IPs)
nslookup kv-ppcc25-demo-dev-cac.vault.azure.net

# List demo secrets
az keyvault secret list --vault-name kv-ppcc25-demo-dev-cac --query "[].name" -o table
```

## 🎭 Demo Flow

1. **Setup**: Run deployment script (5-10 minutes)
2. **Show Infrastructure**: Display Key Vault and private endpoints in Azure Portal
3. **Create Cloud Flow**: Manual Power Automate flow creation (5 minutes)
4. **Test Connectivity**: Execute flow and show successful VNet access
5. **Explain Architecture**: Highlight private networking and zero-trust principles
6. **Cleanup**: Run cleanup script after demo

## ⚠️ Important Notes

- **Name Uniqueness**: Key Vault names are globally unique
- **Soft Delete**: Key Vault soft-delete affects name reuse (cleanup script handles this)
- **RBAC Permissions**: Scripts assign temporary permissions for secret creation
- **Cost**: Estimated ~$10-15/month for Key Vault + private endpoints
- **Dependencies**: Requires existing VNet infrastructure from ptn-azure-vnet-extension

## 🚨 Troubleshooting

### Common Issues

**Power Platform Access Denied (403)**
```bash
# Grant Key Vault Secrets User role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee [USER-OR-IDENTITY-ID] \
  --scope [KEY-VAULT-RESOURCE-ID]
```

**DNS Resolution Issues**
```bash
# Check DNS records
az network private-dns record-set a show \
  --resource-group rg-ppcc25-demoworkspace-dev-vnet-cac \
  --zone-name privatelink.vaultcore.azure.net \
  --name kv-ppcc25-demo-dev-cac
```

**Script Permission Errors**
```bash
# Make scripts executable
chmod +x scripts/demo/*.sh

# Check Azure CLI authentication
az account show
```

## 📚 References

- [Azure Key Vault Private Endpoints](https://docs.microsoft.com/azure/key-vault/general/private-link-service)
- [Power Platform VNet Integration](https://docs.microsoft.com/power-platform/admin/vnet-support)
- [Azure Private DNS](https://docs.microsoft.com/azure/dns/private-dns-overview)