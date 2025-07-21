# Workflow Error Reference Guide

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

> **Comprehensive troubleshooting guide for GitHub workflow errors**  
> *Quick reference for resolving common failures in Terraform Power Platform workflows*

## 🎯 Quick Navigation

- [Common Terraform Init Errors](#common-terraform-init-errors)
- [Common Terraform Plan Errors](#common-terraform-plan-errors)
- [Common Terraform Apply Errors](#common-terraform-apply-errors)
- [Common Terraform Destroy Errors](#common-terraform-destroy-errors)
- [Common Terraform Import Errors](#common-terraform-import-errors)
- [Common Terraform Test Errors](#common-terraform-test-errors)
- [Emergency Procedures](#emergency-procedures)

## 📋 Common Terraform Init Errors

### Error: Backend Configuration Failed

**Symptoms**:
```
Error: Failed to configure backend "azurerm"
```

**Root Causes**:
- Network connectivity issues to Azure Storage Account
- Invalid backend configuration parameters
- OIDC authentication token issues
- JIT network access not active or misconfigured

**Solutions**:
1. **Verify JIT Network Access**:
   - Check that JIT network access workflow step completed successfully
   - Confirm storage account firewall rules allow GitHub Actions IP ranges
   - Wait additional time for network rule propagation (up to 60 seconds)

2. **Check Storage Account Configuration**:
   - Verify storage account exists and is accessible
   - Confirm container name matches backend configuration
   - Ensure resource group name is correct

3. **Validate OIDC Authentication**:
   - Check OIDC trust relationship between GitHub and Azure
   - Verify service principal has Storage Blob Data Contributor role
   - Confirm subscription, tenant, and client IDs are correct

**Diagnostic Commands**:
```bash
# Check storage account accessibility
az storage account show --name <storage-account> --resource-group <rg>

# Verify network rules
az storage account network-rule list --account-name <storage-account> --resource-group <rg>

# Test container access
az storage container list --account-name <storage-account> --auth-mode login
```

### Error: State Lock Conflicts

**Symptoms**:
```
Error: Error locking state: ConditionalCheckFailedException
```

**Root Causes**:
- Previous workflow execution didn't complete cleanup properly
- Multiple concurrent workflow executions on same state
- Workflow was manually cancelled while holding state lock

**Solutions**:
1. **Wait for Lock Expiration**:
   - State locks automatically expire after 15 minutes of inactivity
   - Check if any workflows are currently running on the same configuration

2. **Manual Lock Removal** (Use with caution):
   ```bash
   terraform force-unlock <lock-id>
   ```

3. **Check Workflow Concurrency**:
   - Verify workflow concurrency controls are properly configured
   - Cancel any stuck workflow runs in GitHub Actions UI

## 📋 Common Terraform Plan Errors

### Error: Configuration Syntax Invalid

**Symptoms**:
```
Error: Unsupported argument
Error: Missing resource
Error: Invalid resource name
```

**Root Causes**:
- HCL syntax errors in configuration files
- Invalid resource references or variable usage
- Provider version compatibility issues
- Missing or incorrect variable definitions

**Solutions**:
1. **Local Validation**:
   ```bash
   terraform validate
   terraform fmt -check
   ```

2. **Check Resource References**:
   - Verify all resource and variable names are correct
   - Confirm data source references exist
   - Review provider documentation for correct syntax

3. **Provider Version Issues**:
   - Check provider version constraints in `versions.tf`
   - Verify Power Platform provider is up to date
   - Review breaking changes in provider releases

### Error: Authentication Failed

**Symptoms**:
```
Error: unable to list Power Platform environments
Error: Authentication failed
```

**Root Causes**:
- Service principal lacks required Power Platform permissions
- OIDC token expiration or invalid configuration
- Power Platform API throttling or service issues

**Solutions**:
1. **Verify Service Principal Permissions**:
   - Ensure service principal has Power Platform Administrator role
   - Check specific resource permissions (Environment Admin, etc.)
   - Verify service principal is enabled and not expired

2. **OIDC Configuration**:
   - Check federated credential configuration in Azure AD
   - Verify subject claim matches repository and branch
   - Confirm client ID, tenant ID are correct

3. **Power Platform Service Health**:
   - Check [Power Platform Service Health](https://admin.powerplatform.microsoft.com/service-health)
   - Monitor for API throttling in workflow logs
   - Retry workflow execution after service issues resolve

## 📋 Common Terraform Apply Errors

### Error: Resource Already Exists

**Symptoms**:
```
Error: A resource with the ID already exists
Error: Resource already managed by Terraform
```

**Root Causes**:
- Resource was created outside of Terraform
- State file inconsistencies or corruption
- Import operation was not completed properly

**Solutions**:
1. **Import Existing Resource**:
   ```bash
   terraform import <resource_type>.<resource_name> <resource_id>
   ```

2. **Remove Resource from State**:
   ```bash
   terraform state rm <resource_type>.<resource_name>
   ```

3. **Manual Resource Cleanup**:
   - Delete resource manually from Power Platform admin center
   - Re-run terraform apply to recreate with proper state tracking

### Error: Quota Exceeded

**Symptoms**:
```
Error: Operation failed due to quota limitations
Error: License quota exceeded
```

**Root Causes**:
- Power Platform environment limits reached
- Per-app plan quotas exhausted
- Tenant-level resource limitations

**Solutions**:
1. **Check Power Platform Admin Center**:
   - Review capacity and quota usage
   - Identify which quotas are exhausted
   - Remove unused environments or resources

2. **License Management**:
   - Verify sufficient Power Platform licenses
   - Assign appropriate licenses to service principal
   - Review trial environment limitations

3. **Request Quota Increases**:
   - Submit quota increase requests through Power Platform admin center
   - Work with Microsoft support for enterprise quotas

## 📋 Common Terraform Destroy Errors

### Error: Resource Protection Policies

**Symptoms**:
```
Error: Cannot delete resource due to protection policy
Error: Resource deletion blocked
```

**Root Causes**:
- Resource lock policies preventing deletion
- Dependent resources blocking destruction
- Protection settings enabled in Power Platform

**Solutions**:
1. **Remove Resource Locks**:
   - Check Power Platform admin center for protection settings
   - Remove resource locks before destroy operation
   - Review dependency order for destruction

2. **Handle Dependencies**:
   - Identify dependent resources preventing deletion
   - Remove dependencies or adjust destroy order
   - Use `terraform destroy -target` for selective deletion

### Error: Cascading Deletion Failures

**Symptoms**:
```
Error: Cannot delete resource due to existing dependencies
```

**Root Causes**:
- Child resources preventing parent resource deletion
- Cross-environment dependencies
- Active connections or flows using resources

**Solutions**:
1. **Dependency Analysis**:
   - Review Power Platform admin center for active connections
   - Identify all dependent resources
   - Plan deletion order carefully

2. **Selective Destruction**:
   ```bash
   terraform destroy -target=<specific_resource>
   ```

3. **Manual Cleanup**:
   - Delete dependent resources manually first
   - Then proceed with terraform destroy

## 📋 Common Terraform Import Errors

### Error: Resource Not Found

**Symptoms**:
```
Error: Resource not found for import
Error: Invalid resource ID
```

**Root Causes**:
- Resource ID format is incorrect
- Resource doesn't exist in Power Platform
- Service principal lacks read permissions

**Solutions**:
1. **Verify Resource Exists**:
   - Check Power Platform admin center for resource
   - Confirm resource ID format matches provider documentation
   - Test resource access with service principal

2. **Resource ID Format**:
   - Review Power Platform provider documentation for correct ID format
   - Use PowerShell cmdlets to get correct resource IDs:
   ```powershell
   Get-AdminPowerAppEnvironment | Select-Object EnvironmentName, DisplayName
   ```

3. **Permissions Verification**:
   - Ensure service principal has read access to resource
   - Check if resource is in different tenant or environment

### Error: Resource Type Mismatch

**Symptoms**:
```
Error: Resource type does not match
Error: Cannot import resource of this type
```

**Root Causes**:
- Specified resource type doesn't match actual Power Platform resource
- Provider version doesn't support resource type
- Resource configuration is missing or incorrect

**Solutions**:
1. **Verify Resource Type**:
   - Check Power Platform admin center to confirm resource type
   - Review provider documentation for supported resource types
   - Ensure configuration block matches resource type

2. **Configuration Validation**:
   ```bash
   terraform validate
   terraform plan  # Review plan before import
   ```

## 📋 Common Terraform Test Errors

### Error: Test Configuration Invalid

**Symptoms**:
```
Error: Invalid test configuration
Error: Test file syntax error
```

**Root Causes**:
- Invalid HCL syntax in `.tftest.hcl` files
- Missing test configuration blocks
- Incorrect test variable definitions

**Solutions**:
1. **Validate Test Files**:
   ```bash
   terraform fmt -check tests/
   terraform validate
   ```

2. **Test Configuration Review**:
   - Check test file structure against Terraform test documentation
   - Verify variable definitions and assertions
   - Review test provider configurations

### Error: Integration Test Failures

**Symptoms**:
```
Error: Test assertion failed
Error: Expected vs actual value mismatch
```

**Root Causes**:
- Test environment data doesn't match expectations
- Dynamic test data causing assertion failures
- Test isolation issues between runs

**Solutions**:
1. **Review Test Data**:
   - Check if test environment has expected baseline data
   - Review test assertions for accuracy
   - Consider using dynamic test expectations

2. **Test Environment Isolation**:
   - Ensure tests don't interfere with each other
   - Use unique test data for each run
   - Clean up test resources after execution

## 🚨 Emergency Procedures

### State File Corruption

**Immediate Actions**:
1. Stop all running workflows affecting the same state
2. Download state backup from workflow artifacts
3. Restore state file to Azure Storage container
4. Verify state integrity before resuming operations

**Commands**:
```bash
# Verify state integrity
terraform state list
terraform state show <resource>

# Force state unlock if needed
terraform force-unlock <lock-id>
```

### Authentication Issues

**Immediate Actions**:
1. Verify service principal exists and is not disabled
2. Check OIDC trust relationship configuration
3. Recreate federated credential if necessary
4. Test authentication manually with Azure CLI

**Diagnostic Steps**:
```bash
# Test Azure authentication
az login --service-principal --username <client-id> --tenant <tenant-id>

# Check Power Platform access
az account set --subscription <subscription-id>
```

### Resource Conflicts

**Immediate Actions**:
1. Identify conflicting resources in Power Platform admin center
2. Document current resource state
3. Choose resolution strategy (import, remove, or recreate)
4. Update Terraform configuration accordingly

### Network Connectivity Issues

**Immediate Actions**:
1. Check Azure Storage Account network rules
2. Verify JIT network access configuration
3. Review GitHub Actions IP ranges allowlist
4. Test connectivity from different network

**Diagnostic Commands**:
```bash
# Test storage account connectivity
nslookup <storage-account>.blob.core.windows.net
curl -I https://<storage-account>.blob.core.windows.net
```

## 📞 Support and Escalation

### When to Create an Issue

Create a GitHub issue when:
- Error persists after trying documented solutions
- Error appears to be a bug in workflow or configuration
- New error pattern not documented in this guide

### Issue Template Information

Include the following in your issue:
1. **Complete error logs** from failed workflow run
2. **Configuration details** (sanitized, no secrets)
3. **Steps already attempted** from this troubleshooting guide
4. **Expected vs actual behavior** description
5. **Environment details** (which configuration, tfvars used)

### Internal Escalation

For urgent production issues:
1. **Alert team lead** if workflows affect critical resources
2. **Document incident timeline** and resolution steps
3. **Update this guide** with new troubleshooting information
4. **Review incident** in next team retrospective

## 📚 Additional Resources

### Official Documentation
- [Terraform Documentation](https://developer.hashicorp.com/terraform)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Power Platform Resources
- [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
- [Power Platform Service Health](https://admin.powerplatform.microsoft.com/service-health)
- [Power Platform CLI](https://docs.microsoft.com/en-us/power-platform/developer/cli/introduction)

### Terraform Troubleshooting
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)
- [Terraform Import Guide](https://developer.hashicorp.com/terraform/cli/import)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/backend)

---

**Last Updated**: {{ .Date }}  
**Version**: 2.0.0  
**Maintainers**: GitHub Workflows Team

*This guide is automatically updated as part of the workflow improvement initiative.*
