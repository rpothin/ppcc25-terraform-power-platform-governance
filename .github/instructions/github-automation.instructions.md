---
description: "GitHub Actions workflows and automation standards"
applyTo: ".github/*.yml,.github/*.yaml"
---

# GitHub Automation Guidelines

## Workflow Structure and Organization

**Required Workflow Header Structure:**
All GitHub workflows **MUST** follow this exact order at the top of the file:
1. `name` - Clear, descriptive workflow name
2. `concurrency` - Prevent concurrent runs when appropriate
3. `on` - Trigger events and conditions
4. `run-name` - Dynamic run naming for better identification
5. `permissions` - Explicit permission declarations (principle of least privilege)

**Example Structure:**
```yaml
name: "Terraform Infrastructure Deployment"

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'development'

run-name: "Deploy to ${{ inputs.environment }} by @${{ github.actor }}"

permissions:
  contents: read
  id-token: write
  pull-requests: write

jobs:
  # Jobs definition starts here
```

**Additional Organization Standards:**
- Use reusable workflows for common patterns to reduce duplication
- **REQUIRED**: Reusable workflow names **MUST** start with "♻️" to ensure they appear at the end of the list in the GitHub UI
- Implement proper job dependencies and conditional execution
- Follow semantic naming conventions for workflows and jobs
- Group related actions into composite actions for reusability

## Security and Authentication

**OIDC and Environment Protection:**
- Use OIDC authentication for Azure and cloud provider connections
- **REQUIRED**: All Terraform jobs requiring GitHub secrets **MUST** specify the `production` GitHub environment
- Implement environment protection rules for production deployments
- Store sensitive values in GitHub secrets, not in workflow files
- Apply principle of least privilege for workflow permissions

**GitHub Environment Requirements:**
```yaml
jobs:
  terraform-deploy:
    runs-on: ubuntu-latest
    environment: production  # REQUIRED for Terraform jobs with secrets
    steps:
      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**Permission Standards:**
- Always declare explicit permissions (avoid `permissions: write-all`)
- Use minimal required permissions for each workflow
- Document why specific permissions are needed

## Error Handling and Reliability
- Implement comprehensive error handling with meaningful messages
- Use retry mechanisms for network operations and external dependencies
- Provide clear failure messages and troubleshooting guidance
- Include proper cleanup steps for failed workflow runs

## Performance and Efficiency
- Use caching for dependencies and build artifacts
- Implement conditional execution to skip unnecessary steps
- Optimize workflow triggers to reduce unnecessary runs
- Use matrix strategies for parallel execution where appropriate

## Integration with Repository Standards
- Follow the established workflow naming conventions
- Include proper status reporting and badge integration
- Implement automated testing and validation steps
