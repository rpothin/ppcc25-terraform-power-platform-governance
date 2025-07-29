<!-- BEGIN_TF_DOCS -->
# Smart DLP tfvars Generator

This configuration automates the generation of tfvars files for DLP policy management by accessing live Power Platform data directly, enabling seamless onboarding of existing policies to Infrastructure as Code. Follows Azure Verified Module (AVM) best practices with Power Platform provider adaptations for enterprise-grade governance automation.

## Use Cases

This configuration is designed for organizations that need to:

1. **Onboard existing DLP policies to Terraform**: Retrieves live DLP policy configurations and converts them into ready-to-use tfvars for infrastructure as code adoption.
2. **Migrate from ClickOps to IaC**: Eliminates manual policy recreation by automatically generating tfvars from existing tenant policies.
3. **Validate policy configuration completeness**: Ensures all required fields and connector classifications are accurately captured from live data sources.
4. **Integrate with automated workflows**: Enables GitHub Actions and CLI workflows to generate and validate tfvars as part of CI/CD pipelines.
5. **Support governance transitions**: Facilitates the transition from manual Power Platform administration to Infrastructure as Code governance patterns.

## Architecture Overview

### Direct Data Source Approach
- **Live Tenant Access**: Connects directly to Power Platform APIs via OIDC authentication
- **Real-time Accuracy**: No dependency on exported files or stale data snapshots
- **Secure Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID integration
- **Anti-Corruption Layer**: Provides discrete outputs following AVM patterns

### Key Benefits
- **Zero Export Dependencies**: No need for manual data exports or file management
- **Always Current**: Policy data retrieved at execution time ensures accuracy
- **Simplified Workflow**: Single-step process from live policy to tfvars file
- **Audit Trail**: Complete generation metadata and diagnostic information

## Usage Examples

### GitHub Actions Integration
```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-generate-dlp-tfvars'
  terraform_variables: '-var="source_policy_name=Corporate Data Protection Policy" -var="output_file=policies/corporate-dlp.tfvars"'
```

### CLI Usage
```bash
# Generate tfvars for specific policy
terraform apply \
  -var="source_policy_name=Development Environment DLP" \
  -var="output_file=generated/dev-dlp.tfvars"

# Use generated tfvars with res-dlp-policy module
terraform apply -var-file="generated/dev-dlp.tfvars"
```

### Policy Selection
```hcl
# Example variable configuration
source_policy_name = "Copilot Studio Autonomous Agents"
output_file       = "tfvars/copilot-studio-dlp.tfvars"
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_local"></a> [local](#requirement\_local) (~> 2.4)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_local"></a> [local](#provider\_local) (~> 2.4)

- <a name="provider_powerplatform"></a> [powerplatform](#provider\_powerplatform) (~> 3.8)

## Resources

The following resources are used by this module:

- [local_file.generated_tfvars](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [powerplatform_data_loss_prevention_policies.current](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/data-sources/data_loss_prevention_policies) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_source_policy_name"></a> [source\_policy\_name](#input\_source\_policy\_name)

Description: Name of the DLP policy to onboard and generate tfvars for.

This variable specifies which existing policy to retrieve from the live Power Platform tenant  
and convert into a tfvars configuration for Infrastructure as Code management.

Usage Context:
- Used to select an existing policy from live Power Platform data (onboarding mode)
- Must match a policy display\_name present in the Power Platform tenant
- Enables seamless transition from ClickOps to Infrastructure as Code

Data Source: Live Power Platform tenant via powerplatform\_data\_loss\_prevention\_policies data source  
Authentication: OIDC authentication to Power Platform APIs

Example Values:
- "Corporate Data Protection Policy"
- "Development Environment DLP"
- "Copilot Studio Autonomous Agents"

Validation Rules:
- Must be non-empty string (minimum 1 character)
- Maximum 100 characters for Power Platform compatibility
- Alphanumeric characters, spaces, hyphens, and underscores only
- Case-sensitive matching against actual policy names

Troubleshooting:
- If policy not found, check exact spelling and case sensitivity
- Verify authentication and access to Power Platform tenant
- Use diagnostic\_info output for policy matching details

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_output_file"></a> [output\_file](#input\_output\_file)

Description: Path and filename for the generated tfvars output file.

This variable controls where the generated tfvars configuration will be written  
on the local filesystem for subsequent use with the res-dlp-policy module.

File Format: Standard Terraform .tfvars format with HCL syntax  
File Content: Complete DLP policy configuration ready for immediate use  
File Encoding: UTF-8 with proper Terraform formatting and indentation  
File Permissions: 0644 (readable by owner and group, writable by owner only)

Path Configuration:
- Relative paths: Interpreted relative to Terraform working directory
- Absolute paths: Used as-is for full path control
- Directory creation: Parent directories must exist (not auto-created)

Integration with res-dlp-policy:
- Generated file can be used directly with: terraform apply -var-file="path/to/generated.tfvars"
- All variable names match res-dlp-policy module input requirements
- No manual editing required for basic policy deployment

Example Values:
- "generated-dlp-policy.tfvars" (default, current directory)
- "tfvars/production-dlp.tfvars" (subdirectory organization)
- "/workspace/configs/imported-policy.tfvars" (absolute path)
- "environments/dev/dlp-baseline.tfvars" (environment-specific)

Security Considerations:
- Generated files may contain policy configuration details
- Ensure appropriate file system permissions and access controls
- Consider excluding generated tfvars from version control if sensitive

Type: `string`

Default: `"generated-dlp-policy.tfvars"`

## Outputs

The following outputs are exported:

### <a name="output_connector_analysis"></a> [connector\_analysis](#output\_connector\_analysis)

Description: Detailed analysis of connector classifications and configurations from the source policy.

Provides granular insights into:
- Connector distribution across classifications
- Action and endpoint rule configurations
- Custom connector pattern analysis
- Policy governance compliance indicators

Use for detailed policy analysis and compliance reporting.

### <a name="output_diagnostic_info"></a> [diagnostic\_info](#output\_diagnostic\_info)

Description: Diagnostic information for troubleshooting tfvars generation issues.

Provides detailed diagnostic data including:
- Data source query results and status
- Policy matching logic and results
- Validation errors and warnings
- Performance metrics and execution context

Use this output when generation fails or produces unexpected results.  
All diagnostics based on live Power Platform API responses.

### <a name="output_generated_tfvars_content"></a> [generated\_tfvars\_content](#output\_generated\_tfvars\_content)

Description: The generated tfvars content for the selected DLP policy.

This output provides a ready-to-use tfvars configuration that can be:
- Saved to a .tfvars file for use with res-dlp-policy module
- Used directly in Terraform configurations for policy replication
- Modified as needed for environment-specific adjustments

The content includes:
- Complete DLP policy configuration structure
- All connector classifications (business, non\_business, blocked)
- Custom connector patterns if present
- Properly formatted Terraform syntax ready for immediate use

Generated from live Power Platform data to ensure accuracy and freshness.  
No dependency on exported files - direct tenant access via OIDC authentication.

### <a name="output_generation_summary"></a> [generation\_summary](#output\_generation\_summary)

Description: Summary of the tfvars generation process and validation results.

Provides operational context and validation information including:
- Source policy identification and matching status
- Output file configuration and write status
- Policy data validation and completeness checks
- Connector classification summaries for quick review
- Generation timestamp for audit and tracking purposes

Use this output to verify successful generation and troubleshoot any issues.  
Data sourced directly from live Power Platform tenant via authenticated API access.

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this module.

### <a name="output_policy_analysis"></a> [policy\_analysis](#output\_policy\_analysis)

Description: Analysis of the source DLP policy for governance insights and migration planning.

Provides detailed analysis of the policy structure including:
- Policy complexity indicators (action rules, endpoint rules, custom patterns)
- Environment targeting and scope information
- Connector distribution and classification patterns
- Migration considerations and recommendations

Use this output for policy assessment and migration planning activities.  
Analysis based on live Power Platform policy data for maximum accuracy.

### <a name="output_tfvars_file_path"></a> [tfvars\_file\_path](#output\_tfvars\_file\_path)

Description: The absolute path to the generated tfvars file on the local filesystem.

This output provides the location where the physical tfvars file has been written,  
enabling downstream processes to reference or process the file as needed.

File Location: Relative to Terraform working directory  
File Format: Standard .tfvars format compatible with res-dlp-policy module  
File Encoding: UTF-8 with proper Terraform syntax formatting  
File Permissions: 0644 (readable by owner and group, writable by owner only)

Usage:
- Reference this path for automated deployment workflows
- Use with terraform apply -var-file="$(terraform output -raw tfvars\_file\_path)"
- Integrate with CI/CD pipelines for policy deployment automation

## Modules

No modules.

## Authentication & Security

This configuration requires secure authentication to Microsoft Power Platform:

### Authentication Method
- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **No Client Secrets**: Keyless authentication for enhanced security
- **Required Permissions**: Power Platform Service Admin role or DLP Policy Read permissions
- **State Backend**: Azure Storage with OIDC authentication

### Security Best Practices
- **Principle of Least Privilege**: Service principal permissions limited to DLP policy read access
- **Secure State Management**: Terraform state encrypted at rest in Azure Storage
- **No Sensitive Data Storage**: Generated tfvars contain policy configuration only (no secrets)
- **Audit Logging**: All operations logged through Azure AD and Power Platform audit logs

## Data Handling & Privacy

This configuration prioritizes data security and privacy:

### Data Sources
- **Live API Access**: Connects directly to Power Platform Management APIs
- **No Data Export**: No intermediate file storage or data export requirements
- **Tenant Isolation**: All data remains within your Power Platform tenant boundaries
- **Real-time Queries**: Policy data retrieved at execution time only

### Data Collection Policy
- **No Telemetry**: This configuration does not collect or transmit telemetry data
- **Local Processing**: All data processing occurs in your execution environment
- **Temporary Access**: Policy data accessed only during terraform execution
- **No Third-party Storage**: No data stored outside your tenant and execution environment

## ⚠️ AVM Compliance & Standards

### Provider Exception Documentation

This configuration uses the `microsoft/power-platform` provider, which creates a documented exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### AVM Compliance Implementation

- **TFFR2 Anti-Corruption Layer**: Implements discrete outputs instead of exposing full resource objects
- **TFFR4 Security Standards**: Sensitive data properly marked and segregated in outputs
- **TFFR6 Validation**: Comprehensive input validation with clear error messages
- **TFFR9 Documentation**: Complete variable and output documentation with examples
- **AVM-Inspired Patterns**: Follows AVM standards where technically feasible with Power Platform

### Module Classification
- **Utility Module (`utl-*`)**: Provides data processing and file generation without deploying resources
- **Anti-Corruption Focus**: Transforms live API data into standardized tfvars format
- **Reusable Pattern**: Can be extended for other Power Platform resource onboarding scenarios

## Troubleshooting & Support

### Common Issues & Resolutions

**Authentication Failures**
```bash
# Verify service principal configuration
az ad sp show --id <service-principal-id>
# Check Power Platform permissions
az role assignment list --assignee <service-principal-id>
```
<!-- END_TF_DOCS -->