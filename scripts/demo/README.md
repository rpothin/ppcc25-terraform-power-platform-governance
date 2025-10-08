# PPCC25 Demo Scripts: Azure Private Endpoint Integration

This directory contains scripts for deploying and cleaning up Azure resources with dual private endpoints for the PPCC25 Power Platform governance demonstration.

## 🎯 Demo Scenarios

This directory supports **two independent demo scenarios**, each demonstrating different aspects of Power Platform VNet integration:

### 1️⃣ **Key Vault Demo** - Secret Management via Private Endpoints
- **Purpose**: Demonstrate secure secret retrieval from Key Vault through Power Platform
- **Authentication**: Managed Identity (System-assigned)
- **Use Case**: ClickOps to IaC transition for secure configuration management
- **Scripts**: `setup-keyvault-private-endpoints.sh`, `cleanup-keyvault-private-endpoints.sh`

### 2️⃣ **SQL Server Demo** - Database Connectivity via Private Endpoints  
- **Purpose**: Demonstrate passwordless database access through Power Platform
- **Authentication**: Microsoft Entra ID Integrated (no credentials needed)
- **Use Case**: Modern data access patterns with zero-trust security
- **Scripts**: `setup-sqlserver-private-endpoints.sh`, `cleanup-sqlserver-private-endpoints.sh`

**🎯 Key Feature**: Both demos are **completely independent** - deploy one, both, or neither based on your presentation needs!

## 🎯 Purpose

These scripts complement the `ptn-azure-vnet-extension` Terraform pattern by adding Key Vault infrastructure that demonstrates Power Platform VNet integration through private endpoints.

## 📁 Files

### Key Vault Demo Scripts
| File                                    | Purpose                                      | Usage                  |
| --------------------------------------- | -------------------------------------------- | ---------------------- |
| `setup-keyvault-private-endpoints.sh`   | Deploy Key Vault with dual private endpoints | Main deployment script |
| `cleanup-keyvault-private-endpoints.sh` | Clean up Key Vault demo resources            | Teardown script        |

### SQL Server Demo Scripts
| File                                     | Purpose                                       | Usage                  |
| ---------------------------------------- | --------------------------------------------- | ---------------------- |
| `setup-sqlserver-private-endpoints.sh`   | Deploy SQL Server with dual private endpoints | Main deployment script |
| `cleanup-sqlserver-private-endpoints.sh` | Clean up SQL Server demo resources            | Teardown script        |

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

---

# 🗄️ SQL Server Demo: Passwordless Database Access

## 🎯 Purpose

This demo showcases **passwordless database connectivity** from Power Platform using **Microsoft Entra ID Integrated authentication**. It demonstrates modern data access patterns with zero-trust security principles - **no credentials stored, no passwords managed**.

## 🌟 Key Differentiators from Key Vault Demo

| Aspect             | Key Vault Demo           | SQL Server Demo                     |
| ------------------ | ------------------------ | ----------------------------------- |
| **Purpose**        | Secret management        | Database connectivity               |
| **Authentication** | Managed Identity         | Microsoft Entra ID Integrated       |
| **Resources**      | Key Vault + secrets      | SQL Server + database + demo data   |
| **Use Case**       | Configuration management | Data access and integration         |
| **Complexity**     | Simple (secrets only)    | Moderate (database + schema + data) |
| **Demo Value**     | Security best practices  | Modern data platform integration    |

**🎯 Together, they demonstrate comprehensive Power Platform VNet integration capabilities!**

## 🚀 Quick Start

### Prerequisites

1. **Terraform Infrastructure**: Deploy `ptn-azure-vnet-extension` with desired tfvars configuration first
2. **Azure CLI**: Authenticated and connected to correct subscription  
3. **Permissions**: Contributor access to resource group and SQL Server admin permissions
4. **Optional**: `sqlcmd` with Entra ID support for automated demo table creation (see installation below)

### 🎛️ **Flexible Configuration Support**

Just like the Key Vault demo, SQL Server scripts dynamically target resources based on your **tfvars configuration**:

| tfvars File         | Purpose                   | Example Resources                  |
| ------------------- | ------------------------- | ---------------------------------- |
| `demo-prep`         | Pre-presentation baseline | `sql-ppcc25-demoprepws-dev-cac`    |
| `live-demo`         | Live presentation         | `sql-ppcc25-livedemo-dev-cac`      |
| `regional-examples` | Original demo config      | `sql-ppcc25-demoworks-dev-cac`     |

**🎯 Key Feature**: All resource names are **dynamically calculated** from your tfvars configuration - static names enable idempotent deployments!

### 📝 Demo Table Setup (Azure Portal)

The setup script creates the SQL Server and database infrastructure. After deployment, you'll create the demo table using **Azure Portal's Query Editor** - a simple, reliable approach that avoids command-line tool complexity.

**Why Azure Portal Query Editor?**
- ✅ **No installation required** - Built into Azure Portal
- ✅ **Automatic authentication** - Uses your Azure Portal session
- ✅ **Visual interface** - Perfect for demonstrations
- ✅ **Works with private endpoints** - Tests the actual VNet integration
- ✅ **Simple and reliable** - Focus on the demo, not the tools

**SQL Script Available**: [`scripts/demo/create-demo-table.sql`](./create-demo-table.sql)

**Execution Steps** (after running setup script):
1. Open Azure Portal → Navigate to your SQL Database (`demo-db`)
2. Click **Query editor** in left menu
3. Authenticate (uses your Entra ID automatically)
4. Open the SQL script file: `scripts/demo/create-demo-table.sql`
5. Copy-paste the entire script into Query Editor
6. Click **Run** → Should see "Commands completed successfully" and 5 rows
7. Ready to test from Power Platform!

**What the Script Does**:
- Creates `Customers` table with 8 columns (CustomerID, FirstName, LastName, Email, Company, Region, CreatedDate, IsActive)
- Inserts 5 sample customer records from various companies
- Verifies data with a SELECT query
- Provides clear next steps for Power Platform testing

### Deploy SQL Server Demo Environment

```bash
# Pre-presentation preparation
./scripts/demo/setup-sqlserver-private-endpoints.sh --tfvars-file demo-prep

# Live demonstration deployment (10-15 minutes)
./scripts/demo/setup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Original regional examples
./scripts/demo/setup-sqlserver-private-endpoints.sh --tfvars-file regional-examples

# Any custom tfvars configuration
./scripts/demo/setup-sqlserver-private-endpoints.sh --tfvars-file [YOUR_CONFIG_NAME]
```

**⏱️ Deployment Time**: 10-15 minutes (SQL Server provisioning + database + private endpoints)

### Test Power Platform Connectivity

After deployment, create a Power Automate Cloud Flow:

1. **Flow Name**: "SQL VNet Connectivity Test"
2. **Add SQL Server Connector**:
   - **Action**: Get rows (V2)
   - **Connection Settings**:
     - **Authentication Type**: `Microsoft Entra ID Integrated` ⚡ (NO credentials needed!)
     - **Server**: `sql-ppcc25-demo-dev-cac-12345.database.windows.net` (from setup output)
     - **Database**: `demo-db`
   - **Table**: Select `Customers`

3. **Expected Success**: 
   - **Status**: 200 OK
   - **Records**: 5 customer records with demo data
   - **Authentication**: Automatic via your Entra ID identity

4. **Demo Talking Points**:
   - ✅ No credentials entered
   - ✅ No passwords stored
   - ✅ No Key Vault needed
   - ✅ Automatic authentication via Entra ID
   - ✅ Private connectivity through VNet

### Clean Up After Demo

```bash
# Clean up specific configuration
./scripts/demo/cleanup-sqlserver-private-endpoints.sh --tfvars-file demo-prep

# Clean up live demo resources (3-5 minutes)
./scripts/demo/cleanup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Keep SQL Server, remove only private endpoints (useful for testing)
./scripts/demo/cleanup-sqlserver-private-endpoints.sh --tfvars-file live-demo --keep-sqlserver
```

## 🧠 **Dynamic Resource Naming**

Scripts automatically calculate all resource names using the **same CAF patterns as Terraform**:

### **Naming Formula**:
```bash
# From tfvars workspace name: "DemoPrepWorkspace" → "demoprepworkspace"
RESOURCE_GROUP = "rg-ppcc25-{workspace_lower}-dev-vnet-cac"  
SQL_SERVER = "sql-ppcc25-{workspace_short}-dev-cac"  # Static name (no timestamp)
SQL_DATABASE = "demo-db"  # Fixed for simplicity
VNET_PRIMARY = "vnet-ppcc25-{workspace_lower}-dev-cac-primary"
PRIVATE_ENDPOINT = "pe-sql-ppcc25-{workspace_short}-dev-cac"
```

### **Configuration Examples**:
```bash
# demo-prep.tfvars (name = "DemoPrepWorkspace"):
#   → sql-ppcc25-demoprepws-dev-cac
#   → rg-ppcc25-demoprepworkspace-dev-vnet-cac
#   → pe-sql-ppcc25-demoprepws-dev-cac

# live-demo.tfvars (name = "LiveDemoWorkspace"):  
#   → sql-ppcc25-livedemo-dev-cac
#   → rg-ppcc25-livedemoworkspace-dev-vnet-cac
#   → pe-sql-ppcc25-livedemo-dev-cac

# regional-examples.tfvars (name = "DemoWorkspace"):
#   → sql-ppcc25-demoworks-dev-cac
#   → rg-ppcc25-demoworkspace-dev-vnet-cac
#   → pe-sql-ppcc25-demoworks-dev-cac
```

**🎯 Result**: Static names enable **idempotent deployments** - reruns reuse existing resources instead of creating duplicates!

## 🎛️ **Script Options**

### **Setup Script** (`setup-sqlserver-private-endpoints.sh`):
```bash
--tfvars-file <name>    # Specify tfvars configuration (default: demo-prep)
--auto-approve          # Skip confirmation prompts
--help, -h             # Show detailed help and examples
```

### **Cleanup Script** (`cleanup-sqlserver-private-endpoints.sh`):
```bash
--tfvars-file <name>    # Specify tfvars configuration (default: demo-prep)  
--auto-approve          # Skip confirmation prompts
--keep-sqlserver        # Keep SQL Server, remove only private endpoints
--help, -h             # Show detailed help and examples
```

## 🏗️ Architecture

The scripts deploy this infrastructure:

```
┌─ Azure SQL Server (Canada Central) ────────────────────────┐
│  Name: sql-ppcc25-demo-dev-cac-12345                       │
│  Authentication: Microsoft Entra ID Only (NO SQL auth)     │
│  Public Access: Disabled                                   │  
│  Admin: [Your Entra ID Account]                            │
│  └─ Database: demo-db (Basic tier, ~$5/month)              │
│     └─ Table: Customers (5 sample records)                 │
└────────────────────────────────────────────────────────────┘
                              │
                              │ Private Link Connections
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
┌─ Primary Private Endpoint ─┐    ┌─ Failover Private Endpoint ─┐
│ pe-sql-ppcc25-demo-dev-cac │    │ pe-sql-ppcc25-demo-dev-cae  │
│ Canada Central             │    │ Canada East                  │
│ IP: 10.200.2.x            │    │ IP: 10.216.2.x              │
│ DNS: privatelink.database  │    │ DNS: privatelink.database    │
│      .windows.net          │    │      .windows.net            │
└────────────────────────────┘    └──────────────────────────────┘
              │                               │
              ▼                               ▼
┌─ Primary VNet ─────────────┐    ┌─ Failover VNet ─────────────┐
│ vnet-...-dev-cac-primary   │    │ vnet-...-dev-cae-failover   │
│ 10.200.0.0/12             │    │ 10.216.0.0/12               │
│ └─PrivateEndpoint Subnet   │    │ └─PrivateEndpoint Subnet    │
│   └─ Power Platform Subnet │    │   └─ Power Platform Subnet  │
└────────────────────────────┘    └──────────────────────────────┘
```

## 🔧 Configuration Details

### SQL Server Settings
- **Edition**: SQL Database (PaaS)
- **Tier**: Basic (5 DTUs) - Cost-effective for demos
- **Location**: Canada Central  
- **Authentication**: Microsoft Entra ID Only (SQL authentication disabled)
- **Admin**: Logged-in Azure CLI user becomes Entra ID admin
- **Public Access**: Disabled (private endpoints only)

### Database Settings
- **Name**: `demo-db`
- **Edition**: Basic
- **Capacity**: 5 DTUs
- **Max Size**: 2 GB
- **Zone Redundant**: No (cost optimization)

### Demo Data Schema
```sql
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Company NVARCHAR(100),
    Region NVARCHAR(50) DEFAULT 'Canada',
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

-- 5 sample customer records included
-- Companies: Contoso, Fabrikam, Northwind, Adventure Works, Wide World Importers
```

### Private Endpoints
- **Primary**: Connected to Canada Central VNet private endpoint subnet
- **Failover**: Connected to Canada East VNet private endpoint subnet  
- **DNS Integration**: Automatic A record creation in `privatelink.database.windows.net` zone
- **DNS Resolution**: FQDN resolves to private IPs (10.200.2.x, 10.216.2.x)

### Cost Breakdown
| Resource              | Cost (Monthly) | Notes                     |
| --------------------- | -------------- | ------------------------- |
| SQL Database (Basic)  | ~$5            | 5 DTU, 2GB storage        |
| SQL Server            | $0             | No charge for server      |
| Private Endpoint (×2) | ~$14           | $7 each in Canada regions |
| **Total**             | **~$19-20**    | Per deployment            |

## 🔍 Verification Commands

```bash
# Check SQL Server status (replace [SERVER_NAME] with your actual server name)
az sql server show --name [SERVER_NAME] --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "{name:name,adminType:administrators.administratorType,publicAccess:publicNetworkAccess}"

# Verify Entra ID admin configuration
az sql server ad-admin show --server-name [SERVER_NAME] --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac

# Check database status
az sql db show --name demo-db --server [SERVER_NAME] --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "{name:name,status:status,tier:sku.tier,capacity:sku.capacity}"

# Verify private endpoints  
az network private-endpoint list --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "[?contains(name,'sql')].{name:name,state:provisioningState,location:location}" -o table

# Test DNS resolution (should show private IPs: 10.200.2.x, 10.216.2.x)
nslookup [SERVER_NAME].database.windows.net

# View DNS records
az network private-dns record-set a show \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --zone-name privatelink.database.windows.net \
  --name [SERVER_NAME]

# Query demo data (use Azure Portal Query Editor)
# Navigate to: Portal → SQL databases → demo-db → Query editor
# Execute: SELECT TOP 3 CustomerID, FirstName, LastName, Company, Region FROM Customers ORDER BY CustomerID
```

**💡 Discovery Tip**: The setup script outputs the actual SQL Server name at completion. Look for:
```
SQL Server Information:
  Name: sql-ppcc25-demoprepws-dev-cac-67890
```

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
SQL Server demo supports the same **multiple configuration strategy** as Key Vault demo:

#### **1. Demo-Prep Flow** (Pre-presentation setup):
```bash
# Deploy stable SQL Server baseline before presentation
./setup-sqlserver-private-endpoints.sh --tfvars-file demo-prep --auto-approve

# Test and validate database connectivity
# Create and test Power Platform Cloud Flow with SQL connector
# Verify Entra ID authentication works
# Leave running as backup/fallback

# Cleanup only if needed
./cleanup-sqlserver-private-endpoints.sh --tfvars-file demo-prep
```

#### **2. Live-Demo Flow** (During presentation):
```bash
# Deploy live SQL Server demo environment (10-15 minutes)
./setup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Demonstrate live deployment with audience
# Create Power Platform Cloud Flow showing passwordless auth
# Query Customers table and show demo data
# Highlight Entra ID Integrated authentication (no credentials!)

# Cleanup after presentation (3-5 minutes)
./cleanup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve
```

#### **3. Combined Key Vault + SQL Server Demo** (Advanced):
```bash
# Deploy both demos simultaneously (different resources!)
./setup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve &
./setup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve &
wait

# Demonstrate comprehensive VNet integration:
# 1. Key Vault: Secret management with Managed Identity
# 2. SQL Server: Database access with Entra ID Integrated
# Show different authentication patterns for different use cases

# Selective cleanup
./cleanup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve
./cleanup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve
```

### **Demo Narrative Flow** (15-20 minutes):

1. **Context Setting** (2 min):
   - "Modern organizations need secure database access from Power Platform"
   - "Traditional approach: SQL authentication with passwords stored in Key Vault"
   - "Modern approach: Microsoft Entra ID Integrated - zero credentials"

2. **Setup** (10-12 min if live, 0 min if pre-deployed):
   - Run deployment script (or show pre-deployed resources)
   - Explain: Entra ID-only authentication, public access disabled
   - Highlight: Your account becomes SQL Server admin automatically

3. **Show Infrastructure** (2 min):
   - Display SQL Server in Azure Portal
   - Show Entra ID admin configuration (no SQL logins)
   - Show private endpoints in both regions
   - Display private DNS zone records

4. **Create Cloud Flow** (3-5 min):
   - Open Power Automate in demo environment
   - Add SQL Server connector action
   - **Key Moment**: Select "Microsoft Entra ID Integrated" authentication
   - **Emphasize**: No username, no password, no credentials!
   - Enter server FQDN and database name
   - Select Customers table

5. **Test Connectivity** (2 min):
   - Execute flow and show 5 customer records returned
   - **Success factors to highlight**:
     - ✅ Authentication happened automatically
     - ✅ Connection used private endpoint (show private IPs)
     - ✅ No credentials stored anywhere
     - ✅ Enterprise-grade security with zero-trust

6. **Explain Architecture** (2 min):
   - Private endpoint ensures traffic stays on Azure backbone
   - DNS resolution shows private IPs (10.200.2.x range)
   - Entra ID provides identity-based access control
   - Zero-trust: no passwords, no secrets, no credentials

7. **Cleanup** (3-5 min if live):
   - Run cleanup script
   - Show resources being removed
   - Mention cost savings (~$19-20/month stopped)

### **Benefits of Dynamic Configuration**:
- ✅ **Independent Demos**: Key Vault and SQL Server demos don't conflict
- ✅ **Isolated Resources**: Each configuration creates separate resources  
- ✅ **Flexible Timing**: Deploy/cleanup independently based on presentation flow
- ✅ **Risk Mitigation**: Always have working demo-prep as backup
- ✅ **Cost Management**: Run only what you need, clean up granularly

## ⚠️ Important Notes

### SQL Server Specific
- **Global Uniqueness**: SQL Server names must be globally unique (timestamp suffix added automatically)
- **Entra ID Admin**: Logged-in Azure CLI user becomes SQL Server administrator
- **No SQL Auth**: SQL authentication is completely disabled (Entra ID only)
- **Public Access**: Disabled by design - only private endpoint connectivity allowed
- **Database Size**: Basic tier limited to 2GB (sufficient for demos)

### Authentication Requirements
- **Power Platform**: Must use "Microsoft Entra ID Integrated" authentication type
- **NOT Managed Identity**: SQL connector doesn't support Managed Identity (only Azure Logic Apps do)
- **User Identity**: Power Platform connections use the user's Entra ID identity
- **Permissions**: User must have database permissions granted (setup script grants to deployment user)

### Cost & Resource Management
- **Estimated Cost**: ~$19-20/month per deployment
  - SQL Database (Basic): ~$5/month
  - Private Endpoints (×2): ~$14/month
- **No Soft Delete**: SQL Server doesn't have soft-delete (unlike Key Vault)
- **Immediate Cleanup**: Resources fully deleted immediately (no purge needed)
- **Resource Group**: Shared with Key Vault demo and VNet infrastructure

### Prerequisites
- **VNet Infrastructure**: Must deploy `ptn-azure-vnet-extension` pattern first
- **Private DNS Zone**: `privatelink.database.windows.net` must exist
- **Entra ID Access**: Must be able to query current user for admin setup
- **Optional Tools**: `sqlcmd` with Entra ID support for advanced testing

## 🚨 Troubleshooting

### Common Issues

#### **Power Platform "Login Failed" Errors**
```bash
# Verify Entra ID admin is configured
az sql server ad-admin show \
  --server-name [SERVER_NAME] \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac

# Ensure using correct authentication type
# ✅ CORRECT: "Microsoft Entra ID Integrated"  
# ❌ WRONG: "SQL Server Authentication"
# ❌ WRONG: "Managed Identity" (not supported for SQL connector)

# Verify your account has access
az sql server show --name [SERVER_NAME] --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac
```

#### **DNS Resolution Shows Public IP**
```bash
# Check private DNS records exist
az network private-dns record-set a show \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --zone-name privatelink.database.windows.net \
  --name [SERVER_NAME]

# Verify private endpoints are connected
az network private-endpoint list \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "[?contains(name,'sql')].{name:name,state:provisioningState,connection:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" -o table

# Check DNS zone is linked to VNets
az network private-dns link vnet list \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --zone-name privatelink.database.windows.net -o table
```

#### **"SQL Server Not Found" During Cleanup**
```bash
# Cleanup script auto-discovers SQL Server with timestamp suffix
# If it fails, manually find the server:
az sql server list \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "[?starts_with(name,'sql-ppcc25-')].name" -o tsv

# Then use the actual server name in verification commands
```

#### **Database Connection Timeout**
```bash
# Verify public network access is disabled
az sql server show --name [SERVER_NAME] \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "publicNetworkAccess" -o tsv
# Should return: "Disabled"

# Check private endpoint status
az network private-endpoint show \
  --name pe-sql-ppcc25-[CONFIG_SHORT]-dev-cac \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "{name:name,state:provisioningState,connection:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}"

# Verify Power Platform environment has enterprise policy enabled
# (Required for VNet integration)
```

#### **"Error acquiring Kerberos credentials" with sqlcmd**
```bash
# ❌ ERROR: Failed to authenticate the user '' in Active Directory
# Error acquiring Kerberos credentials
# Mechanism status: No Kerberos credentials available (default cache: FILE:/tmp/krb5cc_1000)

# ✅ ROOT CAUSE: Using Integrated authentication (-G only) without Kerberos configuration
# This happens in dev containers, Codespaces, or non-domain-joined environments

# ✅ SOLUTION 1: Use Interactive authentication (script now does this automatically)
sqlcmd -S [SERVER_NAME].database.windows.net -d demo-db -G -U your-email@domain.com -C
# This prompts for authentication via device code or browser

# ✅ SOLUTION 2: Let script skip sqlcmd and create table manually later
# The setup script now gracefully handles missing sqlcmd

# 📖 EXPLANATION:
# Microsoft Entra authentication methods:
#   -G -U user@domain.com  = Interactive (works everywhere, may prompt for auth)
#   -G (no -U)            = Integrated (requires Kerberos, domain-joined only)
#   -G -U user -P pass    = Password (requires password management)
#
# Dev containers/Codespaces should use Interactive (-G -U)
# Reference: https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-authentication
```

#### **"Permission Denied" Errors**
```bash
# Verify you're authenticated with correct account
az account show

# Check if you're the Entra ID admin
az sql server ad-admin show \
  --server-name [SERVER_NAME] \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "{admin:login,sid:sid}"

# Grant additional user access if needed (requires SQL admin)
sqlcmd -S [SERVER_NAME].database.windows.net -d demo-db -G -C \
  -Q "CREATE USER [user@domain.com] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [user@domain.com];"
```

#### **Configuration Validation Issues**
```bash
# Verify tfvars file exists and is readable
ls -la configurations/ptn-environment-group/tfvars/[CONFIG].tfvars
ls -la configurations/ptn-azure-vnet-extension/tfvars/[CONFIG].tfvars

# Check workspace name parsing
grep "^name" configurations/ptn-environment-group/tfvars/[CONFIG].tfvars

# Validate VNet infrastructure exists
az network vnet list \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac \
  --query "[].{name:name,location:location,addressSpace:addressSpace.addressPrefixes[0]}" -o table
```

#### **Script Permission Errors**
```bash
# Make scripts executable
chmod +x scripts/demo/setup-sqlserver-private-endpoints.sh
chmod +x scripts/demo/cleanup-sqlserver-private-endpoints.sh

# Check Azure CLI authentication
az account show

# Verify required Azure permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac --output table
```

#### **Cleanup Script Issues**
```bash
# If cleanup fails due to dependencies, manually check:

# 1. Database deletion
az sql db delete --name demo-db --server [SERVER_NAME] \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac --yes

# 2. Private endpoints
az network private-endpoint delete --name pe-sql-ppcc25-[CONFIG_SHORT]-dev-cac \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac

# 3. SQL Server (last)
az sql server delete --name [SERVER_NAME] \
  --resource-group rg-ppcc25-[CONFIG]-dev-vnet-cac --yes
```

## 📚 References

- [Azure SQL Database with Entra ID](https://learn.microsoft.com/azure/azure-sql/database/authentication-aad-overview)
- [SQL Server Private Endpoints](https://learn.microsoft.com/azure/azure-sql/database/private-endpoint-overview)
- [Power Platform SQL Server Connector](https://learn.microsoft.com/connectors/sql/)
- [Microsoft Entra ID Integrated Authentication](https://learn.microsoft.com/power-platform/admin/database-security)
- [Power Platform VNet Integration](https://learn.microsoft.com/power-platform/admin/vnet-support)
- [Azure Private DNS for SQL](https://learn.microsoft.com/azure/dns/private-dns-privatednszone)

---

# 🎯 Demo Selection Guide

## Which Demo Should I Use?

### Use **Key Vault Demo** When:
- ✅ Focusing on **secret management** and secure configuration
- ✅ Demonstrating **Managed Identity** authentication pattern
- ✅ Showing **ClickOps to IaC** transition for secrets
- ✅ **Quick demo** needed (5-10 minutes deployment)
- ✅ Emphasizing **zero-trust security** for credentials

### Use **SQL Server Demo** When:
- ✅ Focusing on **database connectivity** and data integration
- ✅ Demonstrating **Microsoft Entra ID Integrated** authentication
- ✅ Showing **passwordless database access**
- ✅ Have **15-20 minutes** for deployment and demo
- ✅ Emphasizing **modern data platform** integration

### Use **Both Demos** When:
- ✅ Comprehensive **VNet integration** presentation
- ✅ Showing **multiple authentication patterns** (Managed Identity + Entra ID)
- ✅ Demonstrating **diverse use cases** (secrets + data)
- ✅ **Advanced audience** interested in architecture depth
- ✅ Have **30+ minutes** for full demonstration

## Demo Combinations

### 🎬 **Scenario 1**: "Security-First Approach"
**Time**: 15 minutes | **Focus**: Authentication & Security
```bash
# Deploy Key Vault only
./setup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Demo narrative:
# - Managed Identity for secret retrieval
# - Zero-trust principles
# - Private endpoint security
# - ClickOps to IaC transition
```

### 🎬 **Scenario 2**: "Modern Data Platform"  
**Time**: 20 minutes | **Focus**: Database Integration
```bash
# Deploy SQL Server only  
./setup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve

# Demo narrative:
# - Passwordless database access
# - Entra ID Integrated authentication
# - Private connectivity for data
# - Modern data integration patterns
```

### 🎬 **Scenario 3**: "Complete VNet Integration"
**Time**: 30-40 minutes | **Focus**: Comprehensive Architecture
```bash
# Deploy both demos
./setup-keyvault-private-endpoints.sh --tfvars-file live-demo --auto-approve &
./setup-sqlserver-private-endpoints.sh --tfvars-file live-demo --auto-approve &
wait

# Demo narrative:
# Part 1: Key Vault secret management (10 min)
# Part 2: SQL Server database access (10 min)  
# Part 3: Architecture comparison and best practices (10 min)
# - Different auth patterns for different use cases
# - Consistent private networking
# - Zero-trust across all services
```

## 💡 Pro Tips

1. **Pre-Deploy for Safety**: Always deploy `demo-prep` before presentation as backup
2. **Independent Cleanup**: Clean up demos separately based on what you actually used
3. **Cost Management**: Remember both demos together cost ~$30-35/month if left running
4. **Resource Naming**: Timestamp suffix on SQL Server prevents naming conflicts
5. **Authentication Clarity**: Emphasize different auth methods (Managed Identity vs Entra ID Integrated)

---

**🎯 Both demos share the same VNet infrastructure and resource group - keeping your Azure environment clean and organized!**