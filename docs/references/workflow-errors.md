# Workflow Error Reference

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

Complete reference for diagnosing and resolving errors in Power Platform Terraform workflows.

## Error Categories

| Error Type                                     | Common Causes                    | Exit Codes | Quick Actions                        |
| ---------------------------------------------- | -------------------------------- | ---------- | ------------------------------------ |
| [Init Errors](#terraform-init-errors)          | Network, Authentication, Backend | 1          | Check JIT access, verify credentials |
| [Plan Errors](#terraform-plan-errors)          | Permissions, Syntax, State       | 1, 2       | Validate config, check permissions   |
| [Apply Errors](#terraform-apply-errors)        | Resources, Limits, Conflicts     | 1          | Review capacity, check naming        |
| [Validate Errors](#terraform-validate-errors)  | Syntax, References, Provider     | 1          | Fix HCL syntax, verify references    |
| [Idempotency Errors](#idempotency-test-errors) | Drift, Computed Values           | 0, 1, 2    | Add ignore_changes, review diff      |
| [Input Validation](#input-validation-errors)   | Missing Files, Wrong Names       | 1          | Check paths, verify naming           |

---

## Terraform Init Errors

### Error Patterns

#### Network Connectivity Failures
```
Error: Failed to get existing workspaces: storage: service returned error
Error: Error loading state: BlobNotFound
Error: timeout while waiting for plugin to start
```

**Diagnostic Information**:
- **Exit Code**: 1
- **Phase**: Backend initialization
- **Component**: Azure Storage backend
- **Retry Behavior**: Automatic (3 attempts with exponential backoff)

**Root Causes**:
- Azure Storage account network access rules blocking GitHub Actions IP
- JIT network access expired or misconfigured
- DNS resolution failures for *.blob.core.windows.net
- Storage account firewall blocking public access

**Resolution Steps**:
1. **Verify JIT Access**: Check workflow logs for JIT network access setup success
2. **Test Connectivity**: Validate storage account accessibility from runner IP
3. **Check Firewall**: Review Azure Storage network access rules
4. **Validate DNS**: Ensure blob storage endpoints resolve correctly

**Configuration Requirements**:
- Storage account must allow GitHub Actions runner IP ranges
- JIT network access action must complete successfully
- Backend configuration secrets must be valid

#### Authentication Failures
```
Error: building AzureRM Client: authenticate to Azure via the CLI, or via Environment Variables
Error: Error building ARM Config: obtain subscription() from Azure CLI
```

**Diagnostic Information**:
- **Exit Code**: 1  
- **Phase**: Provider authentication
- **Component**: Azure OIDC authentication
- **Authentication Method**: Federated credentials

**Root Causes**:
- Service principal federated credentials misconfigured
- GitHub OIDC token validation failures  
- Incorrect tenant ID or subscription ID in secrets
- Service principal disabled or deleted

**Resolution Steps**:
1. **Verify OIDC Setup**: Check federated credential configuration in Azure AD
2. **Validate Secrets**: Confirm GitHub secrets match Azure AD application
3. **Test Permissions**: Ensure service principal has Storage Blob Data Contributor role
4. **Check Token**: Review GitHub OIDC token claims and audience

---

## Terraform Plan Errors

### Error Patterns

#### Permission Denied Errors
```
Error: insufficient privileges to complete the operation
Error: The client does not have authorization to perform action
Error: Forbidden. You do not have permission to view this resource
```

**Diagnostic Information**:
- **Exit Code**: 1
- **Phase**: Resource planning
- **Component**: Power Platform API
- **Required Permissions**: System Administrator, Environment Admin

**Root Causes**:
- Service principal missing Power Platform System Administrator role
- Insufficient Azure AD application permissions
- Power Platform tenant admin consent not granted
- Service principal not added to Power Platform security group

**Resolution Steps**:
1. **Grant PP Role**: Add System Administrator role in Power Platform admin center
2. **Azure AD Permissions**: Grant Microsoft.PowerApps API permissions
3. **Admin Consent**: Provide tenant admin consent for API permissions  
4. **Security Groups**: Add service principal to required Power Platform security groups

#### Configuration Syntax Errors  
```
Error: Unsupported argument
Error: Invalid reference
Error: Invalid function call
```

**Diagnostic Information**:
- **Exit Code**: 1
- **Phase**: Configuration parsing
- **Component**: HCL parser
- **Validation**: Automatic syntax checking

**Root Causes**:
- Invalid HCL syntax (missing quotes, brackets, semicolons)
- Undefined variables or incorrect variable references
- Deprecated resource arguments or functions
- Provider version compatibility issues

**Resolution Steps**:
1. **Local Validation**: Run `terraform validate` locally
2. **Syntax Check**: Review configuration files for HCL syntax errors
3. **Variable Check**: Verify all variable definitions and references
4. **Provider Version**: Ensure provider version compatibility

---

## Terraform Apply Errors

### Error Patterns

#### Resource Creation Failures
```
Error: A resource with the identifier already exists
Error: The environment name is already taken
Error: Request failed with status code 400
```

**Diagnostic Information**:
- **Exit Code**: 1
- **Phase**: Resource provisioning
- **Component**: Power Platform API
- **Operation**: CREATE, UPDATE, DELETE

**Root Causes**:
- Resource naming conflicts with existing resources
- Power Platform service limits or quotas exceeded
- Invalid resource configuration parameters
- Dependencies not properly configured

**Resolution Steps**:
1. **Check Naming**: Verify resource names are unique and follow conventions
2. **Review Limits**: Check Power Platform capacity and licensing limits
3. **Validate Config**: Ensure resource parameters meet Power Platform requirements
4. **Check Dependencies**: Verify prerequisite resources exist and are accessible

#### State Lock Conflicts
```
Error: Error locking state: Error acquiring the state lock
Error: Lock Info: Operation: OperationTypeApply
```

**Diagnostic Information**:
- **Exit Code**: 1
- **Phase**: State management
- **Component**: Azure Storage backend
- **Lock Duration**: Configurable (default: 20 minutes)

**Resolution Steps**:
1. **Wait for Release**: Check if another operation is in progress
2. **Force Unlock**: Use `terraform force-unlock` if lock is stale
3. **Check Logs**: Review other workflow runs for concurrent operations
4. **Verify Access**: Ensure storage account access is still valid

---

## Terraform Validate Errors

### Error Patterns

#### Syntax Validation Failures
```
Error: Invalid block definition
Error: Argument or block definition required
Error: Invalid character
```

**Diagnostic Information**:
- **Exit Code**: 1
- **Phase**: Configuration validation
- **Component**: HCL parser
- **Scope**: Syntax and structure only

**Resolution Requirements**:
- All `.tf` files must have valid HCL syntax
- Resource blocks must follow Terraform schema
- Variable definitions must match usage
- Provider configuration must be complete

---

## Idempotency Test Errors

### Error Patterns

#### Configuration Drift Detection
```
Note: Objects have changed outside of Terraform
Plan: 0 to add, 1 to change, 0 to destroy
```

**Diagnostic Information**:
- **Exit Code**: 2 (changes detected)
- **Phase**: Post-apply verification  
- **Component**: State comparison
- **AVM Requirement**: Zero drift tolerance

**Root Causes**:
- Resources with computed attributes not marked with `ignore_changes`
- Provider API returning different values after creation
- Timestamp or generated ID attributes causing drift
- External modifications to Power Platform resources

**Resolution Patterns**:
```hcl
# Ignore computed attributes
lifecycle {
  ignore_changes = [
    created_on,
    modified_on,
    version,
    system_tags
  ]
}

# Use data sources for read-only resources
data "powerplatform_environment" "existing" {
  display_name = var.environment_name
}
```

#### Test Execution Failures
```
Error: timeout while waiting for plugin to start
Error: Error refreshing state: BlobNotFound
```

**Diagnostic Information**:
- **Exit Code**: 1 (test failure)
- **Phase**: Post-apply plan execution
- **Component**: State refresh
- **Context**: After successful apply

**Resolution Steps**:
1. **Check Authentication**: Verify tokens haven't expired during apply
2. **Validate State**: Ensure state file integrity after apply operations
3. **Network Check**: Confirm backend connectivity is still active
4. **Provider Status**: Check for provider API rate limiting or outages

---

## Input Validation Errors

### Configuration Directory Errors

**Error Messages**:
```
Configuration directory 'invalid-config' does not exist
Available configurations: 01-dlp-policies, 02-dlp-policy, 03-environment
```

**Required Structure**:
```
configurations/
├── 01-dlp-policies/
│   ├── main.tf
│   ├── variables.tf
│   └── tfvars/
├── 02-dlp-policy/
│   └── tfvars/
└── 03-environment/
    └── tfvars/
```

### TfVars File Errors

**Error Messages**:
```
TfVars file 'missing.tfvars' not found in configurations/01-dlp-policies/tfvars/
Available tfvars files: example.tfvars, production.tfvars
```

**Naming Convention**:
- File location: `configurations/{config}/tfvars/{name}.tfvars`
- File format: Standard Terraform variable definitions
- Required variables: Must match configuration requirements

---

## Error Code Reference

| Exit Code | Meaning            | Action Required                                             |
| --------- | ------------------ | ----------------------------------------------------------- |
| 0         | Success            | No action needed                                            |
| 1         | General error      | Review error details and troubleshoot                       |
| 2         | Plan shows changes | Review diff output (normal for plan, error for idempotency) |

## Related Documentation

**Terraform Documentation**:
- [Terraform CLI Commands](https://developer.hashicorp.com/terraform/cli/commands)
- [Terraform Configuration Language](https://developer.hashicorp.com/terraform/language)
- [Azure Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

**Power Platform Documentation**:
- [Service Principal Setup](https://docs.microsoft.com/power-platform/admin/powershell-create-service-principal)
- [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)

**Azure Documentation**:
- [Azure Storage Network Security](https://docs.microsoft.com/azure/storage/common/storage-network-security)
- [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)

**Community Resources**:
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core/)
- [Power Platform Community](https://powerusers.microsoft.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
