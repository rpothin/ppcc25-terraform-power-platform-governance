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

1. **Terraform Infrastructure**: Deploy `ptn-azure-vnet-extension` with desired tfvars configuration first
2. **Azure CLI**: Authenticated and connected to correct subscription  
3. **Permissions**: Contributor access to resource group and Key Vault permissions

### 🎛️ **Flexible Configuration Support**

The scripts dynamically target resources based on your **tfvars configuration**, supporting multiple demo scenarios:

| tfvars File         | Purpose                   | Example Resources                     |
| ------------------- | ------------------------- | ------------------------------------- |
| `demo-prep`         | Pre-presentation baseline | `kv-ppcc25-demoprepws-dev-cac`        |
| `live-demo`         | Live presentation         | `kv-ppcc25-livedemoworkspace-dev-cac` |
| `regional-examples` | Original demo config      | `kv-ppcc25-demoworkspace-dev-cac`     |

**🎯 Key Feature**: All resource names are **dynamically calculated** from your tfvars configuration - no hardcoded values!

### Deploy Demo Environment

```bash
# Pre-presentation preparation
./scripts/demo/setup-keyvault-private-endpoints.sh --tfvars-file demo-prep

# Live demonstration deployment
./scripts/demo/setup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Original regional examples
./scripts/demo/setup-keyvault-private-endpoints.sh --tfvars-file regional-examples

# Any custom tfvars configuration
./scripts/demo/setup-keyvault-private-endpoints.sh --tfvars-file [YOUR_CONFIG_NAME]
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
# Clean up specific configuration
./scripts/demo/cleanup-keyvault-private-endpoints.sh --tfvars-file demo-prep

# Clean up live demo resources
./scripts/demo/cleanup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Keep Key Vault, remove only private endpoints (useful for testing)
./scripts/demo/cleanup-keyvault-private-endpoints.sh --tfvars-file live-demo --keep-keyvault

# Handle soft-delete conflicts (purge before cleanup)
./scripts/demo/cleanup-keyvault-private-endpoints.sh --tfvars-file demo-prep --purge-soft-deleted
```

## 🧠 **Dynamic Resource Naming**

Scripts automatically calculate all resource names using the **same CAF patterns as Terraform**:

### **Naming Formula**:
```bash
# From tfvars workspace name: "DemoPrepWorkspace" → "demoprepworkspace"
RESOURCE_GROUP = "rg-ppcc25-{workspace_lower}-dev-vnet-cac"  
KEY_VAULT = "kv-ppcc25-{workspace_short}-dev-cac"  # Auto-truncated for 24-char limit
VNET_PRIMARY = "vnet-ppcc25-{workspace_lower}-dev-cac-primary"
PRIVATE_ENDPOINT = "pe-kv-ppcc25-{workspace_short}-dev-cac"
```

### **Configuration Examples**:
```bash
# demo-prep.tfvars (name = "DemoPrepWorkspace"):
#   → kv-ppcc25-demoprepws-dev-cac
#   → rg-ppcc25-demoprepworkspace-dev-vnet-cac

# live-demo.tfvars (name = "LiveDemoWorkspace"):  
#   → kv-ppcc25-livedemo-dev-cac
#   → rg-ppcc25-livedemoworkspace-dev-vnet-cac

# regional-examples.tfvars (name = "DemoWorkspace"):
#   → kv-ppcc25-demoworks-dev-cac  
#   → rg-ppcc25-demoworkspace-dev-vnet-cac
```

**🎯 Result**: Scripts work with **any tfvars configuration** without modification!

## 🎛️ **Advanced Script Options**

### **Setup Script** (`setup-keyvault-private-endpoints.sh`):
```bash
--tfvars-file <name>    # Specify tfvars configuration (REQUIRED)
--auto-approve          # Skip confirmation prompts
--secrets-only          # Create secrets only (skip infrastructure)
--help, -h             # Show detailed help and examples
```

### **Cleanup Script** (`cleanup-keyvault-private-endpoints.sh`):
```bash
--tfvars-file <name>    # Specify tfvars configuration (REQUIRED)  
--auto-approve          # Skip confirmation prompts
--keep-keyvault         # Keep Key Vault, remove only private endpoints
--purge-soft-deleted    # Purge soft-deleted Key Vault first (handle conflicts)
--help, -h             # Show detailed help and examples
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
# Check Key Vault status (replace with your actual Key Vault name)
az keyvault show --name kv-ppcc25-[CONFIG]-dev-cac --query "{name:name,publicAccess:properties.publicNetworkAccess}"

# Verify private endpoints (replace with your resource group name)  
az network private-endpoint list --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac --query "[].{name:name,state:provisioningState}" -o table

# Test DNS resolution (should show private IPs)
nslookup kv-ppcc25-[CONFIG]-dev-cac.vault.azure.net

# List demo secrets (replace with your Key Vault name)
az keyvault secret list --vault-name kv-ppcc25-[CONFIG]-dev-cac --query "[].name" -o table
```

**💡 Tip**: Replace `[CONFIG]` with your actual configuration's workspace name pattern:
- `demo-prep` → `demoprepws` 
- `live-demo` → `livedemo`
- `regional-examples` → `demoworks`

## 📋 **Configuration Discovery**

### Find Available Configurations:
```bash
# List all available tfvars configurations
ls configurations/ptn-environment-group/tfvars/*.tfvars

# Check workspace name in specific tfvars file
grep "^name" configurations/ptn-environment-group/tfvars/demo-prep.tfvars
```

### Validate Configuration Pairing:
```bash
# Both files must exist for script to work:
ls configurations/ptn-environment-group/tfvars/[CONFIG].tfvars
ls configurations/ptn-azure-vnet-extension/tfvars/[CONFIG].tfvars
```

## 🎭 Demo Flow

### **Multiple Configuration Strategy**
The enhanced scripts support **different demo scenarios** with isolated resources:

#### **1. Demo-Prep Flow** (Pre-presentation setup):
```bash
# Deploy stable baseline before presentation
./setup-keyvault-private-endpoints.sh --tfvars-file demo-prep --auto-approve

# Test and validate all components work
# Create and test Power Platform Cloud Flow
# Leave running as backup/fallback

# Cleanup only if needed
./cleanup-keyvault-private-endpoints.sh --tfvars-file demo-prep
```

#### **2. Live-Demo Flow** (During presentation):
```bash
# Deploy live demo environment
./setup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Demonstrate live resource creation (5-10 minutes)
# Create Power Platform Cloud Flow with audience
# Show VNet integration working in real-time

# Cleanup after presentation
./cleanup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve
```

#### **3. Multi-Demo Support** (Advanced scenarios):
```bash
# Run both simultaneously (different resource names!)
./setup-keyvault-private-endpoints.sh --tfvars-file demo-prep &
./setup-keyvault-private-endpoints.sh --tfvars-file live-demo &
wait

# Selective cleanup
./cleanup-keyvault-private-endpoints.sh --tfvars-file live-demo --keep-keyvault
./cleanup-keyvault-private-endpoints.sh --tfvars-file demo-prep  
```

### **Benefits of Dynamic Configuration**:
- ✅ **Isolated Resources**: Each configuration creates separate, non-conflicting resources
- ✅ **Flexible Timing**: Deploy/cleanup demo-prep and live-demo independently  
- ✅ **Risk Mitigation**: Always have working demo-prep as backup
- ✅ **Professional Presentation**: Clear resource separation visible to audience

1. **Setup**: Run deployment script with chosen configuration (5-10 minutes)
2. **Show Infrastructure**: Display Key Vault and private endpoints in Azure Portal
3. **Create Cloud Flow**: Manual Power Automate flow creation (5 minutes)
4. **Test Connectivity**: Execute flow and show successful VNet access
5. **Explain Architecture**: Highlight private networking and zero-trust principles
6. **Cleanup**: Run cleanup script with same configuration after demo

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
# Check DNS records (replace [CONFIG] with your configuration)
az network private-dns record-set a show \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --zone-name privatelink.vaultcore.azure.net \
  --name kv-ppcc25-[CONFIG_SHORT]-dev-cac
```

**Configuration Validation Issues**
```bash
# Verify tfvars file exists and is readable
ls -la configurations/ptn-environment-group/tfvars/[CONFIG].tfvars
ls -la configurations/ptn-azure-vnet-extension/tfvars/[CONFIG].tfvars

# Check workspace name parsing
grep "^name" configurations/ptn-environment-group/tfvars/[CONFIG].tfvars
```

**Resource Naming Conflicts**  
```bash
# Check if resources already exist with different configuration
az keyvault list --query "[?starts_with(name,'kv-ppcc25-')].{name:name,resourceGroup:resourceGroup}" -o table

# List all Key Vault private endpoints
az network private-endpoint list --query "[?contains(name,'kv-ppcc25-')].{name:name,resourceGroup:resourceGroup}" -o table
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