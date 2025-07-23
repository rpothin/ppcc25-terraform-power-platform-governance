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

## Documentation and Comments

**Purpose-Driven Comments for Power Platform Governance:**
This standard ensures GitHub Actions workflows provide clear context about governance decisions, security requirements, and operational needs without unnecessary verbosity.

### Header Documentation Pattern

All workflows **MUST** include a comprehensive header following this pattern:

```yaml
# ═══════════════════════════════════════════════════════════════════════════════════════════════════════
# TERRAFORM [OPERATION] WORKFLOW FOR POWER PLATFORM GOVERNANCE
# ═══════════════════════════════════════════════════════════════════════════════════════════════════════
# Brief statement of workflow purpose and primary governance value.
#
# 🎯 WHY THIS EXISTS:
# - Governance requirement it addresses (DLP, environment management, compliance)
# - Business problem it solves (manual processes, security gaps, audit needs)
# - Operational benefit it provides (automation, consistency, error reduction)
#
# 🔒 SECURITY DECISIONS:
# - Why OIDC authentication is required for this operation
# - Why specific environment protections are needed
# - Why certain permissions are granted or restricted
#
# ⚙️ OPERATIONAL CONTEXT:
# - Why concurrency controls are configured this way
# - Why timeout values are set to specific durations  
# - Why certain trigger patterns are used
#
# 📋 INTEGRATION REQUIREMENTS:
# - Dependencies on other workflows or systems
# - Why specific tool versions are pinned
# - Why certain backends or storage patterns are used
# ═══════════════════════════════════════════════════════════════════════════════════════════════════════
```

### Section Documentation Pattern

Document configuration sections that implement governance or security requirements:

```yaml
# === POWER PLATFORM AUTHENTICATION ===
# OIDC required because stored credentials violate zero-trust security model
# Power Platform provider needs explicit tenant context for multi-tenant scenarios
env:
  POWER_PLATFORM_USE_OIDC: true
  POWER_PLATFORM_CLIENT_ID: ${{ secrets.POWER_PLATFORM_CLIENT_ID }}
  POWER_PLATFORM_TENANT_ID: ${{ secrets.POWER_PLATFORM_TENANT_ID }}

# === CONCURRENCY PROTECTION ===
# Prevents state corruption when multiple deployments target same configuration
# Never cancel running Terraform operations to avoid incomplete state changes
concurrency:
  group: terraform-${{ inputs.configuration }}-${{ inputs.tfvars-file }}-${{ github.ref }}
  cancel-in-progress: false
```

### Input/Output Documentation Pattern

All workflow inputs and outputs **MUST** include comprehensive documentation:

```yaml
inputs:
  configuration:
    description: 'Target configuration directory for deployment'
    required: true
    # WHY: Scopes permissions and isolates blast radius for governance
    # VALIDATION: Must exist in configurations/ and contain .tf files
    # SECURITY: Used in state key generation to prevent cross-configuration access
    # EXAMPLES: '02-dlp-policy', '03-environment'
    
  auto-approve:
    description: 'Bypass manual approval for apply operations'
    required: false
    default: false
    # WHY: Production safety requires explicit confirmation for destructive operations
    # GOVERNANCE: Supports automated deployments while maintaining audit trails
    # SECURITY: Default false prevents accidental infrastructure changes
```

### Step Documentation Pattern

Document non-obvious steps, security decisions, and governance context:

```yaml
  steps:
    # === AZURE OIDC AUTHENTICATION ===
    # Required for backend state access and resource management
    # Uses GitHub OIDC identity federation to eliminate stored credentials
    - name: Azure Login via OIDC
      uses: azure/login@v2.3.0
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    # === JIT NETWORK ACCESS ===
    # Storage accounts use firewall restrictions for defense-in-depth security
    # Temporary access prevents permanent security holes while enabling automation
    - name: Enable Temporary Storage Access
      uses: ./.github/actions/jit-network-access
      with:
        action: 'add'
        # WHY: Backend storage requires network-level protection for compliance
        storage-account-name: ${{ secrets.TERRAFORM_STORAGE_ACCOUNT }}
```

### Conditional Logic Documentation

Explain complex conditions and business logic:

```yaml
# Only execute if resources exist - prevents unnecessary operations on empty state
# Force override available for emergency cleanup scenarios
if: |
  needs.validate.outputs.resources-exist == 'true' || 
  inputs.force-destroy == 'true'

# Pull request events need different branch handling for documentation commits
# HEAD ref ensures commits go to PR branch, not base branch
ref: ${{ github.event.pull_request.head.ref || github.ref }}
```

### Error Context Documentation

Provide troubleshooting context and available options:

```yaml
  run: |
    if [ ! -d "configurations/$config" ]; then
      echo "::error title=Configuration Not Found::Directory 'configurations/$config' does not exist"
      # WHY: Early validation prevents confusing failures in later steps
      # CONTEXT: Available configurations are determined by repository structure
      echo "::notice title=Available Options::$(ls configurations/ | grep -E '^[0-9]+-')"
      exit 1
    fi
```

### What NOT to Document

❌ **Avoid explaining obvious operations:**
```yaml
# BAD: Obvious what the step does
- name: Checkout Repository
  uses: actions/checkout@v4
  # Checks out the repository code for processing
```

❌ **Avoid repeating step names in comments:**
```yaml
# BAD: Redundant with step name  
# Setup Terraform CLI
- name: Setup Terraform CLI
```

❌ **Avoid implementation details that change frequently:**
```yaml
# BAD: Too specific to implementation
# Uses version 1.12.2 with wrapper disabled for clean output parsing
```

### Key Principles

1. **Focus on WHY** - Explain decisions, not obvious operations
2. **Governance Context** - Include Power Platform specific requirements
3. **Security Rationale** - Explain authentication and permission choices
4. **Operational Impact** - Document behavior that affects reliability
5. **Maintenance Guidance** - Include context for future updates
6. **Concise but Complete** - Provide necessary context without noise

### Enforcement Requirements

- Comments should pass the "6-month test" - understandable by someone (including yourself) 6 months later
- Every non-obvious configuration choice should have a WHY comment
- Security and governance decisions must be documented
- Integration points and dependencies require context
- Error scenarios should include troubleshooting guidance

## Integration with Repository Standards
- Follow the established workflow naming conventions
- Include proper status reporting and badge integration
- Implement automated testing and validation steps

## YAML Syntax Validation

**Automated YAML Validation Framework:**
This project includes comprehensive YAML validation that runs automatically on all GitHub Actions files. The validation framework ensures syntax correctness, consistent formatting, and GitHub Actions compliance.

### Validation Infrastructure

**Automated Validation Workflow:**
- **CI/CD Integration**: `yaml-validation.yml` workflow validates all YAML changes automatically
- **Trigger Events**: Runs on pull requests and pushes affecting YAML files
- **Comprehensive Coverage**: Validates workflows, composite actions, and configuration files

**Built-in Validation Tools:**
The development environment includes pre-configured validation tools:
- **yamllint**: Project-specific configuration in `.yamllint`
- **actionlint**: GitHub Actions workflow validation
- **Python YAML**: Structural syntax validation

### Project Validation Commands

**Use the project's validation script for all YAML validation needs:**

```bash
# Validate all GitHub Actions YAML files
./scripts/utils/validate-yaml.sh --all-github

# Validate all composite actions
./scripts/utils/validate-yaml.sh --all-actions

# Validate specific file
./scripts/utils/validate-yaml.sh path/to/file.yml
```

**Manual validation (if needed):**
```bash
# Basic syntax check
python3 -c "import yaml; yaml.safe_load(open('file.yml'))"

# Style validation with project configuration
yamllint file.yml

# GitHub Actions workflow validation
actionlint file.yml
```

### YAML Standards

**Project Configuration:**
All YAML validation uses the project's `.yamllint` configuration, which enforces:
- **Line length**: 100 characters (with exceptions for non-breakable content)
- **Indentation**: 2 spaces consistently
- **Document start**: Required `---` at file beginning
- **Comments**: Minimum 2 spaces from content
- **GitHub Actions compatibility**: Flexible truthy values and proper structure

**Quality Requirements:**
- **Syntax correctness**: Must parse without errors
- **Style consistency**: Follows project yamllint rules
- **GitHub Actions compliance**: Valid workflow and action structure
- **Documentation completeness**: Required fields and descriptions

### Validation Enforcement

**Automatic Validation:**
- **Pull Request Validation**: All YAML changes validated before merge
- **Development Environment**: Tools available in devcontainer
- **CI/CD Integration**: Prevents merging invalid YAML files

**Manual Validation:**
Use the project validation script after making YAML changes:
```bash
# Quick validation of changed files
./scripts/utils/validate-yaml.sh --all-github
```

**Common Issues and Solutions:**
- **Line length**: Use YAML folding (`>-`) for long descriptions
- **Indentation**: Use consistent 2-space indentation
- **Missing fields**: Ensure composite actions have required `name`, `description`, `runs`
- **Syntax errors**: Check quotes, brackets, and YAML structure

### Integration Benefits

**Development Workflow:**
- **Early feedback**: Validation runs automatically on changes
- **Consistent standards**: Project-wide YAML formatting rules
- **Quality assurance**: Prevents runtime failures from syntax errors
- **Documentation enforcement**: Ensures proper action and workflow documentation

**Maintenance Advantages:**
- **Automated checks**: No manual validation steps required
- **Standardized configuration**: Single source of truth in `.yamllint`
- **Comprehensive coverage**: All YAML files validated consistently
- **Clear error reporting**: Detailed feedback for quick issue resolution
