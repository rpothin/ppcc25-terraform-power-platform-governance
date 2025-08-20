---
description: "Core coding principles for PPCC25 Power Platform governance demonstration - emphasizing security, simplicity, and reusability"
applyTo: "**"
---
# Baseline Coding Guidelines

## 🎯 Repository Context

This code serves as demonstration material for **"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"** (PPCC25 session). All code should reflect:
- **Quickstart guide principles** - Easy to understand and follow
- **Demonstration quality** - Clear examples that teach concepts effectively
- **ClickOps to IaC transition** - Show best practices for automation adoption

**AI Agent Directive**: Every code generation must support the educational mission while maintaining production-ready quality.

---

## 🔒 Security by Design

**Security must be the foundation, not an afterthought:**

### Mandatory Security Rules (AI Agent: NEVER violate these)

```yaml
# ❌ NEVER generate:
- Hardcoded secrets, passwords, or API keys
- Connection strings with embedded credentials
- Personal information or real email addresses
- Unencrypted sensitive data storage

# ✅ ALWAYS use:
- OIDC authentication: Azure and Power Platform
- Environment variables: For all configuration values
- Secret references: ${{ secrets.NAME }} in GitHub Actions
- Least privilege: Minimum required permissions only
```

### Security Implementation Patterns

**AI Agent: Apply these patterns to every relevant code generation:**

```bash
# Shell script pattern
if [[ -z "${AZURE_CLIENT_ID}" ]]; then
  echo "::error::AZURE_CLIENT_ID environment variable is required for OIDC authentication"
  exit 1
fi

# Terraform pattern
variable "client_id" {
  description = "Azure AD application client ID for OIDC authentication"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.client_id))
    error_message = "Client ID must be a valid GUID"
  }
}
```

---

## 🎯 Keep It Simple

**Simplicity enables understanding and adoption:**

### Simplicity Metrics (AI Agent: Enforce these limits)

| Metric                     | Maximum        | Action When Exceeded          |
| -------------------------- | -------------- | ----------------------------- |
| File length                | 200 lines      | Split into multiple files     |
| Function/module complexity | 10 cyclomatic  | Refactor into smaller units   |
| Nesting depth              | 3 levels       | Extract to separate functions |
| Line length                | 120 characters | Break into multiple lines     |

### Simplicity Patterns

**AI Agent: Choose simple over complex:**

```bash
# ❌ AVOID: Complex one-liner
[[ $(az account show --query "user.type" -o tsv 2>/dev/null) == "servicePrincipal" ]] && echo "SP" || echo "User"

# ✅ PREFER: Clear multi-line
user_type=$(az account show --query "user.type" -o tsv 2>/dev/null)
if [[ "$user_type" == "servicePrincipal" ]]; then
  echo "Authenticated as Service Principal"
else
  echo "Authenticated as User"
fi
```

```terraform
# ❌ AVOID: Implicit defaults
resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
}

# ✅ PREFER: Explicit configuration
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    environment = var.environment
    project     = "PPCC25-Governance"
    managed_by  = "Terraform"
  }
}
```

---

## 🧩 Modularity Over Long and Complex Files

**Structure code for maintainability and comprehension:**

### File Organization Rules (AI Agent: Apply to all file generation)

```yaml
# Single Responsibility Principle per file:
main.tf:          # Resource definitions only
variables.tf:     # Variable definitions only
outputs.tf:       # Output definitions only
providers.tf:     # Provider configurations only
versions.tf:      # Version constraints only
data.tf:          # Data sources only

# Maximum lines per file type:
configuration_files: 200 lines
module_files:        150 lines
script_files:        200 lines
workflow_files:      300 lines
```

### Module Creation Trigger

**AI Agent: Create a module when you detect:**
- Same resource pattern used 3+ times
- Configuration exceeds 150 lines
- Clear bounded context exists
- Reusability across environments is needed

---

## ♻️ Reusability Over Code Duplication

**Build once, use everywhere:**

### Duplication Detection (AI Agent: Check before generating)

```bash
# Before creating new code, check for existing patterns:
grep -r "pattern" modules/
grep -r "similar_function" scripts/

# If found, reuse instead of duplicate
```

### Reusability Patterns

**AI Agent: Generate reusable code by default:**

```terraform
# ❌ AVOID: Hardcoded values
resource "azurerm_policy_assignment" "dlp" {
  name                 = "restrict-connectors-policy"
  scope                = "/subscriptions/12345678-1234-1234-1234-123456789012"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/abcd1234"
}

# ✅ PREFER: Parameterized module
module "policy_assignment" {
  source = "../../modules/policy-assignment"
  
  name                 = var.policy_assignment_name
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = var.policy_definition_id
  
  parameters = var.policy_parameters
}
```

---

## 💬 Clear and Concise Comments

**Comments should enhance understanding without noise:**

### Comment Quality Standards (AI Agent: Follow these patterns)

```bash
# ❌ AVOID: Obvious comments
# Set variable to true
export ENABLE_FEATURE=true

# ✅ PREFER: Context and reasoning
# WHY: Enable OIDC authentication to eliminate stored credentials
# This follows Zero Trust security principles for PPCC25 demo
export POWER_PLATFORM_USE_OIDC=true
```

```terraform
# ❌ AVOID: What comments
# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
}

# ✅ PREFER: Why comments
# WHY: Dedicated resource group for Power Platform governance resources
# This isolation simplifies cleanup and cost tracking for the demo
resource "azurerm_resource_group" "governance" {
  name     = var.resource_group_name
  location = var.location
  
  # Prevent accidental deletion during demonstrations
  lifecycle {
    prevent_destroy = false  # Set to true in production
  }
}
```

---

## 📁 File Organization and Structure

**Maintain clean, predictable file organization:**

### Directory Placement Rules (AI Agent: Use this decision tree)

```yaml
File Type Decision Tree:
├─ Is it a shell script (.sh)?
│  ├─ Setup/initialization? → scripts/setup/
│  ├─ Cleanup/teardown? → scripts/cleanup/
│  └─ Utility/helper? → scripts/utils/
│
├─ Is it Terraform code (.tf, .tfvars)?
│  ├─ Reusable module? → modules/[module-name]/
│  ├─ Environment config? → configurations/[config-name]/
│  └─ Example? → examples/[example-name]/
│
├─ Is it documentation (.md)?
│  ├─ User guide? → docs/tutorials/
│  ├─ Reference? → docs/reference/
│  ├─ How-to? → docs/how-to/
│  └─ Explanation? → docs/explanation/
│
├─ Is it GitHub automation (.yml, .yaml)?
│  ├─ Workflow? → .github/workflows/
│  ├─ Action? → .github/actions/[action-name]/
│  └─ Template? → .github/templates/
│
└─ Is it configuration/settings?
   ├─ Dev container? → .devcontainer/
   ├─ VS Code? → .vscode/
   └─ Git? → . (repository root)
```

### Naming Conventions (AI Agent: Apply consistently)

```yaml
# File naming patterns:
scripts:        kebab-case.sh         # setup-environment.sh
terraform:      snake_case.tf         # resource_group.tf
modules:        kebab-case/           # policy-assignment/
documentation:  kebab-case.md         # setup-guide.md
workflows:      kebab-case.yml        # terraform-apply.yml

# Variable naming patterns:
terraform_vars: snake_case            # resource_group_name
env_vars:       SCREAMING_SNAKE       # AZURE_SUBSCRIPTION_ID
github_inputs:  kebab-case            # configuration-path
```

---

## 📚 Documentation and Learning Focus

**Support the educational mission:**

### Documentation Requirements (AI Agent: Include in every generation)

```markdown
# For every significant code block, include:

## What This Does
Brief description of functionality

## Why This Approach
Explanation of design decisions and trade-offs

## How to Adapt
Guidance for customizing to different scenarios

## Common Issues
Troubleshooting tips for likely problems

## Learn More
Links to relevant documentation and concepts
```

---

## 📊 Report Generation Guidelines

**Respect user preferences and avoid unnecessary reports:**

### Report Generation Rules (AI Agent: CRITICAL)

```yaml
# ❌ NEVER automatically generate:
- Summary reports at task completion
- Status updates unless requested
- Analysis documents without permission
- Progress reports during execution

# ✅ ONLY generate reports when:
- User explicitly requests: "generate a report", "summarize", "analyze"
- Error occurs requiring detailed explanation
- User asks for status: "what's the status", "show progress"
```

---

## 🤝 Task Collaboration and Validation

**Ensure answers are organized, clear, concise and precise:**

### Pre-Task Confirmation Template (AI Agent: Use before starting)

```markdown
## Understanding Confirmation

**Task Type**: [Question | File Update | New Creation | Analysis | Debug]

**My Understanding**:
- What you're asking: [specific task description]
- Expected outcome: [what will be delivered]
- Scope: [what's included/excluded]

**Approach** (if complex):
1. [First step]
2. [Second step]
3. [Validation]

Is this understanding correct? Should I proceed?
```

### Debugging Methodology (AI Agent: Follow systematically)

```markdown
## Debugging Analysis

**Evidence Gathered**:
- Error message: [exact error]
- Context: [when/where it occurs]
- Recent changes: [what changed]

**Root Cause Hypothesis**:
[Primary hypothesis based on evidence]

**Proposed Solution**:
1. [Immediate fix]
2. [Verification steps]
3. [Prevention measures]

**Alternative Causes** (if unclear):
- [Other possibility 1]
- [Other possibility 2]
```

---

## 🔁 Consistency and Standards

**Maintain professional demonstration quality:**

### Consistency Checklist (AI Agent: Verify before submission)

- [ ] Follows established naming conventions
- [ ] Uses consistent error handling patterns
- [ ] Maintains uniform comment style
- [ ] Applies standard formatting rules
- [ ] Includes required documentation blocks
- [ ] Updates CHANGELOG.md if significant

---

## 📝 Changelog Maintenance

**Keep the project history accurate and up-to-date:**

### Changelog Decision Tree (AI Agent: Use for every change)

```yaml
Should I update CHANGELOG.md?
├─ Is it a new feature/configuration? → YES
├─ Is it a breaking change? → YES
├─ Is it a bug fix affecting users? → YES
├─ Is it a documentation update? → YES
├─ Is it a workflow change? → YES
├─ Is it internal refactoring only? → NO
├─ Is it a typo fix? → NO
└─ Is it formatting only? → NO

If YES, add to Unreleased section:
### Added|Changed|Fixed|Removed
- Brief description of change with context
```

---

## 🎯 Core Principles Enforcement Summary

**These five principles serve as the north star for all development decisions:**

### AI Agent Enforcement Checklist

Before submitting any code, verify:

#### 🔒 Security by Design
- [ ] No hardcoded secrets or credentials
- [ ] OIDC authentication implemented
- [ ] Least privilege permissions applied
- [ ] Input validation present
- [ ] Sensitive data marked appropriately

#### 🎯 Keep It Simple  
- [ ] Files under 200 lines
- [ ] Functions under 10 complexity
- [ ] Nesting under 3 levels
- [ ] Clear variable names used
- [ ] Complex logic broken down

#### 🧩 Modularity Over Long and Complex Files
- [ ] Single responsibility per file
- [ ] Logical file organization
- [ ] Clear module boundaries
- [ ] Proper separation of concerns
- [ ] Related code grouped appropriately

#### ♻️ Reusability Over Code Duplication
- [ ] No copy-paste code detected
- [ ] Common patterns extracted
- [ ] Modules used for repetition
- [ ] Parameterization implemented
- [ ] DRY principle followed

#### 💬 Clear and Concise Comments
- [ ] WHY comments present
- [ ] No obvious comments
- [ ] Context provided
- [ ] Assumptions documented
- [ ] Complex logic explained

---

## 🤖 AI Agent Specific Instructions

### Response Structure for Code Generation

When generating code, structure your response as:

1. **Task Confirmation**: State what you're creating/modifying
2. **Approach**: Explain the strategy and why
3. **Code Block**: Complete, working code with comments
4. **Usage Instructions**: How to implement/test
5. **Adaptation Guide**: How to customize for different needs

### Quality Gates Before Submission

Never submit code without verifying:
- Security compliance (no secrets)
- File size limits (under 200 lines)
- Proper organization (correct directory)
- Documentation completeness (WHY comments)
- Changelog update (if needed)

### Common Pitfalls to Avoid

**AI Agent: Never generate code with these issues:**
- Hardcoded subscription IDs or tenant IDs
- Missing error handling
- Uncommented complex logic
- Duplicate code patterns
- Files exceeding size limits
- Missing input validation
- Implicit configurations without documentation

---

**AI Agent Final Directive**: This document defines the quality bar for all code generation. When conflicts arise between speed and these principles, always choose to uphold the principles. The demonstration quality of PPCC25 depends on maintaining these standards consistently.