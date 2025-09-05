# Sequential Environment and Managed Environment Test Utility

This configuration tests sequential deployment of Power Platform environments followed by managed environment enablement to validate provider behavior and isolate URL errors following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Key Features

- **Sequential Deployment Testing**: Validates environment → managed environment deployment patterns
- **Error Isolation**: Isolates complex orchestration variables to identify root causes
- **Comprehensive Logging**: Provides detailed debugging information for troubleshooting
- **Proven Module Integration**: Uses tested res-environment and res-managed-environment modules
- **Configurable Timing**: Adjustable wait durations for different environments

## Use Cases

This configuration is designed for organizations that need to:

1. **Debug Sequential Deployment Issues**: Isolate and identify root causes of "Request url must be an absolute url" errors in environment → managed environment workflows
2. **Validate Provider Behavior**: Test Power Platform provider v3.8+ behavior with sequential resource creation in isolated environment
3. **Timing Analysis**: Determine optimal wait durations and dependency patterns for reliable environment provisioning
4. **Pattern Validation**: Verify that proven res-environment and res-managed-environment modules work correctly in sequence

## Testing and Validation Focus

This utility module is specifically designed for:

- **CI/CD Pipeline Validation**: Test sequential deployment patterns in automated workflows
- **Development Environment Testing**: Validate configurations before complex orchestration
- **Provider Behavior Analysis**: Study Power Platform provider limitations and timing requirements
- **Troubleshooting Support**: Provide isolated test cases for debugging production issues

## Usage with Testing and Validation Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-test-environment-managed-sequence'
  test_name: 'validation-run-001'
  environment_wait_duration: '120s'
```