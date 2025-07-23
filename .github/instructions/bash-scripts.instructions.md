---
description: "Bash scripting standards"
applyTo: "scripts/**"
---

# Bash Script Guidelines

## Script Structure and Safety
- Always start with `#!/bin/bash` shebang
- Use `set -e` to exit on errors and `set -u` for undefined variables
- Include script header comments explaining purpose and usage
- Implement proper signal handling and cleanup on exit

## Function and Variable Standards
- Use descriptive function names with snake_case convention
- Declare variables with appropriate scope (local vs global)
- Quote variables to prevent word splitting: `"$variable"`
- Use arrays for lists and `readonly` for constants

## Error Handling and User Experience
- Implement comprehensive error checking with meaningful messages
- Use color-coded output functions (print_success, print_error, print_warning)
- Provide progress indicators and status updates for long operations
- Include validation of prerequisites and dependencies

## Configuration Management
- Source utility functions from common libraries
- Load configuration from standardized config files (config.env)
- Validate required configuration values before proceeding
- Support both interactive and automated execution modes

## Azure and Platform Integration

**Cloud CLI Standards (Required):**
- **MUST** use Azure CLI (`az`) for all Azure resource interactions
- **MUST** use Power Platform CLI (`pac`) for all Power Platform operations
- **MUST** use GitHub CLI (`gh`) for all GitHub API interactions
- **EXCEPTION ONLY**: If CLI doesn't support required functionality, document justification

**CLI Usage Requirements:**
- Verify CLI installation and authentication before operations
- Use proper authentication checks (`az account show`, `pac auth list`, `gh auth status`)
- Implement retry logic for network operations
- Handle Azure resource naming conflicts gracefully
- Use JSON output format for programmatic processing (`--output json`)

**Alternative Approach Justification:**
When CLI tools cannot fulfill requirements, include detailed comment justification:

```bash
# JUSTIFICATION: Using REST API instead of Azure CLI because:
# - Azure CLI does not support custom policy assignments for this resource type
# - Required for compliance with organizational governance requirements
# - CLI enhancement request submitted: https://github.com/Azure/azure-cli/issues/XXXXX
curl -X POST "https://management.azure.com/..." \
     -H "Authorization: Bearer $access_token" \
     -H "Content-Type: application/json"
```

**Authentication Best Practices:**
- Use managed identities or service principals (avoid personal accounts in automation)
- Implement proper token refresh mechanisms
- Handle authentication failures gracefully with clear error messages
- Document required permissions and scopes
