## 🔄 Migration from Separate Modules

If you're currently using separate `res-environment` and `res-managed-environment` modules, this consolidated approach offers several benefits:

### Migration Benefits

- **Eliminates Timing Issues**: No more "Request url must be an absolute url" errors
- **Atomic Operations**: Environment and managed features created together
- **Simplified Dependencies**: Single module instead of complex orchestration
- **Better Performance**: Fewer API calls and state operations

### Migration Steps

#### Step 1: Backup Current State

```bash
# Export current Terraform state
terraform state pull > backup-state.json

# Document current environment IDs
terraform output -json > current-outputs.json
```

#### Step 2: Update Module References

**Before (Separate Modules):**
```hcl
module "environment" {
  source = "./configurations/res-environment"
  # ... environment configuration
}

module "managed_environment" {
  source = "./configurations/res-managed-environment"
  environment_id = module.environment.environment_id
  # ... managed environment configuration
}
```

**After (Consolidated Module):**
```hcl
module "environment" {
  source = "./configurations/res-environment"
  
  # ... existing environment configuration (unchanged)
  
  # Add managed environment settings
  enable_managed_environment = true
  managed_environment_settings = {
    # Transfer settings from old managed_environment module variables
    sharing_settings = {
      is_group_sharing_disabled = var.old_sharing_settings.is_group_sharing_disabled
      limit_sharing_mode        = var.old_sharing_settings.limit_sharing_mode
      max_limit_user_sharing    = var.old_sharing_settings.max_limit_user_sharing
    }
    # ... other settings
  }
}
```

#### Step 3: Remove Old Managed Environment Resources

```bash
# Remove the old managed environment from state
terraform state rm 'module.managed_environment.powerplatform_managed_environment.this'

# Plan with new configuration to see the import
terraform plan
```

#### Step 4: Import Existing Managed Environment (If Needed)

```bash
# Import the existing managed environment into the new resource
terraform import 'module.environment.powerplatform_managed_environment.this[0]' <environment-id>
```

### Compatibility Notes

- **Environment Configuration**: All existing environment settings remain unchanged
- **Variable Names**: Environment and Dataverse variables are identical
- **Outputs**: New managed environment outputs added, existing outputs preserved
- **Lifecycle**: Managed environments are protected by the same "No Touch Prod" policy

### Testing Migration

1. **Test in Development**: Migrate a development environment first
2. **Validate Outputs**: Confirm all required outputs are still available
3. **Check Dependencies**: Ensure downstream modules receive expected values
4. **Monitor Drift**: Verify no configuration drift after migration

## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role
- **State Backend**: Azure Storage with OIDC authentication

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and is only accessible through your authenticated Terraform execution environment.

## ⚠️ AVM Compliance

### Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`). 

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting environment IDs and computed attributes as discrete outputs
- **Security-First**: Sensitive data properly marked and segregated in outputs 
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Resource Deployment**: Deploys primary Power Platform resources following WAF best practices

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal has Power Platform Service Admin role
- Confirm OIDC configuration in GitHub repository secrets
- Check tenant ID and client ID configuration

**Permission Errors** 
- Ensure service principal is not blocked by conditional access policies
- Verify admin permissions for environment creation and management
- Check for tenant-level restrictions on automation

**Environment Creation Failures**
- Verify the target region is supported for Power Platform environments
- Check Dataverse database requirements and capacity limits  
- Ensure unique environment names within the tenant
- Confirm sufficient Power Platform licensing for environment type

**Duplicate Environment Issues**
- Use duplicate detection feature to identify existing environments with same name
- Consider importing existing environments: `terraform import powerplatform_environment.this {environment-id}`
- Review environment naming conventions to avoid conflicts

**Managed Environment Issues**
- Verify the environment type supports managed features (Sandbox, Production, Trial)
- Check that Dataverse is configured (required for managed environments)
- Ensure proper sharing configuration: group sharing enabled requires max_limit_user_sharing = -1
- Validate solution checker mode is one of: None, Warn, Block

### Migration Troubleshooting

**State Import Issues**
- Use `terraform state list` to verify resource paths
- Check environment ID format: must be valid GUID
- Ensure managed environment exists before import

**Configuration Conflicts**
- Review validation error messages for specific guidance
- Verify sharing settings combinations are valid
- Check that environment group ID is provided when needed

## Additional Links

- [Power Platform Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment)
- [Power Platform Managed Environment Resource Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [Managed Environment Overview](https://learn.microsoft.com/power-platform/admin/managed-environment-overview)