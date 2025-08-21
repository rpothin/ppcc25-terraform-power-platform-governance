---
description: "Terraform Infrastructure as Code standards following Azure Verified Modules (AVM) principles"
applyTo: "configurations/**,modules/**"
---

# Terraform Infrastructure as Code Guidelines

## 🎯 Introduction & Purpose

This document provides Terraform standards for **"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"** (PPCC25 session). These guidelines ensure:
- **Demonstration quality** - Clear examples that teach IaC concepts effectively
- **AVM compliance** - Following Azure Verified Module principles where applicable
- **Power Platform governance** - Specific patterns for DLP policies, environments, and connectors
- **Progressive complexity** - From basic concepts to advanced implementation patterns

## 🚀 Pre-Development Checklist

**AI Agent: MANDATORY - Complete this checklist before writing any Terraform code**

### Module Setup Requirements
- [ ] Confirm module type classification (utl-, res-, ptn-)
- [ ] Create directory structure with all required files
- [ ] Add .terraform-docs.yml configuration
- [ ] Verify provider version matches centralized standard (~> 3.8)

### File Creation Requirements  
- [ ] **main.tf** - Primary resource definitions (modules for ptn-*, resources for res-*)
- [ ] **variables.tf** - Input parameters (all with validation blocks)
- [ ] **outputs.tf** - Anti-corruption layer outputs only
- [ ] **versions.tf** - Provider and version constraints (child module format for res-*)
- [ ] **tests/integration.tftest.hcl** - Test assertions with provider blocks for child modules

### Child Module Compliance (res-* modules only)
- [ ] **No provider blocks** in versions.tf (inherit from parent - Required by Terraform meta-argument compatibility)
- [ ] **No backend blocks** in versions.tf (inherit from parent - Required by Terraform meta-argument compatibility)
- [ ] **File length under 20 lines** for versions.tf
- [ ] **Compatible with meta-arguments** (for_each, count, depends_on - Fundamental Terraform requirement)

### Variable Standards Verification
- [ ] All variables use explicit object types (no `type = any`)
- [ ] All variables have HEREDOC descriptions with examples
- [ ] All object variables include property-level validation
- [ ] Error messages provide actionable guidance

### Output Standards Verification
- [ ] Outputs use discrete values (no full resource exposure)
- [ ] All outputs have comprehensive descriptions
- [ ] Summary outputs aggregate key configuration details
- [ ] Anti-corruption layer pattern implemented consistently

### Testing Requirements Verification
- [ ] **utl-* modules**: Minimum 15 test assertions (plan only)
- [ ] **res-* modules**: Minimum 20 test assertions + lifecycle blocks (plan and apply)
- [ ] **ptn-* modules**: Minimum 25 test assertions (plan and apply with phase separation)
- [ ] All tests use consolidated assertion blocks (performance optimization)
- [ ] **Plan/Apply Separation**: Static validation in plan, runtime validation in apply
- [ ] **Provider blocks in test files** for child module compatibility

## 📚 Azure Verified Modules (AVM) Foundation

**AI Agent: AVM principles serve as the northstar for all Terraform code:**
- Implement AVM-inspired patterns even with Power Platform provider limitations
- Follow AVM specification TFNFR27: Provider configurations should be passed from parent modules
- Follow AVM specification PMNFR2: Pattern modules should be built from resource modules
- Document all AVM compliance exceptions with clear justification
- Maintain AVM quality standards for testing, documentation, and governance
- Plan for future transition to full AVM compliance when technically feasible

### ⚠️ Critical Anti-Pattern Warning

**AI Agent: NEVER allow pattern modules to directly create resources** - this violates AVM principles and creates maintenance debt:

```hcl
# ❌ FORBIDDEN: Direct resource creation in pattern modules
resource "powerplatform_environment_group" "this" { ... }
resource "powerplatform_environment" "environments" { ... }

# ✅ REQUIRED: Module orchestration in pattern modules
module "environment_group" { source = "../res-environment-group" }
module "environments" { source = "../res-environment" }
```

### Module Classifications

**AI Agent: Use this decision tree for module type selection:**

```yaml
Module Type Decision:
├─ Does it deploy Power Platform resources?
│  ├─ Single resource type? → res-* (child module)
│  └─ Multiple resources? → ptn-* (orchestration)
└─ Does it only query/transform data? → utl-* (utility)
```

- **Resource Modules (`res-*`)**: Deploy primary Power Platform resources (DLP policies, environments) - MUST be child modules
- **Pattern Modules (`ptn-*`)**: Orchestrate multiple resource modules using composable patterns - MUST NOT create resources directly
- **Utility Modules (`utl-*`)**: Provide reusable data sources without deploying resources (connector exports)

## 🏗️ Basic Terraform Standards

### Code Structure and Formatting

**AI Agent: Apply these standards to every Terraform file:**

- Use consistent formatting with `terraform fmt` for all configuration files
- Separate concerns using multiple .tf files (main.tf, variables.tf, outputs.tf, versions.tf)
- Keep individual files under 200 lines when possible (baseline principle: modularity)
- Group related resources logically within files
- Use meaningful comments that explain "why" decisions were made (baseline principle: clear comments)

### Mandatory Validation (Gate Requirement)

**AI Agent: All Terraform code must pass these validations before any commit or pull request:**

1. **Format Validation**: `terraform fmt -check` (auto-fix with `terraform fmt`)
2. **Syntax Validation**: `terraform validate` (all configurations must pass)
3. **Test Validation**: `terraform test` (all assertions must pass)
4. **Module-Specific Requirements**:
   - `utl-*`: Minimum 15 test assertions
   - `res-*`: Minimum 20 test assertions + lifecycle blocks
   - `ptn-*`: Minimum 25 test assertions

**Gate Policy**: Code that fails any validation check cannot be merged until fixed.

*Why: This process ensures AVM compliance, CI/CD reliability, and consistent code quality while supporting baseline principles of security by design and simplicity.*

### File Organization (AVM-Inspired)

**AI Agent: Create this exact structure for all modules:**

```
configurations/{module-name}/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input parameters with validation
├── outputs.tf          # Discrete outputs (anti-corruption layer)
├── versions.tf         # Provider and version constraints
├── locals.tf           # Complex transformation logic (when main.tf > 150 lines)
├── README.md           # Auto-generated documentation
├── .terraform-docs.yml # Documentation configuration
└── tests/
    └── integration.tftest.hcl
```

### Provider/Backend Block Limitation: Expected Terraform Behavior

**AI Agent CRITICAL UNDERSTANDING: The restriction "Child modules with provider/backend blocks cannot be used with meta-arguments" is fundamental Terraform behavior by design, not a bug.**

**Technical Background:**
When a child module contains its own `provider` or `backend` blocks, Terraform restricts the use of meta-arguments (`count`, `for_each`, `depends_on`) on that module. This limitation exists because:

1. **Provider Configuration Conflicts**: Child modules with their own provider configurations create ambiguity about which provider configuration should be used
2. **Module Instantiation Issues**: Meta-arguments like `count` and `for_each` require precise control over provider configurations, which conflicts with modules that define their own providers  
3. **Legacy Compatibility**: This restriction maintains backward compatibility while encouraging modern best practices

**AI Agent Action**: Always remove provider/backend blocks from res-* modules.

### Child Module Requirements (res-* modules)

**AI Agent: CRITICAL - All `res-*` modules MUST be designed as child modules for orchestration compatibility**

#### versions.tf Format (MANDATORY)

**AI Agent: Use this exact format for res-* module versions.tf:**

```hcl
# Child module versions.tf (UNDER 20 LINES)
# This format ensures compatibility with meta-arguments (for_each, count, depends_on)
# and aligns with AVM specification TFNFR27
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
  # NO provider or backend blocks in child modules
  # Provider configuration is inherited from parent/root module
}
```

#### Integration Test Requirements

**AI Agent: Include provider block in test files for child modules:**

```hcl
# MUST include provider block in test files
provider "powerplatform" {
  use_oidc = true
}
```

## 🔌 Power Platform Specifics

### Provider Configuration (Centralized Standard)

**AI Agent: Use this exact provider configuration for all root modules:**

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"  # Centralized standard - all modules must match
    }
  }
  # Azure backend with OIDC for secure, keyless authentication
  backend "azurerm" {
    use_oidc = true
  }
}

provider "powerplatform" {
  use_oidc = true  # Enhanced security over client secrets (baseline: security by design)
}
```

*Why `~> 3.8`: This version provides stable Power Platform resource management while allowing patch updates.*

### Authentication and Security

**AI Agent: Apply these security patterns to all Power Platform code:**

- **OIDC authentication** for all Azure and Power Platform connections (no client secrets)
- **Azure Storage backend** with OIDC for state management
- **Never hardcode** sensitive values in configuration files (baseline: security by design)
- **Use Azure Key Vault** or environment variables for secrets
- **Apply principle of least privilege** for all permissions

### Resource Naming and Tagging

**AI Agent: Use this naming pattern for all Power Platform resources:**

```hcl
# Consistent naming pattern for Power Platform resources
resource "powerplatform_data_loss_prevention_policy" "example" {
  display_name = "${var.environment}-${var.policy_name}-dlp"  # env-purpose-type
  
  # Include tags for governance where supported
  # Note: Power Platform has limited tagging support vs Azure resources
}
```

## 📝 Variables and Outputs Standards

### Variable Requirements (Strong Typing)

**AI Agent: MANDATORY - All variables must use this exact pattern:**

```hcl
variable "dlp_policy_config" {
  type = object({
    display_name                      = string
    default_connectors_classification = string
    environment_type                  = string
  })
  description = <<DESCRIPTION
Configuration for Data Loss Prevention policy creation.

This variable consolidates core DLP settings to reduce complexity while
ensuring all connector classifications are intentionally defined.

Properties:
- display_name: Human-readable name for the DLP policy (max 50 chars)
- default_connectors_classification: Default classification (Business/NonBusiness)
- environment_type: Target environment type (Production, Sandbox, etc.)

Example:
dlp_policy_config = {
  display_name                      = "Corporate Data Protection Policy"
  default_connectors_classification = "Business"
  environment_type                  = "Production"
}

Validation Rules:
- Display name must be unique within tenant
- Connector classification must match Power Platform standards
DESCRIPTION

  validation {
    condition     = length(var.dlp_policy_config.display_name) <= 50
    error_message = "Display name must be 50 characters or less for Power Platform compatibility. Current length: ${length(var.dlp_policy_config.display_name)}. Please shorten the name."
  }
  
  validation {
    condition     = contains(["Business", "NonBusiness"], var.dlp_policy_config.default_connectors_classification)
    error_message = "Connector classification must be either 'Business' or 'NonBusiness'. Received: '${var.dlp_policy_config.default_connectors_classification}'. Check Power Platform documentation for valid values."
  }
}
```

**AI Agent Forbidden Practices:**
- ❌ `type = any` (use explicit object types)
- ❌ Variables without validation rules
- ❌ Single-line descriptions (use HEREDOC format)
- ❌ Generic error messages without actionable guidance

### Enhanced Validation Patterns

**AI Agent: Use actionable error messages in all validation blocks:**

```hcl
# ✅ Good: Actionable error message with guidance
validation {
  condition     = length(var.policy_name) > 0 && length(var.policy_name) <= 50
  error_message = "Policy name must be 1-50 characters. Current: ${length(var.policy_name)} chars. Consider shortening '${var.policy_name}' to meet Power Platform limits."
}

# ❌ Bad: Generic error message
validation {
  condition     = length(var.policy_name) <= 50
  error_message = "Policy name too long."
}
```

### Output Standards (Anti-Corruption Layer)

**AI Agent: Implement discrete outputs instead of exposing full resource objects:**

```hcl
# ✅ Good: Discrete, useful outputs
output "dlp_policy_id" {
  description = "The unique identifier of the DLP policy for downstream reference"
  value       = powerplatform_data_loss_prevention_policy.this.id
}

output "policy_configuration_summary" {
  description = "Summary of deployed DLP policy configuration for validation"
  value = {
    name                = powerplatform_data_loss_prevention_policy.this.display_name
    environment_type    = var.dlp_policy_config.environment_type
    connector_count     = length(powerplatform_data_loss_prevention_policy.this.connectors)
    deployment_status   = "deployed"
    last_modified       = timestamp()
  }
}

# ❌ Bad: Exposing entire resource object
output "dlp_policy" {
  value = powerplatform_data_loss_prevention_policy.this  # Security/schema concerns
}
```

**AI Agent Required Summary Outputs (All Modules):**
- **Utility modules**: Processing summary with record counts and validation status
- **Resource modules**: Configuration summary with deployment status and key settings
- **Pattern modules**: Orchestration summary with component status and dependencies

## 🎯 Required Implementation Patterns

### Lifecycle Protection (res-* modules only)

**AI Agent: Include this lifecycle block in all res-* modules:**

```hcl
resource "powerplatform_data_loss_prevention_policy" "this" {
  display_name = var.dlp_policy_config.display_name
  # ... other arguments ...

  lifecycle {
    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []
  }
}
```

### Avoiding Count Dependency Issues

**AI Agent: Use lifecycle preconditions instead of count with unknown values:**

```hcl
# ❌ PROBLEMATIC: Count with unknown values during planning
resource "null_resource" "validation" {
  count = var.dataverse_config != null ? 1 : 0
  # ... validation logic
}

resource "powerplatform_environment" "this" {
  count = null_resource.validation[0] != null ? 1 : 0
  # ... resource configuration
}

# ✅ SOLUTION: Use lifecycle precondition for validation
resource "powerplatform_environment" "this" {
  display_name         = var.environment_config.display_name
  location            = var.environment_config.location
  environment_type    = var.environment_config.environment_type
  
  lifecycle {
    precondition {
      condition     = var.dataverse_config != null
      error_message = "Dataverse configuration is required for environment group assignment"
    }
  }
}
```

### Pattern Module Orchestration (ptn-* modules)

**AI Agent: MANDATORY - Pattern modules must use this exact orchestration pattern:**

```hcl
# Variable transformation layer
locals {
  transformed_environments = {
    for idx, env in var.environments : "env-${idx}" => {
      environment = {
        display_name         = env.display_name
        location            = env.location
        environment_type    = env.environment_type
        environment_group_id = module.environment_group.environment_group_id
      }
      dataverse = {
        language_code = local.language_codes[env.dataverse_language]
        currency_code = env.dataverse_currency
      }
    }
  }
}

# Module orchestration with explicit dependencies
module "environment_group" {
  source = "../res-environment-group"
  environment_group_config = var.environment_group_config
}

module "environments" {
  source   = "../res-environment"
  for_each = local.transformed_environments
  
  environment_config = each.value.environment
  dataverse_config   = each.value.dataverse
  
  depends_on = [module.environment_group]
}
```

### Test Coverage Requirements

**AI Agent: Implement these exact test patterns by module type:**

```hcl
# Consolidated test pattern (performance optimized)
run "comprehensive_validation" {
  command = plan
  
  # Input validation (5+ assertions)
  assert {
    condition     = var.policy_name != ""
    error_message = "Policy name must not be empty"
  }
  
  # Output validation (5+ assertions)
  assert {
    condition     = can(output.policy_configuration_summary)
    error_message = "Summary output must be available"
  }
  
  # Resource validation (5+ assertions for res-* modules)
  assert {
    condition     = powerplatform_data_loss_prevention_policy.this.display_name == var.policy_name
    error_message = "Resource configuration must match input variables"
  }
  
  # ... additional assertions to meet minimum requirements ...
}
```

## 🧪 Testing and Quality Assurance

### Performance-Optimized Testing

**AI Agent: Consolidate assertions to minimize expensive operations:**

```hcl
# ✅ Good: Consolidated assertions in single run block
run "comprehensive_validation" {
  command = plan
  
  assert {
    condition     = can(data.powerplatform_connectors.all)
    error_message = "Should be able to query Power Platform connectors"
  }
  
  assert {
    condition     = length(output.connector_summary.business_connectors) > 0
    error_message = "Should identify at least one business connector"
  }
  
  # ... 13+ more assertions ...
}

# ❌ Bad: Each assertion in separate run block (slow)
run "test_1" { command = plan; assert { ... } }
run "test_2" { command = plan; assert { ... } }
```

### Test Phase Separation (CRITICAL for pattern modules)

**AI Agent: MANDATORY - Separate static validation from runtime validation:**

```hcl
# ✅ REQUIRED: Plan phase - static validation only
run "plan_validation" {
  command = plan
  
  # File-based validation (always available)
  assert {
    condition     = length(regexall("module\\s+\"environment_group\"", file("${path.module}/main.tf"))) > 0
    error_message = "Pattern must orchestrate environment_group module"
  }
  
  # Variable structure validation (always available)
  assert {
    condition     = can(var.environment_group_config.display_name)
    error_message = "Environment group config must have display_name property"
  }
}

# ✅ REQUIRED: Apply phase - runtime validation only
run "apply_validation" {
  command = apply
  
  # Module orchestration validation (only available after apply)
  assert {
    condition     = can(module.environment_group)
    error_message = "Environment group module must be deployed and accessible"
  }
  
  # Output validation (only available after apply)
  assert {
    condition     = module.environment_group.environment_group_id != null
    error_message = "Environment group must be created successfully"
  }
}
```

## 🔒 Security and State Management

### Security by Design

**AI Agent: Apply these security patterns to all Terraform code:**

- **OIDC authentication** for all provider connections (Azure AD app registration)
- **Secure state backends** with encryption at rest
- **Input validation** for all user-provided values
- **Least privilege access** for service principals
- **No hardcoded secrets** in any configuration files

### State Management Best Practices

**AI Agent: Use this exact backend configuration:**

```hcl
terraform {
  backend "azurerm" {
    # Configuration provided via environment variables or CLI
    use_oidc                = true
    resource_group_name     = "terraform-state-rg"
    storage_account_name    = "tfstate{unique_suffix}"
    container_name          = "terraform-state"
    key                     = "powerplatform/governance/{module_name}.tfstate"
  }
}
```

## 📊 AI Agent Decision Trees

### Module Creation Decision Tree

**AI Agent: Follow this decision tree when creating modules:**

```yaml
What type of module should I create?
├─ Does it deploy resources?
│  ├─ Single resource type?
│  │  └─ Create res-* module (child module pattern)
│  └─ Multiple resource types?
│     └─ Create ptn-* module (orchestration pattern)
└─ Does it only query/transform data?
   └─ Create utl-* module (utility pattern)

For res-* modules:
├─ Remove all provider/backend blocks
├─ Keep versions.tf under 20 lines
├─ Add lifecycle blocks
└─ Include 20+ test assertions

For ptn-* modules:
├─ Use module blocks only (no resources)
├─ Transform variables in locals
├─ Add explicit depends_on
└─ Include 25+ test assertions

For utl-* modules:
├─ Use data sources only
├─ Process and transform data
├─ Output summary information
└─ Include 15+ test assertions
```

### Validation Decision Tree

**AI Agent: Apply this validation sequence:**

```yaml
Validation Sequence:
├─ Run terraform fmt
│  ├─ Changes needed? → Apply and continue
│  └─ No changes? → Continue
├─ Run terraform validate
│  ├─ Errors? → Fix and restart
│  └─ Success? → Continue
├─ Run terraform test
│  ├─ Failures? → Fix assertions
│  └─ Success? → Continue
├─ Check module requirements
│  ├─ Correct file structure?
│  ├─ Validation blocks present?
│  ├─ Summary outputs included?
│  └─ Test coverage sufficient?
└─ Ready for commit
```

## 🚫 Common Anti-Patterns to Avoid

**AI Agent: NEVER generate code with these patterns:**

### Pattern Module Anti-Patterns
- ❌ Direct resource creation in ptn-* modules
- ❌ Missing variable transformation layer
- ❌ No explicit dependencies between modules
- ❌ Evaluating module outputs in plan phase tests

### Child Module Anti-Patterns
- ❌ Provider blocks in res-* module versions.tf
- ❌ Backend blocks in res-* module versions.tf
- ❌ versions.tf exceeding 20 lines
- ❌ Missing provider blocks in test files
- ❌ Using count with unknown values

### General Anti-Patterns
- ❌ Variables with `type = any`
- ❌ Missing validation blocks
- ❌ Exposing full resource objects in outputs
- ❌ Single-line descriptions
- ❌ Generic error messages
- ❌ Unconsolidated test assertions

## 📋 Quick Reference Checklists

### Pre-Development Checklist (AI Agent: Complete before starting)
- [ ] Module type classified (utl-, res-, ptn-)
- [ ] Directory structure created with all files
- [ ] Provider version set to ~> 3.8
- [ ] Documentation configuration added

### Variable Checklist (AI Agent: Apply to every variable)
- [ ] Explicit object type (no `any`)
- [ ] HEREDOC description with properties
- [ ] Example provided
- [ ] Validation blocks with actionable errors
- [ ] Sensitive flag for credentials

### Output Checklist (AI Agent: Apply to every output)
- [ ] Discrete values (no full resources)
- [ ] Comprehensive description
- [ ] Summary output included
- [ ] Anti-corruption pattern used

### Test Checklist (AI Agent: Verify coverage)
- [ ] utl-*: 15+ assertions (plan only)
- [ ] res-*: 20+ assertions (plan + apply)
- [ ] ptn-*: 25+ assertions (plan + apply)
- [ ] Consolidated assertion blocks
- [ ] Phase separation for patterns

### Child Module Checklist (AI Agent: res-* modules only)
- [ ] No provider blocks in versions.tf
- [ ] No backend blocks in versions.tf
- [ ] versions.tf under 20 lines
- [ ] Provider block in test files
- [ ] Lifecycle blocks included
- [ ] Meta-argument compatible

### Pattern Module Checklist (AI Agent: ptn-* modules only)
- [ ] No resource blocks (only modules)
- [ ] Variable transformation in locals
- [ ] Explicit depends_on used
- [ ] Test phases separated
- [ ] Module outputs aggregated

---

## 🤖 AI Agent Response Structure

### When Creating Terraform Modules

**AI Agent: Structure your response as follows:**

1. **Module Classification**: State module type (utl-, res-, ptn-) and rationale
2. **File Structure**: List all files to be created with their purposes
3. **Implementation Strategy**: Explain approach and AVM alignment
4. **Code Blocks**: Provide complete, working Terraform code
5. **Test Coverage**: Include comprehensive test file
6. **Usage Example**: Show how to use the module
7. **Validation Steps**: List commands to verify correctness

### When Debugging Terraform Issues

**AI Agent: Follow this structure:**

1. **Error Analysis**: Quote exact error and identify root cause
2. **Pattern Recognition**: Identify if it's a known anti-pattern
3. **Solution**: Provide corrected code with explanation
4. **Prevention**: Explain how to avoid similar issues
5. **Verification**: List steps to confirm fix works

---

**AI Agent Final Directive**: This document defines the quality bar for all Terraform code generation. Always prioritize AVM compliance, security by design, and demonstration quality. When conflicts arise, consult the baseline principles and maintain the educational mission of PPCC25.