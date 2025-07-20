# Power Platform Terraform Testing Guide

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

This guide shows you how to run and develop tests for Power Platform Terraform configurations using the comprehensive testing framework.

## Prerequisites

- Terraform CLI (>= 1.5.0)
- Power Platform service principal with appropriate permissions
- Azure CLI (for authentication)
- Access to the configured Terraform backend

## Testing Architecture Overview

The testing framework uses a multi-layered approach:

- **Unit Tests**: Basic syntax and structure validation without authentication
- **Integration Tests**: Full functionality tests with Power Platform connectivity
- **CI/CD Tests**: Automated testing in GitHub Actions with comprehensive reporting

## Test Structure

Each configuration follows this standardized test structure:

```
configurations/<config-name>/
├── tests/
│   ├── unit.tftest.hcl           # Terraform native unit tests
│   ├── integration.tftest.hcl    # Terraform native integration tests
│   ├── integration-test.sh       # Custom integration test script
│   └── run-tests.sh              # Test runner for local development
└── <configuration files>
```

## Running Tests Locally

### Quick Test Execution

Navigate to any configuration directory and use the test runner:

```bash
# Navigate to configuration directory
cd configurations/01-dlp-policies

# Run all tests
./tests/run-tests.sh all

# Run specific test types
./tests/run-tests.sh unit           # Unit tests only
./tests/run-tests.sh integration    # Integration tests only
```

### Unit Tests Only

Unit tests validate configuration syntax and structure without requiring authentication:

```bash
cd configurations/01-dlp-policies

# Initialize without backend for unit testing
terraform init -backend=false

# Run unit tests
terraform test tests/unit.tftest.hcl
```

### Integration Tests with Authentication

Integration tests require Power Platform authentication and test real connectivity:

```bash
cd configurations/01-dlp-policies

# Set authentication environment
export RUN_AUTHENTICATED_TESTS=true
export ARM_CLIENT_ID="your-service-principal-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# Run integration test script
chmod +x tests/integration-test.sh
./tests/integration-test.sh
```

## Test File Requirements

### Critical Provider Configuration

**Important**: All `.tftest.hcl` files must include explicit provider configuration blocks. This is a requirement discovered through troubleshooting and is critical for proper test execution.

```hcl
# ✅ Required provider block in test files
provider "powerplatform" {
  use_oidc = true
}

# Test runs follow this pattern
run "test_name" {
  command = plan  # Only 'plan' and 'apply' are valid commands
  
  assert {
    condition     = can(data.powerplatform_data_loss_prevention_policies.current)
    error_message = "Test validation message"
  }
}
```

### Unit Test Structure

Unit tests (`unit.tftest.hcl`) focus on:
- Configuration syntax validation
- Provider configuration structure
- File structure validation
- Basic Terraform constraints

### Integration Test Structure

Integration tests (`integration.tftest.hcl`) validate:
- Data source connectivity with Power Platform
- Output structure compliance (AVM requirements)
- Backend configuration functionality
- Resource access patterns

## Authentication Setup

### Local Development Authentication

For local testing with authentication:

1. **Azure CLI Login**:
   ```bash
   az login
   ```

2. **Set Environment Variables**:
   ```bash
   export ARM_USE_OIDC=true
   export POWER_PLATFORM_USE_OIDC=true
   export RUN_AUTHENTICATED_TESTS=true
   ```

3. **Configure Service Principal** (if not using Azure CLI):
   ```bash
   export ARM_CLIENT_ID="service-principal-id"
   export ARM_TENANT_ID="tenant-id"
   export ARM_SUBSCRIPTION_ID="subscription-id"
   export POWER_PLATFORM_CLIENT_ID="power-platform-app-id"
   export POWER_PLATFORM_TENANT_ID="tenant-id"
   ```

### CI/CD Authentication

The GitHub Actions workflow automatically configures OIDC authentication using repository secrets:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `POWER_PLATFORM_CLIENT_ID`
- `POWER_PLATFORM_TENANT_ID`

## Test Categories and Coverage

### Unit Tests
- **Purpose**: Validate basic configuration structure and syntax
- **Authentication**: Not required
- **Execution Time**: < 1 minute
- **Coverage**: Syntax, file structure, provider configuration

### Integration Tests
- **Purpose**: Validate Power Platform connectivity and functionality
- **Authentication**: Required (OIDC or service principal)
- **Execution Time**: 2-5 minutes (depends on tenant size)
- **Coverage**: Data source access, API connectivity, output validation

### CI/CD Pipeline Tests
- **Purpose**: Comprehensive testing with security scanning and validation
- **Authentication**: OIDC with GitHub secrets
- **Execution Time**: 5-15 minutes
- **Coverage**: All test types plus security scanning and AVM compliance

## Troubleshooting Common Issues

### Provider Configuration Errors

**Issue**: Tests fail with "provider not configured" errors

**Solution**: Ensure test files include provider blocks:
```hcl
provider "powerplatform" {
  use_oidc = true
}
```

### Authentication Failures

**Issue**: Integration tests fail with authentication errors

**Solutions**:
1. Verify service principal permissions in Power Platform admin center
2. Check environment variables are set correctly
3. Ensure OIDC trust relationship is configured

### Timeout Issues

**Issue**: Tests timeout during execution

**Possible Causes**:
- Large Power Platform tenant with many resources
- Power Platform API performance issues
- Network connectivity problems

**Solutions**:
- Increase timeout values in test scripts
- Run tests during off-peak hours
- Check Power Platform service health

### Backend Configuration Issues

**Issue**: Tests fail to initialize Terraform backend

**Solutions**:
1. Verify storage account access permissions
2. Check JIT network access configuration
3. Confirm backend configuration in test environment

## Test Development Best Practices

### Creating New Tests

1. **Start with Unit Tests**: Create basic syntax validation first
2. **Add Provider Configuration**: Always include provider blocks in test files
3. **Use Valid Commands**: Only `plan` and `apply` are supported in test runs
4. **Test Incrementally**: Build up from simple to complex assertions

### Test File Organization

```hcl
# File header with description
# Provider configuration (required)
provider "powerplatform" {
  use_oidc = true
}

# Test runs in logical order
run "basic_validation" {
  command = plan
  # Simple assertions first
}

run "advanced_validation" {
  command = plan
  # Complex assertions last
}
```

### Assertion Guidelines

```hcl
# ✅ Good: Specific, testable conditions
assert {
  condition     = can(data.powerplatform_data_loss_prevention_policies.current)
  error_message = "DLP policies data source must be accessible"
}

# ✅ Good: Output structure validation
assert {
  condition     = can(output.dlp_policies.policy_count)
  error_message = "Output must include policy_count for AVM compliance"
}

# ❌ Avoid: Vague or untestable conditions
assert {
  condition     = true
  error_message = "This test should pass"
}
```

## Integration with CI/CD

### Workflow Integration

Tests are automatically executed in GitHub Actions when:
- Pull requests modify configurations or modules
- Changes are pushed to the main branch
- Manual workflow dispatch is triggered

### Test Reports

The CI/CD pipeline generates:
- Test execution summaries in GitHub Actions logs
- Security scan results uploaded to GitHub Security tab
- Artifact uploads with detailed test outputs
- Job summaries with test coverage information

### Customizing Test Execution

Use workflow dispatch parameters to customize test runs:
- `target_path`: Test specific configuration only
- `force_all`: Test all configurations regardless of changes
- `skip_integration`: Skip integration tests for faster runs

## Adding Tests to New Configurations

### Minimal Test Setup

For any new configuration, create these required files:

1. **Unit Tests** (`tests/unit.tftest.hcl`):
   ```hcl
   provider "powerplatform" {
     use_oidc = true
   }
   
   run "validate_syntax" {
     command = plan
     assert {
       condition = can(terraform.required_providers.powerplatform)
       error_message = "Provider configuration must be valid"
     }
   }
   ```

2. **Integration Tests** (`tests/integration.tftest.hcl`):
   ```hcl
   provider "powerplatform" {
     use_oidc = true
   }
   
   run "validate_connectivity" {
     command = plan
     assert {
       condition = can(data.powerplatform_data_loss_prevention_policies.current)
       error_message = "Power Platform connectivity test failed"
     }
   }
   ```

3. **Test Runner** (`tests/run-tests.sh`):
   ```bash
   #!/bin/bash
   # Copy from existing configuration and adapt as needed
   ```

## Related Documentation

- [Troubleshooting: Terraform Test Provider Configuration](../troubleshooting/terraform-test-provider-configuration.md)
- [Setup Guide: Validation and Testing](setup-guide.md#-validation-and-testing)
- [AVM Compliance: Testing Requirements](avm-compliance-remediation-plan.md)

## External References

- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
- [Power Platform Provider Authentication](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/guides/azure_cli)
- [Azure Verified Modules Testing Guidelines](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/)
