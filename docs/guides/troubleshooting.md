# Troubleshooting Guide

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

**Purpose**: Solutions for common issues when using Terraform with Power Platform  
**Audience**: Anyone experiencing issues with setup, deployment, or operations  
**Format**: Problem → Solution with step-by-step fixes

---

## 🚨 Quick Diagnostic

Before diving into specific issues, run these quick checks:

```bash
# Check tool versions
terraform version    # Should be >= 1.5.0
az --version        # Should be >= 2.50.0
gh --version        # Optional but helpful

# Check authentication
az account show     # Should show your subscription
gh auth status      # Should show logged in

# Check repository
git remote -v       # Should show your fork
git status          # Should show clean or known changes
```

---

## Authentication Issues

### Error: "Azure CLI authentication failed"

**Symptom**:
```
Error: Azure CLI authentication failed
Unable to get subscription information
```

**Cause**: Not logged into Azure CLI or wrong subscription selected

**Solution**:
```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "Your Subscription Name"

# Verify
az account show
```

---

### Error: "AADSTS700016: Application not found"

**Symptom**:
```
Error: AADSTS700016: Application with identifier '...' was not found
```

**Cause**: Service principal not created or incorrectly configured

**Solution**:

1. **Verify service principal exists**:
   ```bash
   az ad sp list --display-name "terraform-powerplatform-governance" --output table
   ```

2. **If not found, recreate**:
   ```bash
   # Re-run setup
   ./setup.sh
   
   # Or run specific script
   ./scripts/setup/01-create-service-principal-config.sh
   ```

3. **Verify GitHub secrets**:
   - Go to GitHub Settings → Secrets
   - Check `AZURE_CLIENT_ID` matches service principal
   - Check `AZURE_TENANT_ID` is correct

---

### Error: "Power Platform authentication failed"

**Symptom**:
```
Error: Failed to authenticate with Power Platform
OIDC authentication failed
```

**Cause**: Missing or incorrect Power Platform environment variables

**Solution**:

1. **Check GitHub secrets**:
   ```
   POWER_PLATFORM_CLIENT_ID      # Should match service principal
   POWER_PLATFORM_TENANT_ID      # Should match Azure tenant
   ```

2. **Verify service principal has Power Platform admin**:
   - Go to https://admin.powerplatform.microsoft.com
   - Settings → Security roles
   - Verify service principal has System Administrator role

3. **Re-register application**:
   ```bash
   # Run the registration script
   ./scripts/setup/01-create-service-principal-config.sh
   ```

---

### Error: "Insufficient privileges to complete the operation"

**Symptom**:
```
Error: Forbidden - insufficient privileges
403 Forbidden
```

**Cause**: Service principal lacks required permissions

**Solution**:

1. **Check Azure role assignments**:
   ```bash
   # Check current roles
   az role assignment list \
     --assignee $(az ad sp list --display-name "terraform-powerplatform-governance" --query "[0].appId" -o tsv) \
     --output table
   ```

2. **Required roles**:
   - Subscription: Owner or Contributor + User Access Administrator
   - Power Platform: System Administrator

3. **Assign missing roles**:
   ```bash
   # Assign Contributor role (example)
   az role assignment create \
     --assignee <service-principal-app-id> \
     --role "Contributor" \
     --scope "/subscriptions/<subscription-id>"
   ```

---

## Setup Script Issues

### Error: "Permission denied: setup.sh"

**Symptom**:
```bash
$ ./setup.sh
bash: ./setup.sh: Permission denied
```

**Solution**:
```bash
# Make script executable
chmod +x setup.sh

# Verify
ls -la setup.sh  # Should show -rwxr-xr-x

# Run again
./setup.sh
```

---

### Error: "config.env: No such file or directory"

**Symptom**:
```
Error: config.env file not found
```

**Solution**:
```bash
# Copy the example file
cp config.env.example config.env

# Edit with your values
nano config.env

# Required: Set GITHUB_OWNER and GITHUB_REPO
```

---

### Error: "Storage account name already exists"

**Symptom**:
```
Error: Storage account name 'stterraformxxx' already exists
```

**Cause**: Storage account names must be globally unique across all of Azure

**Solution**:

1. **Let script auto-generate** (easiest):
   ```bash
   # In config.env, leave empty:
   STORAGE_ACCOUNT_NAME=""
   ```

2. **Choose a more unique name**:
   ```bash
   # In config.env, use company/project prefix:
   STORAGE_ACCOUNT_NAME="stmycompanytf${RANDOM}"
   ```

3. **Use existing storage account**:
   ```bash
   # If you already have one, use it:
   STORAGE_ACCOUNT_NAME="your-existing-storage-account"
   ```

---

## Terraform Issues

### Error: "Backend initialization failed"

**Symptom**:
```
Error: Error building ARM Config: obtain subscription
```

**Cause**: Cannot access Terraform backend storage

**Solution**:

1. **Check storage account exists**:
   ```bash
   az storage account show \
     --name <your-storage-account> \
     --resource-group <your-resource-group>
   ```

2. **Check network access**:
   ```bash
   # Temporarily allow your IP
   az storage account network-rule add \
     --account-name <storage-account> \
     --resource-group <resource-group> \
     --ip-address $(curl -s ifconfig.me)
   ```

3. **Verify GitHub Actions network access**:
   - JIT (Just-In-Time) access should be configured
   - Check workflow logs for network errors

---

### Error: "Resource already exists"

**Symptom**:
```
Error: A resource with the ID "..." already exists
```

**Cause**: Resource was created manually or in another Terraform run

**Solution**:

**Option 1: Import existing resource** (recommended):
```bash
# Import into Terraform state
terraform import \
  powerplatform_data_loss_prevention_policy.policy \
  <policy-id>
```

**Option 2: Remove from state if it's wrong**:
```bash
# Check what's in state
terraform state list

# Remove incorrect resource
terraform state rm powerplatform_data_loss_prevention_policy.policy

# Re-apply
terraform apply
```

**Option 3: Delete and recreate**:
- Delete the resource manually in Admin Center
- Run `terraform apply` again

---

### Error: "Resource not found" after successful apply

**Symptom**:
```
Apply complete! Resources: 1 added
But the resource doesn't appear in Power Platform Admin Center
```

**Cause**: Replication delay

**Solution**:

Wait 1-2 minutes, then:

1. **Refresh Admin Center** (Ctrl+F5 or Cmd+Shift+R)
2. **Check the correct tenant** (top-right selector)
3. **Look in the right place**:
   - DLP Policies: Policies → Data policies
   - Environments: Environments list
4. **Verify with Terraform**:
   ```bash
   terraform show | grep <resource-name>
   ```

---

## GitHub Actions Issues

### Error: "Workflow run failed: authentication error"

**Symptom**:
```
Error: Azure login failed
Run failed: authentication could not be completed
```

**Cause**: OIDC not configured or GitHub secrets incorrect

**Solution**:

1. **Verify federated credentials**:
   ```bash
   az ad app federated-credential list \
     --id <app-id> \
     --output table
   ```

2. **Should see**:
   - Subject: `repo:owner/repo:ref:refs/heads/main`
   - Issuer: `https://token.actions.githubusercontent.com`

3. **Recreate if missing**:
   ```bash
   ./scripts/setup/01-create-service-principal-config.sh
   ```

---

### Error: "Secret not found"

**Symptom**:
```
Error: Secret AZURE_CLIENT_ID is not set
```

**Cause**: GitHub secrets not created or incorrect

**Solution**:

1. **Check secrets exist**:
   - Go to GitHub repo
   - Settings → Secrets and variables → Actions
   - Verify all required secrets are listed

2. **Recreate secrets**:
   ```bash
   ./scripts/setup/03-create-github-secrets-config.sh
   ```

3. **Or create manually**:
   - Get values from Azure:
     ```bash
     az account show --query "{tenant:tenantId, subscription:id}" -o json
     az ad sp list --display-name "terraform-powerplatform-governance" --query "[0].appId" -o tsv
     ```
   - Add to GitHub Settings → Secrets

---

### Error: "Configuration not found"

**Symptom**:
```
Error: Configuration path does not exist
configurations/res-dlp-policy not found
```

**Cause**: Incorrect configuration name in workflow input

**Solution**:

1. **Check available configurations**:
   ```bash
   ls -d configurations/*/
   ```

2. **Use exact folder name**:
   - ✅ `res-dlp-policy` (correct)
   - ❌ `res-dlp-policies` (incorrect)
   - ❌ `dlp-policy` (incorrect)

3. **Case-sensitive**: Must match exactly

---

## Power Platform Specific Issues

### Error: "Environment creation timeout"

**Symptom**:
```
Error: Timeout while waiting for environment to be created
Operation took longer than 30 minutes
```

**Cause**: Environment provisioning can take 10-15 minutes (normal)

**Solution**:

1. **This is normal** for environments with Dataverse
2. **Check status in Admin Center**:
   - Environment may still be provisioning
   - Look for "Preparing" or "Creating" status
3. **Wait for completion**:
   - Don't cancel the workflow
   - Environments can take up to 15 minutes
4. **If truly stuck after 30 minutes**:
   - Check Power Platform service health
   - Try again later
   - Contact Microsoft support if persistent

---

### Error: "Cannot delete system user"

**Symptom**:
```
Error: User with SystemUserId= is not disabled
Failed to delete system user for application
```

**Cause**: Platform requires specific deletion sequence for application admins

**Solution**:

**This is a known limitation** - manual cleanup required:

1. **Go to Power Platform Admin Center**
2. **For each environment**:
   - Navigate to environment → Settings
   - Users + permissions → Application users
   - Find the application user
   - Delete manually
3. **Then run Terraform destroy**:
   ```bash
   terraform destroy -var-file="tfvars/yourfile.tfvars"
   ```

**Alternative - Remove from state**:
```bash
terraform state list  # Find resource names
terraform state rm 'module.environment_application_admin[...].powerplatform_environment_application_admin.this'
terraform destroy  # Remove remaining resources
```

See: [Known Limitations](../explanations/known-limitations.md#application-admin-resource-teardown-blocking)

---

### Error: "DLP policy conflicts detected"

**Symptom**:
```
Error: Data Loss Prevention policy conflicts with existing policy
```

**Cause**: Policy with same name already exists

**Solution**:

**Option 1: Use different name**:
```hcl
# In your tfvars file
display_name = "My Policy - Terraform Managed"  # Add suffix
```

**Option 2: Remove existing policy**:
1. Go to Admin Center
2. Policies → Data policies
3. Delete the conflicting policy
4. Re-run Terraform apply

**Option 3: Import existing** (if you want to manage it):
```bash
# Note: Import not currently supported for DLP policies
# Use Option 1 or 2 above
```

---

## Configuration Issues

### Error: "Connector ID not valid"

**Symptom**:
```
Error: Connector ID is not valid or not available
```

**Cause**: Incorrect connector ID or connector not available in your region

**Solution**:

1. **Export all available connectors**:
   ```bash
   # Deploy utl-export-connectors configuration
   # This creates a list of all valid connector IDs
   ```

2. **Verify ID format**:
   ```hcl
   # Correct:
   "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
   
   # Incorrect:
   "shared_sharepointonline"  # Missing prefix
   "SharePoint Online"        # Display name, not ID
   ```

3. **Check connector availability**:
   - Some connectors are region-specific
   - Some require specific licenses
   - Check connector is not deprecated

---

### Error: "Invalid environment ID"

**Symptom**:
```
Error: Environment ID is not valid
```

**Cause**: Incorrect environment ID format or environment doesn't exist

**Solution**:

1. **Get environment IDs from Admin Center**:
   - Go to https://admin.powerplatform.microsoft.com
   - Environments
   - Click environment name
   - Copy GUID from URL or details pane

2. **Verify format**:
   ```hcl
   # Correct (GUID format):
   "d55dae23-ebcf-e76d-b63d-bece332f560c"
   
   # Incorrect:
   "My Dev Environment"  # Display name, not ID
   "https://..."         # URL, not ID
   ```

3. **Check environment exists**:
   ```bash
   # List all environments
   pac admin list
   ```

---

## Network and Connectivity Issues

### Error: "Network access denied to storage account"

**Symptom**:
```
Error: This request is not authorized to perform this operation
Status code: 403
```

**Cause**: IP address not allowlisted for storage account access

**Solution**:

1. **For local development**:
   ```bash
   # Add your IP to storage account
   az storage account network-rule add \
     --account-name <storage-account> \
     --ip-address $(curl -s ifconfig.me)
   ```

2. **For GitHub Actions**:
   - JIT access should handle this automatically
   - Check workflow logs for JIT access errors
   - Verify JIT action is in your workflow

3. **Check firewall rules**:
   ```bash
   az storage account show \
     --name <storage-account> \
     --query "networkRuleSet"
   ```

---

## Performance Issues

### Slow Terraform operations

**Symptom**: Terraform plan/apply takes a very long time

**Solutions**:

1. **Reduce parallelism**:
   ```bash
   terraform apply -parallelism=5
   ```

2. **Check network latency**:
   ```bash
   # Test connectivity to Azure
   az account show
   
   # Test connectivity to Power Platform
   curl -s https://api.powerplatform.com
   ```

3. **Clear Terraform cache**:
   ```bash
   rm -rf .terraform
   terraform init
   ```

---

## Validation and Testing Issues

### Error: "Variable validation failed"

**Symptom**:
```
Error: Invalid value for variable
```

**Cause**: Input doesn't meet validation requirements

**Solution**:

1. **Check validation rules** in `variables.tf`
2. **Common validations**:
   ```hcl
   # Display name max 50 characters
   display_name = "Short name"  # Not 60+ characters
   
   # Language code must be valid
   language_code = 1033  # Not "en-US"
   
   # Currency code format
   currency_code = "USD"  # Not "US Dollar"
   ```

3. **Read error message carefully** - it tells you what's wrong

---

## Getting More Help

### 1. Check Documentation

- **[Setup Guide](setup-guide.md)** - Complete setup process
- **[DLP Policy Management](dlp-policy-management.md)** - DLP-specific issues
- **[Known Limitations](../explanations/known-limitations.md)** - Platform constraints

### 2. Check Workflow Logs

GitHub Actions logs contain detailed error information:
1. Go to Actions tab
2. Click the failed workflow
3. Expand failed steps
4. Look for detailed error messages

### 3. Enable Debug Logging

For Terraform:
```bash
export TF_LOG=DEBUG
terraform plan
```

For Azure CLI:
```bash
az <command> --debug
```

### 4. Search Existing Issues

Check if others have encountered this:
- [GitHub Issues](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues)
- [GitHub Discussions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)

### 5. Ask for Help

If you're still stuck:

1. **Open a discussion**:
   - [Start a discussion](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
   - Include error messages
   - Describe what you've tried

2. **Report a bug**:
   - [Create an issue](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues)
   - Include steps to reproduce
   - Include logs (remove sensitive info!)

---

## Diagnostic Checklist

Use this checklist to gather information before asking for help:

```markdown
### Environment Information
- [ ] Operating System: ____
- [ ] Terraform version: ____
- [ ] Azure CLI version: ____
- [ ] Using dev container: Yes/No

### Authentication
- [ ] Azure login works: `az account show`
- [ ] Correct subscription selected
- [ ] Service principal exists
- [ ] GitHub secrets configured

### Configuration
- [ ] config.env file created
- [ ] GITHUB_OWNER and GITHUB_REPO set
- [ ] Storage account exists
- [ ] Network access configured

### Error Details
- [ ] Full error message: ____
- [ ] When it occurs: ____
- [ ] Steps to reproduce: ____
- [ ] Workflow logs attached: Yes/No
```

---

## Prevention Tips

**Avoid common issues**:

✅ **Always**:
- Run `terraform plan` before `apply`
- Review plan output carefully
- Use version control for all changes
- Test in non-production first
- Keep documentation updated

❌ **Never**:
- Apply without planning
- Skip error messages
- Ignore warnings
- Hard-code sensitive values
- Delete state files manually

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0  
**Contribute**: Help improve this guide by [sharing your solutions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
