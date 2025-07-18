# Power Platform Terraform Governance - Setup Guide

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

This guide walks you through the manual setup process for the Power Platform Terraform governance infrastructure. Use this when you prefer step-by-step control or need to understand each component.

## 🎯 Purpose

This setup creates the complete infrastructure needed for Power Platform governance using Terraform:

- **Azure AD Service Principal** with OIDC authentication for GitHub Actions
- **Terraform Backend Storage** with Just-In-Time (JIT) network access
- **GitHub Repository Secrets** for secure CI/CD operations
- **Power Platform Integration** for governance automation

## ⚡ Quick Start (Automated)

If you want the fastest setup experience:

```bash
# Copy configuration template
cp config.env.example config.env

# Edit with your values (only GitHub owner/repo required)
vim config.env

# Run complete automated setup
./scripts/setup/setup.sh
```

**Continue reading for manual step-by-step approach.**

## 📋 Prerequisites

Before starting setup, ensure you have:

### Required Tools
- **Azure CLI** >= 2.50.0 installed and configured
- **Power Platform CLI** installed and configured  
- **Git** for repository operations
- **Bash shell** (Linux, macOS, or WSL on Windows)

### Required Permissions
- **Azure subscription** with appropriate permissions to:
  - Create service principals and app registrations
  - Assign roles at subscription level
  - Create resource groups and storage accounts
- **Power Platform tenant admin** access for governance operations
- **GitHub repository** with admin access for secrets management

### Authentication Requirements
- **Azure CLI** authenticated: `az login`
- **Power Platform CLI** authenticated: `pac auth create`
- **GitHub CLI** (optional but recommended): `gh auth login`

## 🔧 Manual Setup Process

### Step 1: Configure Your Environment

1. **Copy the configuration template:**
   ```bash
   cp config.env.example config.env
   ```

2. **Edit the configuration file:**
   ```bash
   vim config.env
   ```

3. **Required configuration:**
   ```bash
   # Minimum required configuration
   GITHUB_OWNER="your-github-username"
   GITHUB_REPO="your-repo-name"
   ```

4. **Optional configuration (uses sensible defaults):**
   ```bash
   # Azure (uses current CLI context if empty)
   AZURE_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
   AZURE_TENANT_ID="11111111-1111-1111-1111-111111111111"
   
   # Service Principal (auto-generated if empty)
   SP_NAME="terraform-powerplatform-governance"
   
   # Terraform Backend (auto-generated if empty)
   RESOURCE_GROUP_NAME="rg-terraform-powerplatform-governance"
   STORAGE_ACCOUNT_NAME=""  # Auto-generates unique name
   CONTAINER_NAME="terraform-state"
   LOCATION="East US"
   ```

### Step 2: Create Service Principal with OIDC

This creates an Azure AD service principal with OIDC authentication for GitHub Actions.

```bash
./scripts/setup/01-create-service-principal-config.sh
```

**What this script does:**
- Creates Azure AD App Registration
- Configures Microsoft Graph API permissions for Power Platform governance
- Sets up OIDC federated credentials for GitHub Actions
- Assigns subscription-level Owner role for resource management
- Registers application with Power Platform for governance operations

**Time estimate:** 3-5 minutes

**Success indicators:**
- ✅ Service principal created with OIDC authentication
- ✅ Microsoft Graph permissions granted and consented
- ✅ GitHub OIDC federated credentials configured
- ✅ Power Platform app registration completed

### Step 3: Create Terraform Backend Storage

This creates Azure storage infrastructure for Terraform state management.

```bash
./scripts/setup/02-create-terraform-backend-config.sh
```

**What this script does:**
- Creates Azure resource group with governance tags
- Deploys storage account using Azure Verified Modules (AVM) Bicep template
- Configures network access controls with JIT (Just-In-Time) access
- Creates blob container for Terraform state files
- Assigns appropriate permissions to service principal

**Time estimate:** 2-4 minutes

**Success indicators:**
- ✅ Resource group created with proper tags
- ✅ Storage account deployed with network restrictions
- ✅ Blob container created for state files
- ✅ Service principal permissions configured

### Step 4: Configure GitHub Repository Secrets

This configures GitHub repository secrets for secure CI/CD operations.

```bash
./scripts/setup/03-create-github-secrets-config.sh
```

**What this script does:**
- Creates repository-level secrets for Azure and Power Platform authentication
- Configures environment protection rules for production deployments
- Sets up environment-specific secrets for different deployment targets
- Validates secret accessibility and permissions

**Time estimate:** 1-2 minutes

**Success indicators:**
- ✅ Repository secrets created and validated
- ✅ Environment protection rules configured
- ✅ Environment secrets set up for controlled deployments

## 🔍 Validation and Testing

After completing setup, validate your configuration:

```bash
./scripts/setup/validate-setup.sh
```

**What validation checks:**
- Service principal authentication and permissions
- Terraform backend connectivity and access
- GitHub secrets accessibility
- Power Platform integration functionality
- Network access controls (JIT functionality)

## 🛠️ Advanced Configuration

### Custom Resource Naming

If you need custom naming for Azure resources:

```bash
# In config.env
RESOURCE_GROUP_NAME="rg-custom-terraform-backend"
STORAGE_ACCOUNT_NAME="stcustomterraform123"  # Must be globally unique
CONTAINER_NAME="custom-state-container"
```

### Different Azure Subscription

To use a specific Azure subscription:

```bash
# Set subscription before running setup
az account set --subscription "your-subscription-id"

# Or specify in config.env
AZURE_SUBSCRIPTION_ID="your-subscription-id"
```

### Custom Service Principal Permissions

The setup automatically assigns subscription-level Owner role. For custom permissions:

1. **Edit the service principal script:** Modify `scripts/setup/01-create-service-principal-config.sh`
2. **Adjust role assignments:** Change from Owner to specific roles
3. **Update Graph API permissions:** Modify the `GRAPH_PERMISSIONS` array as needed

### Environment-Specific Configuration

For multiple environments (dev, staging, prod):

1. **Create separate config files:**
   ```bash
   cp config.env config-dev.env
   cp config.env config-prod.env
   ```

2. **Use different resource names:**
   ```bash
   # config-dev.env
   RESOURCE_GROUP_NAME="rg-terraform-powerplatform-dev"
   
   # config-prod.env  
   RESOURCE_GROUP_NAME="rg-terraform-powerplatform-prod"
   ```

3. **Run setup with specific config:**
   ```bash
   CONFIG_FILE="config-dev.env" ./scripts/setup/setup.sh
   ```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### **Authentication Errors**

**Problem:** Azure CLI not authenticated
```bash
Error: Azure CLI authentication failed
```

**Solution:**
```bash
az login
az account show  # Verify correct subscription
```

**Problem:** Power Platform CLI not authenticated
```bash
Error: Power Platform authentication failed
```

**Solution:**
```bash
pac auth create
pac auth list  # Verify authentication
```

#### **Permission Issues**

**Problem:** Insufficient Azure permissions
```bash
Error: Forbidden - insufficient privileges
```

**Solution:**
- Ensure you have subscription Owner or Contributor + User Access Administrator roles
- Contact your Azure administrator for proper permissions

**Problem:** Graph API permissions denied
```bash
Error: Admin consent required for Graph API permissions
```

**Solution:**
- The setup script handles admin consent automatically
- If still failing, manually grant consent in Azure Portal:
  1. Go to Azure AD > App registrations
  2. Find your app > API permissions
  3. Click "Grant admin consent"

#### **Storage Account Issues**

**Problem:** Storage account name conflicts
```bash
Error: Storage account name already exists
```

**Solution:**
- Storage account names must be globally unique
- Leave `STORAGE_ACCOUNT_NAME` empty in config.env for auto-generation
- Or choose a more unique name

**Problem:** Network access issues
```bash
Error: Network access denied to storage account
```

**Solution:**
- The setup configures JIT (Just-In-Time) access
- Network rules deny access by default for security
- GitHub Actions automatically manage IP allowlisting

#### **GitHub Issues**

**Problem:** GitHub repository not found
```bash
Error: Repository not accessible
```

**Solution:**
- Verify `GITHUB_OWNER` and `GITHUB_REPO` in config.env
- Ensure you have admin access to the repository
- Check if repository exists and is accessible

**Problem:** GitHub secrets creation fails
```bash
Error: Failed to create repository secrets
```

**Solution:**
- Install GitHub CLI: `gh auth login`
- Or manually create secrets in GitHub repository settings
- Required secrets are listed in the script output

### Getting Help

If you encounter issues not covered here:

1. **Check script logs:** All scripts provide detailed output and error messages
2. **Run validation:** Use `./scripts/setup/validate-setup.sh` to identify specific issues
3. **Review configuration:** Verify all values in `config.env` are correct
4. **Check prerequisites:** Ensure all required tools and permissions are in place

## 📚 Next Steps

After successful setup:

1. **Deploy your first governance policy:**
   - Go to your GitHub repository
   - Navigate to Actions tab
   - Run "Terraform Plan and Apply" workflow
   - Choose a configuration (e.g., `02-dlp-policy`)
   - Select an environment (e.g., `dlp-finance`)

2. **Explore available configurations:**
   - DLP policies: `configurations/02-dlp-policy/`
   - Environment management: `configurations/03-environment/`

3. **Create custom configurations:**
   - Follow the pattern in existing configurations
   - Add your own Terraform configurations
   - Use the established tfvars strategy

## 🔄 Cleanup and Teardown

To remove all created resources:

```bash
# Run the cleanup script
./scripts/cleanup/cleanup.sh

# Or clean individual components
./scripts/cleanup/cleanup-github-secrets-config.sh
./scripts/cleanup/cleanup-terraform-backend-config.sh  
./scripts/cleanup/cleanup-service-principal-config.sh
```

**Warning:** Cleanup permanently deletes all Terraform state files and Azure resources. This action cannot be undone.

## 📖 Additional Resources

- **Main repository documentation:** [README.md](../../README.md)
- **Configuration examples:** [configurations/](../../configurations/)
- **ROI justification:** [../explanations/setup-automation-roi-justification.md](../explanations/setup-automation-roi-justification.md)
- **Terraform provider documentation:** [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)

---

*This setup guide follows the Diataxis framework as a How-to Guide - providing step-by-step instructions to accomplish the specific task of setting up Power Platform Terraform governance infrastructure.*
