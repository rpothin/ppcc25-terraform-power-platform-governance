---
description: "GitHub Actions workflows and automation standards"
applyTo: ".github/*.yml,.github/*.yaml"
---

# GitHub Automation Guidelines

## Workflow Structure and Organization

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

Permission Standards:

Always declare explicit permissions (avoid permissions: write-all)
Use minimal required permissions for each workflow
    echo "::notice title=Fix Instructions::Use one of the available configurations listed above"
    exit 1
  fi

Reliability Patterns:

Timeout Configuration: Appropriate timeouts for each operation type
Retry Logic: Automatic retry for transient failures
    timeout-minutes: 5
    steps:
      # ... job steps

  # Creates Terraform execution plan  
  # WHY: Shows what changes will be made before applying
  terraform-plan:
    needs: validate
    runs-on: ubuntu-latest
    environment: production  # Required for state access
    timeout-minutes: 15
    outputs:
      has-changes: ${{ steps.plan.outputs.changes }}
    steps:
      # ... job steps

  # Applies the Terraform plan to deploy resources
  # WHY: Only runs if plan succeeds and changes exist
  terraform-apply:
    needs: terraform-plan
    if: needs.terraform-plan.outputs.has-changes == 'true'
    runs-on: ubuntu-latest
    environment: production  # Required for deployment secrets
    timeout-minutes: 25
    steps:
      # ... job steps

Job Documentation Principles:

One-line purpose - Clear, simple description of what the job does
WHY comment - Brief explanation of why this job exists or runs conditionally

---
description: "GitHub Actions workflows and automation standards"
applyTo: ".github/*.yml,.github/*.yaml"
---

# GitHub Automation Guidelines

## Workflow Structure and Organization

### Required Workflow Header Structure
All GitHub workflows **MUST** follow this exact order at the top of the file:
1. `name` — Clear, descriptive workflow name
2. `concurrency` — Prevent concurrent runs when appropriate
3. `on` — Trigger events and conditions
4. `run-name` — Dynamic run naming for better identification
5. `permissions` — Explicit permission declarations (principle of least privilege)

#### Example Structure
```yaml
---  # REQUIRED: Document start marker
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

### Additional Organization Standards
- Use reusable workflows for common patterns to reduce duplication
- **REQUIRED**: Reusable workflow names **MUST** start with "♻️" to ensure they appear at the end of the list in the GitHub UI
- Implement proper job dependencies and conditional execution
- Follow semantic naming conventions for workflows and jobs
- Group related actions into composite actions for reusability

---

## File Size and Complexity Management

### Mandatory Size Limits
Following the baseline principle of **Modularity Over Long and Complex Files**:
- **Individual workflow files**: **MAXIMUM 300 lines**
- **Composite action files**: **MAXIMUM 150 lines**
- **Reusable workflow files**: **MAXIMUM 400 lines** (due to interface complexity)

#### Exception Process
Files exceeding limits require:
- **Documented justification** in header comment with architectural reasoning
- **Modularization plan** with specific timeline for splitting
- **Architecture review approval** before merge

#### Modularization Triggers
- **IMMEDIATE REVIEW**: Any file approaching 80% of size limit
- **MANDATORY ACTION**: Files exceeding limits must be split unless exception approved
- **REFACTORING GUIDANCE**: Use composite actions, job splitting, or workflow chaining

#### Complexity Reduction Patterns
```yaml
# GOOD: Split large workflows into focused components
# Main workflow coordinates, reusable workflows handle operations
uses: ./.github/workflows/reusable-terraform-base.yml
with:
  operation: plan
  configuration: ${{ inputs.configuration }}

# GOOD: Extract complex logic to composite actions
- name: Configure Terraform Backend
  uses: ./.github/actions/terraform-backend-setup
  with:
    storage-account: ${{ secrets.TERRAFORM_STORAGE_ACCOUNT }}
```

---

## Automated Compliance Enforcement

### Pre-commit Validation Requirements
All workflows and composite actions **MUST** pass automated validation before commit:

```bash
# REQUIRED: Run before committing any GitHub Actions changes
./scripts/utils/validate-github-actions-compliance.sh

# Validates:
# - YAML document start markers (---)
# - Required header structure order
# - File size limits and complexity
# - Environment protection requirements
# - Documentation completeness
```

### CI/CD Integration Standards
- **Compliance validation** runs automatically on all pull requests
- **Non-compliant changes** are blocked from merging
- **Validation results** provide specific remediation guidance
- **Quality gates** require compliance score above threshold

#### Enforcement Mechanisms
```yaml
# Automatic validation in PR workflow
- name: Validate GitHub Actions Compliance
  uses: ./.github/actions/validate-actions-compliance
  with:
    fail-on-violations: true
    generate-report: true
```

---

## Template-Based Development

### Required Scaffolding Process
Following the baseline principle of **Reusability Over Code Duplication**:
- **NEW WORKFLOWS**: Must use approved templates from `.github/templates/`
- **VALIDATION**: Template compliance automatically verified
- **CONSISTENCY**: Identical patterns across all workflow types

#### Template Categories
- `workflow-terraform-operation.template.yml` — Infrastructure operations
- `workflow-validation.template.yml` — Validation and testing workflows
- `workflow-reusable.template.yml` — Reusable workflow patterns
- `action-composite.template.yml` — Reusable composite actions

#### Template Usage
```bash
# Generate new workflow from template
./scripts/utils/create-workflow.sh --template terraform-operation --name my-workflow

# Validate template compliance
./scripts/utils/validate-template-compliance.sh path/to/workflow.yml
```

---

## Security and Authentication

### OIDC and Environment Protection
Following the baseline principle of **Security by Design**:
- Use OIDC authentication for Azure and cloud provider connections
- **REQUIRED**: All Terraform jobs requiring GitHub secrets **MUST** specify the `production` GitHub environment
- Implement environment protection rules for production deployments
- Store sensitive values in GitHub secrets, not in workflow files
- Apply principle of least privilege for workflow permissions

#### GitHub Environment Requirements
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

#### Permission Standards
- Always declare explicit permissions (avoid `permissions: write-all`)
- Use minimal required permissions for each workflow
- Document why specific permissions are needed in inline comments

#### Security Validation
```yaml
# Automated security scanning for workflows
- name: Scan for Security Issues
  uses: ./.github/actions/security-scan-workflows
  with:
    check-secrets: true
    validate-permissions: true
    enforce-oidc: true
```

---

## Error Handling and Reliability

### Comprehensive Error Handling
Following the baseline principle of **Keep It Simple**:
- Implement meaningful error messages with actionable guidance
- Use retry mechanisms for network operations and external dependencies
- Provide clear failure messages and troubleshooting guidance
- Include proper cleanup steps for failed workflow runs

#### Error Message Standards
```yaml
run: |
  if [ ! -d "configurations/$config" ]; then
    echo "::error title=Configuration Not Found::Directory 'configurations/$config' does not exist"
    # WHY: Early validation prevents confusing failures in later steps
    # CONTEXT: Available configurations are determined by repository structure
    echo "::notice title=Available Options::$(ls configurations/ | grep -E '^[0-9]+-')"
    echo "::notice title=Fix Instructions::Use one of the available configurations listed above"
    exit 1
  fi
```

#### Reliability Patterns
- **Timeout Configuration**: Appropriate timeouts for each operation type
- **Retry Logic**: Automatic retry for transient failures
- **State Protection**: Never cancel operations that modify infrastructure state
- **Cleanup Procedures**: Proper resource cleanup on failure

---

## Performance and Efficiency

### Optimization Requirements
- Use caching for dependencies and build artifacts
- Implement conditional execution to skip unnecessary steps
- Optimize workflow triggers to reduce unnecessary runs
- Use matrix strategies for parallel execution where appropriate

#### Caching Standards
```yaml
# Standardized caching for Terraform operations
- name: Cache Terraform Providers
  uses: actions/cache@v4
  with:
    path: ~/.terraform.d/plugin-cache
    key: terraform-providers-${{ runner.os }}-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: terraform-providers-${{ runner.os }}-
```

---

## Documentation and Comments

### Purpose-Driven Comments for Power Platform Governance
Following the baseline principle of **Clear and Concise Comments**:

This standard ensures GitHub Actions workflows provide clear context about governance decisions, security requirements, and operational needs without unnecessary verbosity.

#### Header Documentation Pattern
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

#### Section Documentation Pattern
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

#### Input/Output Documentation Pattern
All workflow inputs and outputs **MUST** include comprehensive documentation:
```yaml
inputs:
  configuration:
    description: 'Target configuration directory for deployment'
    required: true
    # WHY: Scopes permissions and isolates blast radius for governance
    # VALIDATION: Must exist in configurations/ and contain .tf files
    # SECURITY: Used in state key generation to prevent cross-configuration access
    # EXAMPLES: 'res-dlp-policy', 'ptn-environment'
  auto-approve:
    description: 'Bypass manual approval for apply operations'
    required: false
    default: false
    # WHY: Production safety requires explicit confirmation for destructive operations
    # GOVERNANCE: Supports automated deployments while maintaining audit trails
    # SECURITY: Default false prevents accidental infrastructure changes
```

#### Step Documentation Pattern
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

#### Conditional Logic Documentation
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

#### Error Context Documentation
Provide troubleshooting context and available options:
```yaml
run: |
  if [ ! -d "configurations/$config" ]; then
    echo "::error title=Configuration Not Found::Directory 'configurations/$config' does not exist"
    # WHY: Early validation prevents confusing failures in later steps
    # CONTEXT: Available configurations are determined by repository structure
    echo "::notice title=Available Options::$(ls configurations/ | grep -E '^[0-9]+-')"
    echo "::notice title=Fix Instructions::Check configuration name spelling and ensure directory exists"
    exit 1
  fi
```

#### Jobs Documentation Pattern
Document jobs simply and clearly, focusing on **what** and **why** without overwhelming detail:
```yaml
jobs:
  # Validates Terraform configuration before planning
  # WHY: Prevents wasted time on invalid configurations
  validate:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      # ... job steps
  # Creates Terraform execution plan  
  # WHY: Shows what changes will be made before applying
  terraform-plan:
    needs: validate
    runs-on: ubuntu-latest
    environment: production  # Required for state access
    timeout-minutes: 15
    outputs:
      has-changes: ${{ steps.plan.outputs.changes }}
    steps:
      # ... job steps
  # Applies the Terraform plan to deploy resources
  # WHY: Only runs if plan succeeds and changes exist
  terraform-apply:
    needs: terraform-plan
    if: needs.terraform-plan.outputs.has-changes == 'true'
    runs-on: ubuntu-latest
    environment: production  # Required for deployment secrets
    timeout-minutes: 25
    steps:
      # ... job steps
```

##### Job Documentation Principles
1. **One-line purpose** — Clear, simple description of what the job does
2. **WHY comment** — Brief explanation of why this job exists or runs conditionally
3. **Environment context** — Short inline comment for non-obvious environment/timeout choices
4. **Dependency clarity** — Use descriptive job names and simple conditional logic
5. **Avoid over-documentation** — Don't explain obvious things like `runs-on: ubuntu-latest`

#### Good examples
```yaml
# Deploy DLP policies to Power Platform
# WHY: Automates governance that was previously manual
terraform-apply:
# Only run if configuration changes detected  
# WHY: Saves time and avoids unnecessary operations
if: needs.terraform-plan.outputs.has-changes == 'true'
```

#### What NOT to Document
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

---

## Key Principles

1. **Focus on WHY** — Explain decisions, not obvious operations
2. **Governance Context** — Include Power Platform specific requirements
3. **Security Rationale** — Explain authentication and permission choices
4. **Operational Impact** — Document behavior that affects reliability
5. **Maintenance Guidance** — Include context for future updates
6. **Concise but Complete** — Provide necessary context without noise

### Enforcement Requirements
- Comments should pass the "6-month test" — understandable by someone (including yourself) 6 months later
- Every non-obvious configuration choice should have a WHY comment
- Security and governance decisions must be documented
- Integration points and dependencies require context
- Error scenarios should include troubleshooting guidance

---

## Quality Metrics and Monitoring

### Continuous Compliance Monitoring
Following the baseline principle of **Consistency and Standards**:

#### Automated Metrics Collection
- **File Complexity**: Line count, nesting depth, job count tracking
- **Documentation Coverage**: Comment-to-code ratios, missing documentation detection
- **Standards Compliance**: Automated scoring of instruction adherence

#### Quality Gates
- **PR Requirements**: Compliance score above 85% required for merge
- **Trend Monitoring**: Alerts when repository-wide compliance degrades below 90%
- **Regular Reports**: Weekly compliance status and improvement recommendations

#### Compliance Scoring
```yaml
# Automated compliance scoring
- name: Calculate Compliance Score
  uses: ./.github/actions/compliance-scoring
  with:
    minimum-score: 85
    fail-below-threshold: true
    generate-report: true
```

---

## Integration with Repository Standards

### Development Environment Integration
- **IDE/Editor Integration**: Custom YAML schema validates GitHub Actions syntax
- **Linting Rules**: Project-specific yamllint configuration enforced
- **Real-time Validation**: Immediate feedback on compliance violations
- **Template Access**: Easy access to approved templates via scripts

### Workflow Creation Process
1. **Use Templates**: Start with approved template for consistency
2. **Validate Early**: Run compliance checks during development
3. **Document Thoroughly**: Include all required documentation sections
4. **Test Completely**: Validate functionality and compliance before PR
5. **Monitor Continuously**: Track compliance metrics post-deployment

---

## YAML Syntax Validation

### Automated YAML Validation Framework
This project includes comprehensive YAML validation that runs automatically on all GitHub Actions files. The validation framework ensures syntax correctness, consistent formatting, and GitHub Actions compliance.

#### Validation Infrastructure
- **CI/CD Integration**: `yaml-validation.yml` workflow validates all YAML changes automatically
- **Trigger Events**: Runs on pull requests and pushes affecting YAML files
- **Comprehensive Coverage**: Validates workflows, composite actions, and configuration files

#### Built-in Validation Tools
The development environment includes pre-configured validation tools:
- **yamllint**: Project-specific configuration in `.yamllint`
- **actionlint**: GitHub Actions workflow validation
- **Python YAML**: Structural syntax validation

#### Project Validation Commands
Use the project's validation script for all YAML validation needs:
```bash
# Validate all GitHub Actions YAML files
./scripts/utils/validate-yaml.sh --all-github
# Validate all composite actions
./scripts/utils/validate-yaml.sh --all-actions
# Validate specific file
./scripts/utils/validate-yaml.sh path/to/file.yml
# Comprehensive compliance validation
./scripts/utils/validate-github-actions-compliance.sh --fix-issues
```

#### Manual validation (if needed)
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

#### Quality Requirements
- **Syntax correctness**: Must parse without errors
- **Style consistency**: Follows project yamllint rules
- **GitHub Actions compliance**: Valid workflow and action structure
- **Documentation completeness**: Required fields and descriptions

### YAML Formatting Standards
**📋 Authoritative Reference:** The `.yamllint` file is the single source of truth for all YAML formatting rules. When in doubt, always consult `.yamllint` for the complete and current configuration.

#### Immediate Formatting Rules (from project `.yamllint` configuration)
Write all YAML following these standards to avoid validation failures:
```yaml
---  # REQUIRED: Document start marker on first line
# INDENTATION: Always use 2 spaces (never tabs)
name: "Terraform Infrastructure Deployment"
# COMMENTS: Minimum 2 spaces from content
concurrency:  # Prevent concurrent runs
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
# LINE LENGTH: Maximum 100 characters, use folding for long content
on:
  workflow_dispatch:
    inputs:
      description: >-
        This is a long description that exceeds 100 characters
        so we use YAML folding to maintain readability and compliance
# GITHUB ACTIONS VALUES: Use standard values, 'on' key is allowed
permissions:  # Not permissions: true/false
  contents: read
  id-token: write
# EMPTY LINES: Maximum 2 consecutive, none at start, max 1 at end
jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    steps:
      # Two spaces minimum between content and comments
      - name: Checkout Repository  # Required for workflow access
        uses: actions/checkout@v4
```

#### Key Rules Summary (extracted from `.yamllint`)
- **Document start**: Always begin with `---`
- **Indentation**: 2 spaces consistently, never tabs
- **Line length**: 100 characters maximum
- **Comments**: Minimum 2 spaces from content
- **Empty lines**: Max 2 consecutive, none at file start
- **Truthy values**: Use `true`/`false`, `on`/`off`, `yes`/`no`
- **GitHub Actions**: `on:` key allowed despite being truthy value

#### Long Content Handling
```yaml
# Use YAML folding (>-) for descriptions exceeding 100 characters
description: >-
  This workflow deploys Power Platform governance policies using Terraform.
  It includes DLP policy management, environment configuration, and compliance
  monitoring to ensure consistent governance across all Power Platform tenants.
# Break long arrays and objects for readability
env:
  POWER_PLATFORM_USE_OIDC: true
  POWER_PLATFORM_CLIENT_ID: ${{ secrets.POWER_PLATFORM_CLIENT_ID }}
  POWER_PLATFORM_TENANT_ID: ${{ secrets.POWER_PLATFORM_TENANT_ID }}
```

**⚠️ Important:** These examples show the most common rules, but `.yamllint` contains the complete configuration including edge cases, specific rule exceptions, and detailed validation settings. Always reference `.yamllint` for:
- **Complete rule definitions** and their specific parameters
- **Rule exceptions** and special case handling
- **Updates** to formatting standards over time
- **Troubleshooting** complex validation errors

#### Validation Integration
These rules are automatically enforced by:
- **Development environment**: Pre-configured yamllint in devcontainer
- **CI/CD validation**: `yaml-validation.yml` workflow on all changes  
- **Manual validation**: `./scripts/utils/validate-yaml.sh --all-github`

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
# Comprehensive compliance check
./scripts/utils/validate-github-actions-compliance.sh
```

#### Common Issues and Solutions
- **Line length**: Use YAML folding (`>-`) for long descriptions
- **Indentation**: Use consistent 2-space indentation
- **Missing fields**: Ensure composite actions have required `name`, `description`, `runs`
- **Syntax errors**: Check quotes, brackets, and YAML structure
- **File size**: Split large files using modularization patterns

---

## Integration Benefits

### Development Workflow
- **Early feedback**: Validation runs automatically on changes
- **Consistent standards**: Project-wide YAML formatting rules
- **Quality assurance**: Prevents runtime failures from syntax errors
- **Documentation enforcement**: Ensures proper action and workflow documentation

### Maintenance Advantages
- **Automated checks**: No manual validation steps required
- **Standardized configuration**: Single source of truth in `.yamllint`
- **Comprehensive coverage**: All YAML files validated consistently
- **Clear error reporting**: Detailed feedback for quick issue resolution

---

## Changelog Integration

### Required Changelog Updates
Following the baseline principle of **Changelog Maintenance**:
- **Always check CHANGELOG.md** when making changes to workflows or actions
- **Update the Unreleased section** for notable additions, changes, or fixes
- **Follow established format** with clear categorization

#### Examples of changelog-worthy changes
- New workflow creation or major workflow modifications
- Changes to reusable workflow interfaces
- Security or authentication updates
- Performance optimizations or reliability improvements

#### Examples that may not need changelog updates
- Minor comment updates or formatting fixes
- Internal refactoring without functional changes
- Template updates that don't affect existing workflows