---
mode: agent
model: Claude Sonnet 4
description: "Creates new Terraform configurations aligned with Azure Verified Modules (AVM) principles using template-based initialization"
---

# 🚀 Terraform Configuration Initialization Agent

## 🎯 Mission

Create production-ready Terraform configurations for Power Platform governance using a template-based approach that ensures AVM compliance, security-first design, and educational quality for PPCC25 demonstrations.

---

## 📋 Information Collection Phase

### Required User Input (STOP if not provided)

1. **Module Classification** (MANDATORY)
   ```
   res-* : Resource Module - Deploys single Power Platform resource
   ptn-* : Pattern Module - Orchestrates multiple resources  
   utl-* : Utility Module - Exports data without deployment
   ```

2. **Configuration Name** (MANDATORY)
   - Format: `{classification}-{descriptive-name}`
   - Examples: `res-dlp-policy`, `ptn-environment-group`, `utl-export-connectors`

3. **Primary Purpose** (MANDATORY)
   - One sentence describing the configuration's goal

4. **Environment Support** (OPTIONAL)
   - Default: Single environment
   - If multi-environment: Creates `tfvars/` with dev, staging, prod files

### Validation Gates

```yaml
STOP_CONDITIONS:
  - Name doesn't match pattern: {classification}-{descriptive-name}
  - Classification not in: [res-*, ptn-*, utl-*]
  - Primary purpose exceeds 100 characters
  - Template directory missing or incomplete
```

---

## 🏗️ Execution Workflow

### Phase 1: Template Foundation (30% of effort)

#### Step 1.1: Verify Template Integrity
```bash
# MANDATORY: Check template exists
list_dir .github/terraform-configuration-template/

# Expected files (STOP if missing any):
- _header.md
- _footer.md  
- .terraform-docs.yml
```

#### Step 1.2: Copy Template (NEVER create manually)
```bash
# MANDATORY: Use terminal copy command
cp -r .github/terraform-configuration-template configurations/{configuration-name}

# Verify copy success
list_dir configurations/{configuration-name}/
```

#### Step 1.3: Process Templates

**Placeholder Replacement Map:**

| Placeholder                      | Source                | Example Value                                 |
| -------------------------------- | --------------------- | --------------------------------------------- |
| `{{CONFIGURATION_TITLE}}`        | Derived from name     | "DLP Policy Management"                       |
| `{{CONFIGURATION_NAME}}`         | User input            | "res-dlp-policy"                              |
| `{{PRIMARY_PURPOSE}}`            | User input            | "Manages Data Loss Prevention policies"       |
| `{{CLASSIFICATION_PURPOSE}}`     | Classification lookup | "Resource Deployment"                         |
| `{{CLASSIFICATION_DESCRIPTION}}` | Classification lookup | "Deploys primary Power Platform resources"    |
| `{{TFFR2_IMPLEMENTATION}}`       | Classification lookup | "outputting resource IDs as discrete outputs" |
| `{{WORKFLOW_TYPE}}`              | Classification lookup | "Resource Deployment Workflows"               |

**Use Case Generation Rules:**
- ALWAYS generate 4 primary use cases (USE_CASE_1 through USE_CASE_4)
- Add USE_CASE_5 and USE_CASE_6 ONLY for `ptn-*` modules
- Each use case must be specific to the configuration purpose

**Conditional Section Processing:**

```yaml
Include_Sections:
  KEY_FEATURES: 
    when: [res-*, ptn-*]
    content: Generate 4-6 feature bullets
  
  ADDITIONAL_USE_CASES:
    when: [ptn-*]
    content: Add use cases 5-6
  
  CONFIGURATION_CATEGORIES:
    when: Multiple setting types exist
    content: List configuration categories
  
  ENVIRONMENT_EXAMPLES:
    when: Multi-environment support requested
    content: Show environment-specific patterns
  
  SP_PERMISSIONS:
    when: Resource requires special permissions
    content: Include permission scripts
  
  ADVANCED_USAGE:
    when: [ptn-*]
    content: Orchestration patterns
```

### Phase 2: Core File Generation (50% of effort)

#### Step 2.1: Universal Files (ALL configurations)

**versions.tf** - Provider Configuration
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"  # MANDATORY: Centralized version
    }
  }
  backend "azurerm" {
    use_oidc = true  # MANDATORY: OIDC authentication
  }
}

provider "powerplatform" {
  use_oidc = true
}
```

#### Step 2.2: Classification-Specific Files

**Decision Matrix:**

| File         | utl-*            | res-*                   | ptn-*            | Notes                   |
| ------------ | ---------------- | ----------------------- | ---------------- | ----------------------- |
| main.tf      | ✓ Data sources   | ✓ Resources + lifecycle | ✓ Module calls   | Core logic              |
| variables.tf | ⚬ Optional       | ✓ Required              | ✓ Required       | Strong typing MANDATORY |
| outputs.tf   | ✓ Required       | ✓ Required              | ✓ Required       | Anti-corruption layer   |
| tfvars/      | ✗ Never          | ⚬ If multi-env          | ⚬ If multi-env   | Environment configs     |
| tests/       | ✓ 15+ assertions | ✓ 20+ assertions        | ✓ 25+ assertions | Minimum coverage        |

**Mandatory Quality Rules:**

1. **Strong Typing (NO `any` type allowed)**
   ```hcl
   # ❌ FORBIDDEN
   variable "config" {
     type = any
   }
   
   # ✅ REQUIRED
   variable "config" {
     type = object({
       name = string
       tags = map(string)
     })
     validation {
       condition = can(regex("^[a-z0-9-]+$", var.config.name))
       error_message = "Name must be lowercase alphanumeric with hyphens"
     }
   }
   ```

2. **Lifecycle Management (res-* ONLY)**
   ```hcl
   resource "powerplatform_resource" "main" {
     # ... configuration ...
     
     lifecycle {
       # 🔒 GOVERNANCE: Infrastructure as Code enforcement
       # All manual changes treated as drift
       ignore_changes = []
     }
   }
   ```

3. **Comprehensive Comments**
   ```hcl
   # WHY: Brief explanation of design decision
   # CONTEXT: Environmental or organizational requirement
   # IMPACT: What happens if changed
   ```

### Phase 3: Quality Assurance (20% of effort)

#### Step 3.1: Format Validation (MANDATORY)
```bash
cd configurations/{configuration-name}

# Check formatting
terraform fmt -check

# If issues found, auto-correct
terraform fmt

# Re-verify (MUST pass with no output)
terraform fmt -check
```

#### Step 3.2: Syntax Validation
```bash
terraform validate
```

#### Step 3.3: Documentation Update
- Add entry to CHANGELOG.md under "Unreleased/Added"
- Format: `- Add {configuration-name} configuration for {primary purpose}`

---

## 📊 Classification Reference Tables

### Core Characteristics

| Classification | Purpose                 | Output Focus                | Test Strategy                       |
| -------------- | ----------------------- | --------------------------- | ----------------------------------- |
| `utl-*`        | Data export             | Structured data outputs     | Plan tests only (15+ assertions)    |
| `res-*`        | Resource deployment     | Resource IDs and attributes | Plan + Apply tests (20+ assertions) |
| `ptn-*`        | Multi-resource patterns | Orchestrated resource IDs   | Plan + Apply tests (25+ assertions) |

### File Content Patterns

| Classification | main.tf Focus               | variables.tf Complexity | outputs.tf Pattern                |
| -------------- | --------------------------- | ----------------------- | --------------------------------- |
| `utl-*`        | Data sources only           | Simple filters          | Comprehensive data structures     |
| `res-*`        | Single resource + lifecycle | Detailed validation     | Resource ID + computed attributes |
| `ptn-*`        | Module orchestration        | Complex object types    | Multiple resource IDs             |

---

## ✅ Success Criteria Checklist

### Pre-Execution
- [ ] User provided: classification, name, purpose
- [ ] Name follows `{classification}-{descriptive-name}` pattern
- [ ] Template directory verified complete

### During Execution
- [ ] Template copied using `cp -r` (NOT manual creation)
- [ ] All placeholders replaced systematically
- [ ] Conditional sections processed based on classification
- [ ] Files generated according to classification matrix
- [ ] Strong typing enforced (no `any` type)
- [ ] Lifecycle management added for res-* modules
- [ ] Minimum test assertions met

### Post-Execution
- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` passes
- [ ] No remaining `{{PLACEHOLDER}}` markers
- [ ] CHANGELOG.md updated
- [ ] All required files present

---

## 🚨 Common Pitfalls to Avoid

1. **NEVER manually create template files** - Always use `cp -r`
2. **NEVER use `any` type** - Always explicit object types
3. **NEVER skip format validation** - Must pass before completion
4. **NEVER hardcode secrets** - Use OIDC and environment variables
5. **NEVER exceed file limits** - 200 lines maximum per file
6. **NEVER generate summary reports** - Unless explicitly requested

---

## 🎯 Agent Response Template

When executing this prompt, structure your response as:

```markdown
## Configuration Initialization: {configuration-name}

### Understanding Confirmation
- **Classification**: {res-*|ptn-*|utl-*}
- **Purpose**: {primary purpose}
- **Environment Support**: {single|multi}

### Execution Plan
1. Copy template from `.github/terraform-configuration-template/`
2. Replace placeholders for {classification} module
3. Generate {list of files to create}
4. Apply format validation and syntax checks

Shall I proceed with this initialization?
```

After confirmation, execute the workflow and provide:
- Files created/modified
- Key configuration decisions made
- Next steps for the user

---

**FINAL DIRECTIVE**: This prompt optimizes for clarity, consistency, and compliance. Follow the workflow sequentially, validate at each gate, and prioritize quality over speed.