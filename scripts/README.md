# Power Platform Terraform Governance - Setup Scripts

This directory contains automated setup scripts to quickly configure the Power Platform Terraform governance solution. These scripts will set up all the necessary Azure resources, service principals, and GitHub secrets required to run the Terraform configurations.

## ⚠️ **Important: Fresh Setup Only**

**These scripts are designed for creating NEW resources from scratch and do NOT support using existing resources:**

- ✅ **Creates NEW Service Principal** - No option to use existing service principal
- ✅ **Creates NEW Storage Account** - No option to use existing storage account  
- ✅ **Creates NEW Resource Group** - No option to use existing resource group
- ✅ **Creates NEW GitHub Secrets** - Overwrites existing secrets with same names

**Why this approach?**
- **Exploration Focus**: Perfect for learning and testing scenarios
- **Clean Environment**: Ensures consistent, predictable setup
- **Easy Cleanup**: All resources can be deleted cleanly after exploration
- **No Conflicts**: Avoids issues with existing resource configurations
- **Security**: Fresh credentials eliminate potential security issues

**For Production Use**: Consider adapting these scripts or manually configuring existing resources with the same permissions and settings.

## Prerequisites

Before running these scripts, ensure you have the following tools installed and configured:

### Required Tools
- **Azure CLI** (`az`) - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Power Platform CLI** (`pac`) - [Installation Guide](https://docs.microsoft.com/en-us/power-platform/developer/cli/introduction)
- **GitHub CLI** (`gh`) - [Installation Guide](https://cli.github.com/)
- **jq** - JSON processor for parsing responses
- **openssl** - For generating random values

### Required Permissions
- **Azure**: Owner or Contributor + User Access Administrator on the Azure subscription
- **Azure AD**: Global Administrator or Application Administrator (for Graph API permissions)
- **Power Platform**: Tenant Administrator privileges
- **GitHub**: Admin access to the target repository

### Authentication
Before running the setup, authenticate with all required services:

```bash
# Azure authentication
az login

# Power Platform authentication (with tenant admin account)
pac auth create --url https://your-tenant.crm.dynamics.com

# GitHub authentication
gh auth login
```

## Quick Start

For a complete automated setup, run the main setup script:

```bash
./setup.sh
```

This will guide you through the entire setup process, running all individual scripts in the correct order.

## Script Behavior Analysis

### Resource Creation vs. Existing Resources

#### 1. Service Principal Script (`01-create-service-principal.sh`)
- **Always creates NEW service principal** using `az ad sp create-for-rbac`
- **No check for existing service principal** with the same name
- **Fails if service principal with same name already exists**
- **Creates new federated credentials** (overwrites if app already exists)
- **Registers with Power Platform** (safe if already registered)

#### 2. Terraform Backend Script (`02-create-terraform-backend.sh`)
- **Always creates NEW resource group** (skips if already exists with warning)
- **Always creates NEW storage account** (skips if already exists with warning)
- **Always creates NEW storage container** (skips if already exists with warning)
- **No validation of existing resource compatibility**

#### 3. GitHub Secrets Script (`03-create-github-secrets.sh`)
- **Always creates/overwrites GitHub secrets** using `gh secret set`
- **No backup of existing secrets**
- **Replaces any existing secrets with same names**
- **Creates new GitHub environment** (updates if already exists)

### Idempotency Behavior

| Script | Resource | Behavior if Exists | Idempotent |
|--------|----------|-------------------|------------|
| Script 1 | Service Principal | **FAILS** | ❌ No |
| Script 1 | Federated Credentials | **OVERWRITES** | ⚠️ Partial |
| Script 2 | Resource Group | **SKIPS** | ✅ Yes |
| Script 2 | Storage Account | **SKIPS** | ✅ Yes |
| Script 2 | Storage Container | **SKIPS** | ✅ Yes |
| Script 3 | GitHub Secrets | **OVERWRITES** | ⚠️ Partial |
| Script 3 | GitHub Environment | **UPDATES** | ✅ Yes |

### Cleanup Instructions

Since these scripts create NEW resources, you may want to clean up after exploration:

### 1. Service Principal Cleanup
```bash
# List service principals (find your SP)
az ad sp list --display-name "terraform-powerplatform-sp" --query "[].{DisplayName:displayName, AppId:appId, ObjectId:id}" --output table

# Delete the service principal
az ad sp delete --id "<service-principal-object-id>"

# Or by app ID
az ad sp delete --id "<client-id>"
```

### 2. Azure Resource Cleanup
```bash
# Delete the entire resource group (removes storage account and container)
az group delete --name "rg-terraform-backend" --yes --no-wait

# Or delete individual resources
az storage account delete --name "<storage-account-name>" --resource-group "rg-terraform-backend"
```

### 3. GitHub Secrets Cleanup
```bash
# List repository secrets
gh secret list

# Delete individual secrets
gh secret delete AZURE_CLIENT_ID
gh secret delete AZURE_TENANT_ID
gh secret delete AZURE_SUBSCRIPTION_ID
gh secret delete TERRAFORM_BACKEND_CONFIG

# Delete GitHub environment
gh api repos/:owner/:repo/environments/production --method DELETE
```

### 4. Power Platform Cleanup
The service principal registration with Power Platform will be removed automatically when the service principal is deleted from Azure AD.

### Cost Considerations

- **Service Principal**: Free
- **Storage Account**: ~$0.05/month for minimal usage
- **GitHub Secrets**: Free (part of GitHub repository)
- **Resource Group**: Free (container only)

**Total Monthly Cost**: < $0.10 for exploration purposes

## Individual Scripts

You can also run the individual scripts if you prefer a step-by-step approach:

### 1. Create Service Principal (`01-create-service-principal.sh`)

Creates an Azure AD Service Principal with:
- **Owner role** at subscription level for comprehensive governance capabilities
- **Microsoft Graph API permissions** for Entra ID security group management
- OIDC trust configuration for GitHub Actions
- Power Platform tenant admin registration

```bash
./01-create-service-principal.sh
```

**What it does:**
- Creates a new Service Principal in Azure AD with Owner permissions
- Configures federated credentials for GitHub OIDC
- Assigns Owner role (includes Contributor + User Access Administrator)
- Grants Microsoft Graph API permissions for security group management
- Provides admin consent for Graph API permissions
- Registers the Service Principal with Power Platform using `pac admin application register`

**Security Considerations:**
- **Owner Role**: Required for comprehensive Power Platform governance scenarios
- **Graph API Permissions**: Enables Entra ID security group creation and management
- **Capabilities**: Enables Azure resource deployment, identity management, and access control
- **Admin Consent**: Required for Graph API permissions (may need Global Admin role)
- **OIDC Authentication**: No long-lived secrets, uses secure token exchange

**Required Permissions:**
- Azure subscription Owner or Contributor + User Access Administrator
- Azure AD Global Administrator or Application Administrator (for Graph API consent)

### 2. Create Terraform Backend (`02-create-terraform-backend.sh`)

Creates Azure resources for Terraform state storage:
- Resource Group
- Storage Account with security best practices
- Storage Container for state files

```bash
./02-create-terraform-backend.sh
```

**What it does:**
- Creates a dedicated Resource Group for Terraform state
- Creates a secure Storage Account with versioning and soft delete
- Creates a private Storage Container
- Configures proper access permissions for the Service Principal

### 3. Create GitHub Secrets (`03-create-github-secrets.sh`)

Creates all required GitHub repository secrets:
- Azure authentication credentials
- Power Platform authentication credentials
- Terraform backend configuration

```bash
./03-create-github-secrets.sh
```

**What it does:**
- Creates GitHub repository secrets for Azure and Power Platform authentication
- Stores Terraform backend configuration
- Creates a production environment for additional security

## Created Resources

After running the setup scripts, the following resources will be created:

### Azure Resources
- **Service Principal**: `terraform-powerplatform-governance` (or custom name)
- **Resource Group**: `rg-terraform-powerplatform-governance`
- **Storage Account**: `stterraformpp<random>` with security features enabled
- **Storage Container**: `terraform-state` for Terraform state files

### Power Platform
- **Registered Application**: Service Principal registered with tenant admin privileges

### GitHub Secrets
- `AZURE_CLIENT_ID` - Service Principal Client ID
- `AZURE_TENANT_ID` - Azure Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `POWER_PLATFORM_CLIENT_ID` - Same as Azure Client ID
- `POWER_PLATFORM_TENANT_ID` - Same as Azure Tenant ID
- `TERRAFORM_RESOURCE_GROUP` - Resource Group for Terraform state
- `TERRAFORM_STORAGE_ACCOUNT` - Storage Account for Terraform state
- `TERRAFORM_CONTAINER` - Storage Container for Terraform state

## Security Considerations

The setup scripts follow security best practices:

### Service Principal
- Uses OIDC authentication (no long-lived secrets)
- **Owner role at subscription level** for comprehensive governance capabilities
- **Microsoft Graph API permissions** for Entra ID security group management
- Scoped to specific subscription and directory tenant
- Required for Azure resource deployment, identity management, and security group operations

### Storage Account
- Private access only (no public blob access)
- TLS 1.2 minimum encryption
- Versioning enabled for state history
- Soft delete enabled for recovery

### GitHub Secrets
- All sensitive values stored as GitHub secrets
- Production environment protection available
- OIDC authentication for workflows

## Troubleshooting

### Common Issues

1. **Azure CLI not authenticated**
   ```bash
   az login
   ```

2. **Power Platform CLI not authenticated**
   ```bash
   pac auth create --url https://your-tenant.crm.dynamics.com
   ```

3. **GitHub CLI not authenticated**
   ```bash
   gh auth login
   ```

4. **Insufficient permissions**
   - Ensure you have Contributor access to Azure subscription
   - Ensure you have Power Platform tenant admin privileges
   - Ensure you have admin access to the GitHub repository

5. **Storage account name conflicts**
   - Storage account names must be globally unique
   - The script generates random suffixes to avoid conflicts
   - If issues persist, try running the script again

### Verification

After setup, verify the configuration:

1. **Azure Portal**: Check that the Service Principal and resources were created
2. **Power Platform Admin Center**: Verify the application registration
3. **GitHub Repository**: Confirm all secrets are present in Settings > Secrets
4. **GitHub Actions**: Try running the workflow to test the configuration

## Next Steps

After completing the setup:

1. Review the created resources in the Azure Portal
2. Check the GitHub secrets in your repository settings
3. Run the "Terraform Plan and Apply" GitHub Actions workflow
4. Choose a configuration (e.g., `02-dlp-policy`) and tfvars file
5. Monitor the workflow execution in the Actions tab

## Resource Management and Cleanup

### Created Resources That Need Management
- **Azure AD Service Principal**: `terraform-powerplatform-governance` (or custom name)
- **Azure Resource Group**: `rg-terraform-powerplatform-governance`
- **Azure Storage Account**: `stterraformpp<random>` (globally unique name)
- **Power Platform App Registration**: Registered application with tenant admin privileges
- **GitHub Secrets**: 8 repository secrets for CI/CD authentication

### Cleanup Instructions
When you're done exploring, clean up the resources to avoid ongoing costs:

```bash
# 1. Delete the Azure Resource Group (includes storage account)
az group delete --name rg-terraform-powerplatform-governance --yes --no-wait

# 2. Delete the Service Principal
az ad sp delete --id <service-principal-client-id>

# 3. Unregister from Power Platform (optional)
pac admin application unregister --application-id <service-principal-client-id>

# 4. Delete GitHub Secrets (manual via GitHub UI or CLI)
gh secret delete AZURE_CLIENT_ID --repo owner/repo
gh secret delete AZURE_TENANT_ID --repo owner/repo
# ... repeat for all secrets
```

### Cost Considerations
- **Storage Account**: Minimal cost (~$1-5/month) for Terraform state files
- **Service Principal**: Free (no direct costs)
- **GitHub Actions**: Free tier includes 2000 minutes/month
- **Power Platform**: Uses existing tenant (no additional cost for app registration)

## Script Structure

```
scripts/
├── README.md                          # This file
├── setup.sh                           # Main orchestration script
├── 01-create-service-principal.sh     # Azure AD and Power Platform setup
├── 02-create-terraform-backend.sh     # Azure storage resources
└── 03-create-github-secrets.sh        # GitHub repository secrets
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the script output for specific error messages
3. Verify all prerequisites are met
4. Check the main project README for additional documentation

## Contributing

When modifying these scripts:
1. Follow the existing error handling patterns
2. Maintain the colored output format
3. Add appropriate validation for user inputs
4. Update this README with any new requirements or changes
