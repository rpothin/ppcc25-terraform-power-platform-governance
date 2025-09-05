<!-- BEGIN_TF_DOCS -->
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

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_null"></a> [null](#requirement\_null) (~> 3.2)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [powerplatform_environment.test](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id)

Description: Azure AD security group GUID for Dataverse environment security.  

This security group controls access to the test Dataverse environment.  
The group should contain users who need access to the test environment.  

Example:
```hcl
security_group_id = "12345678-1234-1234-1234-123456789012"
```

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_location"></a> [location](#input\_location)

Description: Power Platform location for test environment creation.  

Specifies the geographic location where the test environment will be provisioned.  
This should match your organization's data residency requirements.  

Example:
```hcl
location = "unitedstates"
```

Type: `string`

Default: `"unitedstates"`

### <a name="input_test_name"></a> [test\_name](#input\_test\_name)

Description: Display name for the test environment and managed environment configuration.  

This variable defines the naming for the test resources created to validate  
sequential deployment of environments followed by managed environment enablement.  

Example:
```hcl
test_name = "test-seq-validation"
```

Type: `string`

Default: `"test-environment-managed-sequence"`

## Outputs

The following outputs are exported:

### <a name="output_created_resources_summary"></a> [created\_resources\_summary](#output\_created\_resources\_summary)

Description: Summary of resources created during the test for cleanup reference

### <a name="output_dataverse_organization_id"></a> [dataverse\_organization\_id](#output\_dataverse\_organization\_id)

Description: The organization ID of the Dataverse instance in the test environment

### <a name="output_debug_information"></a> [debug\_information](#output\_debug\_information)

Description: Simplified debugging information for troubleshooting sequential deployment

### <a name="output_deployment_timestamp"></a> [deployment\_timestamp](#output\_deployment\_timestamp)

Description: The timestamp when the sequential deployment test was initiated

### <a name="output_environment_unique_name"></a> [environment\_unique\_name](#output\_environment\_unique\_name)

Description: The unique name (schema name) of the test environment

### <a name="output_environment_url"></a> [environment\_url](#output\_environment\_url)

Description: The web URL of the test Power Platform environment

### <a name="output_test_configuration"></a> [test\_configuration](#output\_test\_configuration)

Description: Summary of the test configuration parameters

### <a name="output_test_environment_id"></a> [test\_environment\_id](#output\_test\_environment\_id)

Description: The unique identifier of the test Power Platform environment

### <a name="output_test_environment_name"></a> [test\_environment\_name](#output\_test\_environment\_name)

Description: The display name of the test Power Platform environment

### <a name="output_test_managed_environment_id"></a> [test\_managed\_environment\_id](#output\_test\_managed\_environment\_id)

Description: The unique identifier of the test managed environment configuration

### <a name="output_validation_checkpoints"></a> [validation\_checkpoints](#output\_validation\_checkpoints)

Description: Status indicators for key validation checkpoints in sequential deployment

## Modules

The following Modules are called:

### <a name="module_test_managed_environment"></a> [test\_managed\_environment](#module\_test\_managed\_environment)

Source: ../res-managed-environment

Version:

## Authentication

This configuration requires authentication to Microsoft Power Platform:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role
- **State Backend**: Azure Storage with OIDC authentication

### Service Principal Permission Requirements

The service principal used for testing requires:
- **Power Platform Service Admin**: For environment and managed environment management
- **Azure AD Group Member**: Must be member of or owner of the security group specified in `security_group_id`
- **Environment Creator**: Permission to create sandbox environments in the target location

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and is only accessible through your authenticated Terraform execution environment.

## ⚠️ AVM Compliance

### Provider Exception

This configuration uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by providing discrete test result outputs and resource identifiers
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Testing and Validation**: Provides testing utilities for validating deployment patterns and provider behavior

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal has Power Platform Service Admin role
- Confirm OIDC configuration in GitHub repository secrets
- Check tenant ID and client ID configuration

**Permission Errors**
- Ensure service principal is not blocked by conditional access policies
- Verify admin permissions for test environment and managed environment management
- Check for tenant-level restrictions on automation

**Sequential Deployment Errors**
- If "Request url must be an absolute url" error occurs, increase environment\_wait\_duration
- Check environment\_id output for empty or malformed values
- Verify res-environment and res-managed-environment modules are up to date

**Test Execution Issues**
- Ensure test\_name is unique to avoid conflicts with existing resources
- Use different security\_group\_id if permission issues occur
- Enable comprehensive\_logging for detailed debugging information

### Debugging Sequential Deployment Issues

1. **Check Environment Readiness**: Verify environment\_id is populated before managed environment creation
2. **Timing Adjustments**: Increase environment\_wait\_duration if timing-related errors occur
3. **Module Compatibility**: Ensure both res-environment and res-managed-environment modules are latest versions
4. **Dependency Validation**: Review validation\_checkpoints output to identify which phase failed

## Additional Links

- [Power Platform Managed Environment Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/managed_environment)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->