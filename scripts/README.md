# Power Platform Terraform Governance - Setup Scripts

This directory contains automated setup scripts to quickly configure the Power Platform Terraform governance solution. These scripts will set up all the necessary Azure resources, service principals, and GitHub secrets required to run the Terraform configurations.

## Prerequisites

Before running these scripts, ensure you have the following tools installed and configured:

### Required Tools
- **Azure CLI** (`az`) - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Power Platform CLI** (`pac`) - [Installation Guide](https://docs.microsoft.com/en-us/power-platform/developer/cli/introduction)
- **GitHub CLI** (`gh`) - [Installation Guide](https://cli.github.com/)
- **jq** - JSON processor for parsing responses
- **openssl** - For generating random values

### Required Permissions
- **Azure**: Contributor access to the Azure subscription
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

## Individual Scripts

You can also run the individual scripts if you prefer a step-by-step approach:

### 1. Create Service Principal (`01-create-service-principal.sh`)

Creates an Azure AD Service Principal with:
- OIDC trust configuration for GitHub Actions
- Required Azure permissions for Terraform
- Power Platform tenant admin registration

```bash
./01-create-service-principal.sh
```

**What it does:**
- Creates a new Service Principal in Azure AD
- Configures federated credentials for GitHub OIDC
- Assigns necessary Azure roles
- Registers the Service Principal with Power Platform using `pac admin application register`

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
- Follows principle of least privilege
- Scoped to specific subscription and resources

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
