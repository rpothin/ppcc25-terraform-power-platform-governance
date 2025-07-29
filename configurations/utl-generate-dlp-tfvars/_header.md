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