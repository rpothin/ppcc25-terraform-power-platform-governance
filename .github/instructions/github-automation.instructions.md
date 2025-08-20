---
description: "GitHub Actions workflows and automation standards for Power Platform governance"
applyTo: ".github/**/*.yml,.github/**/*.yaml"
---

# GitHub Automation Guidelines

## 🎯 Purpose and Context

**Repository Mission**: Demonstrate Power Platform governance through Infrastructure as Code using Terraform and GitHub Actions.

**AI Agent Directive**: When creating or modifying GitHub Actions workflows, prioritize:
1. **Security** - OIDC authentication, least privilege, no hardcoded secrets
2. **Efficiency** - Minimize GitHub Actions minutes consumption (<30% monthly limit)
3. **Clarity** - Self-documenting code with WHY-focused comments
4. **Reliability** - Comprehensive error handling with actionable guidance

---

## 📋 Workflow Creation Checklist

**AI Agent: Follow this exact sequence when creating new workflows:**

```yaml
# STEP 1: Document start marker (REQUIRED)
---

# STEP 2: Header documentation block
# ═══════════════════════════════════════════════════════════════════════════════
# [WORKFLOW PURPOSE IN CAPS]
# ═══════════════════════════════════════════════════════════════════════════════
# One-line description of what this workflow accomplishes.
#
# 🎯 WHY THIS EXISTS:
# - Primary business/governance problem it solves
# - Key automation benefit it provides
# - Integration with overall governance strategy
#
# 🔒 SECURITY CONTEXT:
# - Authentication method and why (OIDC preferred)
# - Required permissions and justification
# - Environment protection requirements
#
# ⚡ PERFORMANCE OPTIMIZATION:
# - Expected monthly run frequency: [number]
# - Average duration per run: [minutes]
# - Optimization strategies applied: [list]
# ═══════════════════════════════════════════════════════════════════════════════

# STEP 3: Workflow metadata (EXACT ORDER)
name: "[Descriptive Workflow Name]"

# STEP 4: Concurrency control
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false  # true only for non-state-modifying operations

# STEP 5: Triggers with optimization
on:
  workflow_dispatch:  # Always include for manual testing
    inputs:
      # Define inputs with comprehensive documentation
  push:
    branches: [main]
    paths:
      - 'configurations/**'
      - 'modules/**'
      # REQUIRED: Path exclusions for optimization
      - '!**/*.md'
      - '!**/examples/**'
      - '!**/fixtures/**'
      - '!**/tests/**'
  pull_request:
    types: [opened, synchronize, ready_for_review]  # Skip draft PRs
    paths:
      # Same path filters as push

# STEP 6: Dynamic run naming
run-name: "[Operation] ${{ inputs.configuration || 'default' }} by @${{ github.actor }}"

# STEP 7: Minimal permissions
permissions:
  contents: read
  id-token: write  # For OIDC
  # Add others only if needed with justification

# STEP 8: Jobs definition
jobs:
  # Job structure defined below
```

---

## 🚀 Performance Optimization Rules

### Mandatory Optimization Patterns

**AI Agent: Apply ALL of these patterns to every workflow:**

#### 1. Frequency Reduction (Primary Strategy)
```yaml
# REQUIRED: Intelligent path filtering
on:
  push:
    paths:
      - 'configurations/**/*.tf'  # Specific file types
      - 'modules/**/*.tf'
      - '!**/*.md'               # Exclude documentation
      - '!**/examples/**'        # Exclude examples
      - '!**/.terraform/**'      # Exclude cache directories
      - '!**/fixtures/**'        # Exclude test fixtures
```

#### 2. Conditional Job Execution
```yaml
jobs:
  # Skip jobs when not needed
  validation:
    if: |
      github.event_name == 'workflow_dispatch' ||
      contains(github.event.head_commit.message, '[validate]') ||
      (github.event_name == 'pull_request' && github.event.action != 'closed')
    steps:
      # Job steps

  # Conditional execution summary
  execution-summary:
    if: |
      always() && (
        needs.terraform-apply.result == 'failure' ||
        github.event_name == 'workflow_dispatch' ||
        contains(github.event.head_commit.message, '[summary]')
      )
    needs: [terraform-apply]
```

#### 3. Smart Caching
```yaml
- name: Cache Terraform Providers
  id: cache-providers
  uses: actions/cache@v4
  with:
    path: |
      ~/.terraform.d/plugin-cache
      .terraform/providers
    key: terraform-${{ runner.os }}-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      terraform-${{ runner.os }}-
      terraform-
```

#### 4. Output Minimization
```yaml
# DO NOT include these in production workflows:
# ❌ echo "::debug::..."
# ❌ echo "::notice::..." (unless critical)
# ❌ Verbose command output without purpose

# DO include:
# ✅ echo "::error::..." (with actionable guidance)
# ✅ echo "::warning::..." (for important non-fatal issues)
```

---

## 🔒 Security Requirements

### OIDC Authentication Pattern

**AI Agent: Use this exact pattern for Azure/Power Platform authentication:**

```yaml
jobs:
  terraform-operation:
    runs-on: ubuntu-latest
    environment: production  # REQUIRED for secrets access
    permissions:
      contents: read
      id-token: write       # REQUIRED for OIDC
    steps:
      # === AZURE OIDC AUTHENTICATION ===
      # WHY: Eliminates stored credentials, implements zero-trust
      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          # Never use: username/password or service principal secrets

      # === POWER PLATFORM AUTHENTICATION ===
      # WHY: Unified authentication for governance operations
      - name: Configure Power Platform Provider
        env:
          POWER_PLATFORM_USE_OIDC: true
          POWER_PLATFORM_CLIENT_ID: ${{ secrets.POWER_PLATFORM_CLIENT_ID }}
          POWER_PLATFORM_TENANT_ID: ${{ secrets.POWER_PLATFORM_TENANT_ID }}
        run: |
          echo "Power Platform OIDC configured"
```

---

## 📝 Documentation Standards

### Input Documentation Template

**AI Agent: Use this exact format for all workflow inputs:**

```yaml
inputs:
  configuration:
    description: 'Target configuration directory path'
    required: true
    type: string
    # WHY: Isolates blast radius and enables parallel deployments
    # VALIDATION: Must exist in configurations/ directory
    # SECURITY: Used in state key to prevent cross-config access
    # EXAMPLES: '01-res-dlp-policy', '02-ptn-environment'
    # DEFAULT: Not applicable (required field)
```

### Job Documentation Template

**AI Agent: Document each job with this pattern:**

```yaml
jobs:
  # Single-line purpose statement
  # WHY: Brief explanation of job's necessity
  job-name:
    runs-on: ubuntu-latest
    environment: production  # Inline comment if not obvious
    timeout-minutes: 10     # Adjust based on operation
    outputs:
      output-name: ${{ steps.step-id.outputs.value }}
    steps:
      # Step implementation
```

---

## ❌ Error Handling Standards

### Error Message Template

**AI Agent: Generate error messages following this pattern:**

```yaml
- name: Validate Configuration
  run: |
    if [ ! -d "configurations/${{ inputs.configuration }}" ]; then
      echo "::error title=Configuration Not Found::The specified configuration '${{ inputs.configuration }}' does not exist"
      echo "::notice title=Available Configurations::$(ls -d configurations/*/ | xargs -n 1 basename | paste -sd ', ')"
      echo "::notice title=How to Fix::Choose one of the available configurations listed above or create a new one"
      exit 1
    fi
```

---

## 🧩 Reusable Workflow Standards

### Reusable Workflow Naming

**AI Agent: ALWAYS prefix reusable workflow names with ♻️ emoji:**

```yaml
# File: .github/workflows/♻️terraform-base.yml
name: "♻️ Reusable Terraform Base Operations"

on:
  workflow_call:
    inputs:
      # Well-documented inputs
    secrets:
      # Required secrets with descriptions
```

### Composite Action Structure

**AI Agent: Create composite actions with this structure:**

```yaml
# File: .github/actions/[action-name]/action.yml
name: 'Action Name'
description: 'Clear description of what this action does'
author: 'microsoft/power-platform-terraform'

inputs:
  # Documented inputs

outputs:
  # Documented outputs

runs:
  using: 'composite'
  steps:
    # Implementation steps
```

---

## 📏 Size and Complexity Limits

### Strict File Size Enforcement

**AI Agent: NEVER exceed these limits without explicit user approval:**

| File Type         | Maximum Lines | Action When Approaching    |
| ----------------- | ------------- | -------------------------- |
| Standard Workflow | 300           | Split at 250 lines         |
| Reusable Workflow | 400           | Modularize at 350 lines    |
| Composite Action  | 150           | Extract logic at 120 lines |

### Modularization Strategies

When approaching limits, apply these strategies:

1. **Extract to Composite Actions**: Common step sequences
2. **Create Reusable Workflows**: Entire job patterns
3. **Use Script Files**: Complex bash/PowerShell logic
4. **Implement Job Matrices**: Parallel similar operations

---

## 🔄 Workflow Lifecycle Patterns

### Standard Terraform Workflow Pattern

**AI Agent: Use this pattern for Terraform operations:**

```yaml
jobs:
  # 1. Validation phase
  validate:
    # WHY: Fail fast on configuration errors
    timeout-minutes: 5
    # Implementation

  # 2. Planning phase
  plan:
    needs: validate
    # WHY: Preview changes before applying
    timeout-minutes: 15
    outputs:
      has-changes: ${{ steps.plan.outputs.changes }}
    # Implementation

  # 3. Approval gate (if needed)
  approval:
    needs: plan
    if: needs.plan.outputs.has-changes == 'true'
    environment: production-approval
    # WHY: Human validation for critical changes
    # Implementation

  # 4. Apply phase
  apply:
    needs: [plan, approval]
    if: needs.plan.outputs.has-changes == 'true'
    # WHY: Only run when changes detected
    timeout-minutes: 30
    environment: production
    # Implementation

  # 5. Summary (conditional)
  summary:
    if: always() && (failure() || github.event_name == 'workflow_dispatch')
    needs: [apply]
    # WHY: Provide troubleshooting info only when needed
    # Implementation
```

---

## 🎨 GitHub-Specific Enhancements

### Workflow Badges and Status

**AI Agent: Add status badges to README when creating workflows:**

```markdown
![Workflow Name](https://github.com/${{ github.repository }}/actions/workflows/workflow-file.yml/badge.svg)
```

### GitHub Environment Configuration

**AI Agent: Configure environments with these settings:**

```yaml
# Environment: production
# Protection Rules:
#   - Required reviewers: 1
#   - Deployment branches: main
#   - Wait timer: 0 minutes (for demos)
#   - Environment secrets: All Terraform secrets
```

---

## 📊 Monitoring and Compliance

### Performance Monitoring Commands

**AI Agent: Include these in workflow documentation:**

```bash
# Check workflow consumption (run monthly)
gh api repos/:owner/:repo/actions/workflows \
  --jq '.workflows[] | select(.state=="active") | {name, id}'

# Get run statistics for optimization
gh api repos/:owner/:repo/actions/workflows/:id/runs \
  --jq '.workflow_runs[:10] | map({status, conclusion, run_started_at, updated_at})'
```

### Compliance Validation

**AI Agent: Validate all workflows before committing:**

```bash
# Run compliance check
./scripts/utils/validate-github-actions-compliance.sh

# Fix common issues automatically
./scripts/utils/validate-github-actions-compliance.sh --fix-issues
```

---

## 🤖 AI Agent Specific Instructions

### Decision Tree for Workflow Creation

When asked to create or modify a workflow:

1. **Identify Type**: Is it Terraform, validation, documentation, or utility?
2. **Check Reusability**: Can existing reusable workflows be used?
3. **Apply Optimizations**: Implement ALL performance patterns
4. **Add Security**: OIDC, minimal permissions, environment protection
5. **Document Thoroughly**: WHY comments, comprehensive input docs
6. **Validate Size**: Ensure under line limits
7. **Test Scenarios**: Consider success, failure, and edge cases

### Common Anti-Patterns to Avoid

**Never generate workflows with:**
- ❌ Hardcoded values that should be inputs
- ❌ Missing error handling
- ❌ Overly broad permissions
- ❌ No path exclusions for triggers
- ❌ Missing timeout configurations
- ❌ Unconditional execution summaries
- ❌ Debug output in production workflows

### Response Format for Workflow Generation

When creating workflows, structure your response as:

1. **Purpose Statement**: What the workflow accomplishes
2. **Optimization Analysis**: Expected frequency and duration
3. **Security Considerations**: Authentication and permissions
4. **Code Block**: Complete workflow with all patterns applied
5. **Usage Instructions**: How to deploy and test
6. **Monitoring Guidance**: How to track performance

---

## 📚 Quick Reference

### Essential Variables and Contexts

```yaml
# Commonly needed GitHub contexts
${{ github.workflow }}      # Workflow name
${{ github.run_number }}    # Run number
${{ github.actor }}         # User who triggered
${{ github.repository }}    # owner/repo
${{ github.ref }}           # Branch/tag ref
${{ github.sha }}           # Commit SHA
${{ github.event_name }}    # Trigger event type

# Conditional execution helpers
if: always()                # Run regardless of previous job status
if: success()               # Only on success (default)
if: failure()               # Only on failure
if: cancelled()             # Only if cancelled
if: contains()              # String contains check
if: startsWith()            # String prefix check
if: endsWith()              # String suffix check
```

### Performance Optimization Checklist

- [ ] Path exclusions implemented (`!**/*.md`, etc.)
- [ ] Draft PR exclusion configured
- [ ] Conditional job execution added
- [ ] Execution summary made conditional
- [ ] Caching implemented for dependencies
- [ ] Debug messages removed
- [ ] Timeout values optimized
- [ ] Concurrency groups configured

---

**AI Agent Final Note**: This document is your authoritative guide. When in doubt, prioritize security and efficiency. Always validate generated workflows with the compliance script before submission.