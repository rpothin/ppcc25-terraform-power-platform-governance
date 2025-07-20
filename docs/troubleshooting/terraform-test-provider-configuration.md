# Terraform Test Provider Configuration Issue

## Problem Description

Our Terraform test files (`.tftest.hcl`) were missing proper provider configuration blocks, which is required according to the official Terraform testing documentation.

## Root Cause

When following the [official Terraform Test tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test), test files need their own provider configuration blocks, especially when:

1. Tests need to authenticate with external providers
2. Tests use different provider configurations than the main module
3. Tests run independently of the main configuration

## Original Issues

### Missing Provider Blocks
Our test files were attempting to reference provider resources without declaring the provider:

```hcl
# ❌ Missing provider configuration
run "validate_configuration_structure" {
  command = plan
  
  assert {
    condition = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "DLP policies data source must be properly configured"
  }
}
```

### Invalid Command Values
The unit tests were using `command = validate` which is not valid in Terraform test syntax:

```hcl
# ❌ Invalid command
run "validate_terraform_syntax" {
  command = validate  # Only 'plan' and 'apply' are valid
}
```

## Solution Applied

### 1. Added Provider Configuration Blocks

Both test files now include proper provider configuration:

```hcl
# ✅ Proper provider configuration for tests
provider "powerplatform" {
  use_oidc = true
}
```

### 2. Fixed Command Values

All test run blocks now use valid command values:

```hcl
# ✅ Valid command
run "validate_terraform_syntax" {
  command = plan  # Changed from 'validate' to 'plan'
}
```

## Key Learnings

### Test File Structure Requirements

1. **Provider Declaration**: Test files must declare their own provider blocks
2. **Command Values**: Only `plan` and `apply` are valid command values
3. **No Terraform Blocks**: Test files don't use `terraform {}` blocks - they inherit requirements from the main configuration
4. **Authentication**: Test provider blocks need the same authentication configuration as the main configuration

### AVM Compliance

This fix ensures our test structure follows both:
- Official Terraform testing best practices
- Azure Verified Modules (AVM) testing standards

## Files Modified

- `/configurations/01-dlp-policies/tests/integration.tftest.hcl`
- `/configurations/01-dlp-policies/tests/unit.tftest.hcl`

## Validation

After the fix:
- `terraform validate` passes successfully
- `terraform test` properly recognizes provider configuration (fails on authentication as expected in non-configured environment)
- Test structure follows official Terraform testing patterns

## References

- [Terraform Test Tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
- [Power Platform Provider Authentication](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/guides/azure_cli)
- [AVM Testing Guidelines](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/)
