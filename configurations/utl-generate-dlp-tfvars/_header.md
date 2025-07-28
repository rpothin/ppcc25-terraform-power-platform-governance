# Smart DLP tfvars Generator

This configuration automates the generation of tfvars files for DLP policy management by processing exported policy and connector data, supporting both new policy creation and onboarding of existing policies to IaC, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Onboard existing DLP policies to Terraform**: Converts exported DLP policy data into ready-to-use tfvars for infrastructure as code adoption.
2. **Generate new policy templates**: Creates tfvars files from governance templates (strict, balanced, development) for new DLP policies.
3. **Validate policy configuration completeness**: Ensures all required fields and connector classifications are present in generated tfvars.
4. **Integrate with automated workflows**: Enables GitHub Actions and CLI workflows to generate and validate tfvars as part of CI/CD.

## Usage with Data Export Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'utl-generate-dlp-tfvars'
  terraform_variables: '-var="source_policy_name=Copilot Studio Autonomous Agents"'
```