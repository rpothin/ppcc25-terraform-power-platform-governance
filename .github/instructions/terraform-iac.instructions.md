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

**MANDATORY: Complete this checklist before writing any Terraform code**

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

**AVM principles serve as the northstar for all Terraform code:**
- Implement AVM-inspired patterns even with Power Platform provider limitations
- Follow AVM specification TFNFR27: Provider configurations should be passed from parent modules
- Follow AVM specification PMNFR2: Pattern modules should be built from resource modules
- Document all AVM compliance exceptions with clear justification
- Maintain AVM quality standards for testing, documentation, and governance
- Plan for future transition to full AVM compliance when technically feasible

### ⚠️ Critical Anti-Pattern Warning
**NEVER allow pattern modules to directly create resources** - this violates AVM principles and creates maintenance debt:

```hcl
# ❌ FORBIDDEN: Direct resource creation in pattern modules
resource "powerplatform_environment_group" "this" { ... }
resource "powerplatform_environment" "environments" { ... }

# ✅ REQUIRED: Module orchestration in pattern modules
module "environment_group" { source = "../res-environment-group" }
module "environments" { source = "../res-environment" }
```

### Module Classifications
- **Resource Modules (`res-*`)**: Deploy primary Power Platform resources (DLP policies, environments) - MUST be child modules
- **Pattern Modules (`ptn-*`)**: Orchestrate multiple resource modules using composable patterns - MUST NOT create resources directly
- **Utility Modules (`utl-*`)**: Provide reusable data sources without deploying resources (connector exports)

## 🏗️ Basic Terraform Standards

### Code Structure and Formatting
- Use consistent formatting with `terraform fmt` for all configuration files
- Separate concerns using multiple .tf files (main.tf, variables.tf, outputs.tf, versions.tf)
- Keep individual files under 200 lines when possible (baseline principle: modularity)
- Group related resources logically within files
- Use meaningful comments that explain "why" decisions were made (baseline principle: clear comments)

### Mandatory Validation (Gate Requirement)
**All Terraform code must pass these validations before any commit or pull request:**

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

**CRITICAL UNDERSTANDING: The restriction "Child modules with provider/backend blocks cannot be used with meta-arguments" is not a bug or AVM-specific limitation—it is fundamental Terraform behavior by design.**

**Technical Background:**
When a child module contains its own `provider` or `backend` blocks, Terraform restricts the use of meta-arguments (`count`, `for_each`, `depends_on`) on that module. This limitation exists because:

1. **Provider Configuration Conflicts**: Child modules with their own provider configurations create ambiguity about which provider configuration should be used
2. **Module Instantiation Issues**: Meta-arguments like `count` and `for_each` require precise control over provider configurations, which conflicts with modules that define their own providers  
3. **Legacy Compatibility**: This restriction maintains backward compatibility while encouraging modern best practices

**AVM Specification Alignment:**
This Terraform limitation aligns perfectly with Azure Verified Module specifications:
- **TFNFR27**: Provider blocks **must not** be declared in module code except when different instances of the same provider are needed
- **PMNFR2**: Pattern modules should be built from resource modules (requiring proper module composition)
- **Best Practice**: Provider configurations should be passed in by module users, with only `alias` used in provider blocks within modules

**Why This Approach Is Correct:**
- **Modularity**: Each resource module focuses on a specific resource type without provider coupling
- **Reusability**: Resource modules can be used across different pattern modules with different provider configurations
- **Maintainability**: Provider configurations are centralized in the root module
- **Composability**: Pattern modules can easily combine multiple resource modules
- **Compliance**: Follows both Terraform best practices and AVM specifications

**Reference Documentation:**
- [Terraform Provider Configuration](https://developer.hashicorp.com/terraform/language/providers/configuration)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [Terraform Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)

### Child Module Requirements (res-* modules)
**CRITICAL: All `res-*` modules MUST be designed as child modules for orchestration compatibility**

**Why This Is Required:**
When child modules contain their own `provider` or `backend` blocks, Terraform restricts the use of meta-arguments (`count`, `for_each`, `depends_on`) on those modules. This is a fundamental Terraform limitation that applies to all modules, not just AVM modules. The error "Child modules with provider/backend blocks cannot be used with meta-arguments" is expected behavior that:
- **Prevents Provider Configuration Conflicts**: Child modules with their own providers create ambiguity about which provider should be used
- **Ensures Module Instantiation Consistency**: Meta-arguments require precise control over provider configurations
- **Maintains Legacy Compatibility**: This restriction encourages modern best practices

**AVM Specification Alignment:**
This approach aligns with AVM specification [TFNFR27](https://azure.github.io/Azure-Verified-Modules/specs/tf/) which requires that provider blocks **must not** be declared in module code except when different instances of the same provider are needed.

#### versions.tf Format (MANDATORY)
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
```hcl
# MUST include provider block in test files
provider "powerplatform" {
  use_oidc = true
}
```

## 🔌 Power Platform Specifics

### Provider Configuration (Centralized Standard)
**All modules must use the same provider version for consistency:**

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
- **OIDC authentication** for all Azure and Power Platform connections (no client secrets)
- **Azure Storage backend** with OIDC for state management
- **Never hardcode** sensitive values in configuration files (baseline: security by design)
- **Use Azure Key Vault** or environment variables for secrets
- **Apply principle of least privilege** for all permissions

### Resource Naming and Tagging
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
**All variables must use explicit typing and comprehensive validation:**

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

**Forbidden Practices:**
- ❌ `type = any` (use explicit object types)
- ❌ Variables without validation rules
- ❌ Single-line descriptions (use HEREDOC format)
- ❌ Generic error messages without actionable guidance

### Enhanced Validation Patterns
**All validation blocks must include actionable error messages:**

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
**Implement discrete outputs instead of exposing full resource objects:**

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

**Required Summary Outputs (All Modules):**
- **Utility modules**: Processing summary with record counts and validation status
- **Resource modules**: Configuration summary with deployment status and key settings
- **Pattern modules**: Orchestration summary with component status and dependencies

*Why anti-corruption layer: Protects downstream consumers from provider schema changes and prevents accidental exposure of sensitive attributes.*

## 🎯 Required Implementation Patterns

### Lifecycle Protection (res-* modules only)
**All `res-*` modules must include lifecycle protection:**

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

*Why lifecycle blocks: Manual changes in Power Platform admin center should not cause Terraform drift.*

**Documentation requirement:** Include lifecycle behavior explanation in module README.

### Avoiding Count Dependency Issues
**CRITICAL: Use lifecycle preconditions instead of count with unknown values**

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

*Why preconditions: They validate requirements without creating dependency issues with unknown values during planning.*

### Anti-Corruption Output Pattern (All modules)
```hcl
# ✅ Correct: Discrete, useful outputs with summary pattern
output "policy_configuration_summary" {
  description = "Summary of deployed configuration for validation and downstream reference"
  value = {
    name             = resource.main.display_name
    environment_type = var.config.environment_type
    connector_count  = length(resource.main.connectors)
    deployment_date  = timestamp()
    module_version   = local.module_version
  }
}

# ❌ Incorrect: Full resource exposure
output "policy" {
  value = powerplatform_data_loss_prevention_policy.this
}
```

### File Organization Enhancement
**When main.tf approaches 150+ lines, extract complex logic:**

```hcl
# locals.tf - Complex transformation and processing logic
locals {
  # Complex connector processing
  business_connectors = [
    for connector in var.connectors : connector
    if connector.classification == "Business"
  ]
  
  # Policy validation logic
  policy_valid = length(local.business_connectors) > 0 && length(var.policy_name) <= 50
  
  # Summary generation
  deployment_summary = {
    policy_name      = var.policy_name
    connector_count  = length(local.business_connectors)
    validation_state = local.policy_valid ? "valid" : "invalid"
  }
}
```

### Pattern Module Orchestration (ptn-* modules)
**MANDATORY: Pattern modules must orchestrate resource modules, never create resources directly**

#### Required Implementation Pattern
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

#### Orchestration Requirements
- **Variable Transformation**: Use locals to bridge interfaces between pattern and resource modules
- **Explicit Dependencies**: Use `depends_on` to ensure correct resource creation order
- **Meta-Arguments**: Leverage `for_each` for multiple resource deployment
- **Output Aggregation**: Collect and transform outputs from child modules

### Test Coverage Requirements
**Minimum test patterns by module type:**

- **All modules**: Basic structure, input validation, output presence
- **utl-* modules**: Data transformation accuracy, error handling, performance validation
- **res-* modules**: Resource planning, lifecycle behavior validation, state management
- **ptn-* modules**: Multi-resource orchestration, dependency validation, rollback scenarios, module compatibility

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

## 🛡️ Advanced Requirements (AVM Compliance)

### Strong Variable Validation (All Modules)
**Every object variable must include property-level validation:**

- **Explicit object types** for all complex variables (no `any` type)
- **Validation blocks** for each object property
- **HEREDOC descriptions** with properties, examples, and validation reasoning
- **Clear error messages** that guide users toward correct values with specific guidance

### Testing Coverage Requirements
**Minimum test assertions by module type:**

| Module Type | Minimum Assertions | Required Test Types     | Focus Areas                                      |
| ----------- | ------------------ | ----------------------- | ------------------------------------------------ |
| `utl-*`     | 15+                | `plan` only             | Data transformation, error handling, performance |
| `res-*`     | 20+                | Both `plan` and `apply` | Resource planning, lifecycle, state management   |
| `ptn-*`     | 25+                | Both `plan` and `apply` | Orchestration, dependencies, rollback scenarios  |

```hcl
# res-* modules must test both planning and deployment
run "plan_validation" {
  command = plan
  # ... at least 10 assertions for structure and logic ...
}

run "apply_validation" {
  command = apply
  # ... at least 10 assertions for actual deployment ...
}
```

*Why these numbers: Based on AVM standards and complexity analysis of Power Platform resources. Plan/apply separation ensures both design-time and runtime validation.*

## 🧪 Testing and Quality Assurance

### Performance-Optimized Testing
**Consolidate assertions to minimize expensive plan/apply operations:**

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
**MANDATORY: Separate static validation from runtime validation to avoid unknown value errors**

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

**Why separation is critical:**
- **Plan phase**: Can only validate static configuration, file structure, and variable types
- **Apply phase**: Can validate module outputs, computed values, and actual resource creation
- **Unknown values**: Module outputs and computed locals are unknown during plan phase

### Missing Outputs Prevention
**All modules must include these standard outputs to prevent test failures:**

```hcl
# Required for all utility modules
output "processing_summary" {
  description = "Summary of data processing operations and results"
  value = {
    records_processed = local.total_records
    validation_status = local.validation_passed
    processing_time   = timestamp()
  }
}

# Required for all resource modules  
output "deployment_summary" {
  description = "Summary of resource deployment status and configuration"
  value = {
    resource_id       = try(resource.main.id, null)
    deployment_status = "completed"
    configuration     = local.resource_config_summary
  }
}
```

### Documentation Standards
**Auto-generate documentation using terraform-docs:**
- Include `.terraform-docs.yml` configuration
- Provide usage examples in module README
- Document troubleshooting guidance for common Power Platform issues
- Reference official Microsoft documentation
- Include performance considerations for large datasets

### Validation Workflows
- Include automated format/syntax checking in CI/CD
- Validate both successful deployments and error conditions
- Test against multiple Power Platform environments when possible
- Follow semantic versioning (SemVer) for module releases

## 🔒 Security and State Management

### Security by Design
**Power Platform governance requires enhanced security:**
- **OIDC authentication** for all provider connections (Azure AD app registration)
- **Secure state backends** with encryption at rest
- **Input validation** for all user-provided values
- **Least privilege access** for service principals
- **No hardcoded secrets** in any configuration files

### State Management Best Practices
**Use Azure Storage backend with proper security:**

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

**State Security Requirements:**
- Never commit state files to version control
- Use OIDC authentication (avoid access keys)
- Implement proper state locking mechanisms
- Document state recovery procedures
- Follow organizational naming conventions for state files

---

## � Lessons Learned from Migration Experience

### Critical Migration Insights
**Based on the successful transformation from anti-pattern direct resource creation to AVM-compliant child module orchestration:**

#### 1. Anti-Pattern Recognition
- **Warning Signs**: Pattern modules creating resources directly instead of orchestrating child modules
- **Impact**: Code duplication, maintenance complexity, violation of AVM principles
- **Detection**: Look for `resource` blocks in `ptn-*` modules - should only contain `module` blocks

#### 2. Child Module Compatibility Requirements
- **Root Cause**: Provider and backend blocks in child modules prevent meta-argument usage (fundamental Terraform limitation)
- **Technical Reason**: Meta-arguments require precise control over provider configurations, which conflicts with modules that define their own providers
- **AVM Alignment**: This aligns with AVM specification TFNFR27 requiring provider configurations to be passed from parent modules
- **Solution**: Remove all provider/backend blocks from `res-*` modules
- **Validation**: Child modules must work with `for_each`, `count`, and `depends_on`
- **Expected Behavior**: The error "Child modules with provider/backend blocks cannot be used with meta-arguments" is standard Terraform behavior, not a bug

#### 3. Test Phase Separation Critical Success Factor
- **Problem**: "Unknown condition value" errors when evaluating runtime values during plan phase
- **Solution**: Strict separation between static validation (plan) and runtime validation (apply)
- **Implementation**: File-based assertions in plan, module output assertions in apply

#### 4. Variable Transformation Patterns
- **Need**: Bridge interface differences between pattern and resource modules
- **Pattern**: Use `locals` for complex transformations (e.g., language code mapping)
- **Benefits**: Clean interfaces, maintainable code, clear data flow

#### 5. Integration Test Infrastructure Requirements
- **Child Module Testing**: Must include provider blocks in test files
- **Performance**: Consolidate assertions to minimize expensive plan/apply cycles
- **Coverage**: 25+ assertions for patterns, 20+ for resources, proper phase distribution

### Migration Checklist for Future Implementations
**Use this checklist when implementing new modules or refactoring existing ones:**

#### Pattern Module Migration (ptn-*)
- [ ] Replace all `resource` blocks with `module` blocks
- [ ] Implement variable transformation in `locals`
- [ ] Add explicit `depends_on` between modules
- [ ] Update outputs to reference module outputs
- [ ] Separate test phases (plan vs apply validation)

#### Child Module Preparation (res-*)
- [ ] Remove provider blocks from versions.tf
- [ ] Remove backend blocks from versions.tf
- [ ] Minimize versions.tf to under 20 lines
- [ ] Add provider blocks to test files
- [ ] Replace count-based validation with lifecycle preconditions
- [ ] Verify compatibility with meta-arguments

#### Common Pitfalls to Avoid
- ❌ **Never** mix resource creation and module orchestration in same module (violates AVM PMNFR2)
- ❌ **Never** use count with unknown values from other resources (causes planning errors)
- ❌ **Never** put provider/backend blocks in child modules (breaks meta-argument compatibility - violates AVM TFNFR27)
- ❌ **Never** evaluate module outputs in plan phase tests (unknown values cause test failures)
- ❌ **Never** skip explicit dependencies between modules (can cause race conditions)
- ❌ **Never** expect different behavior from "Child modules with provider/backend blocks cannot be used with meta-arguments" error (this is expected Terraform behavior)

---

## �📋 Quick Reference

### Pre-Development Checklist (Essential)
- [ ] Module type classified and directory structure created
- [ ] All required files present (main.tf, variables.tf, outputs.tf, versions.tf, tests/)
- [ ] Variables use explicit types with validation and HEREDOC descriptions
- [ ] Outputs implement anti-corruption layer with summary patterns
- [ ] Tests meet minimum assertion requirements for module type

### Module Checklist (Validation Gates)
- [ ] Uses provider version `~> 3.8`
- [ ] All variables have explicit types and validation with actionable error messages
- [ ] Outputs use anti-corruption layer pattern with required summary outputs
- [ ] `res-*` modules include lifecycle blocks
- [ ] Tests meet minimum assertion requirements with consolidated run blocks
- [ ] Documentation auto-generated with terraform-docs
- [ ] Passes `terraform fmt -check` and `terraform validate`
- [ ] Complex logic extracted to locals.tf when main.tf > 150 lines

### Child Module Specific Validation (res-* modules)
- [ ] **No provider blocks** in versions.tf (child module compatibility)
- [ ] **No backend blocks** in versions.tf (child module compatibility)
- [ ] **versions.tf under 20 lines** (AVM child module standard)
- [ ] **Provider block in test files** for integration test compatibility
- [ ] **Compatible with for_each and depends_on** (verified in pattern module tests)
- [ ] **Uses lifecycle preconditions** instead of count for validation

### Pattern Module Specific Validation (ptn-* modules)
- [ ] **No direct resource creation** (only module orchestration)
- [ ] **Variable transformation layer** implemented in locals
- [ ] **Explicit dependencies** using depends_on between modules
- [ ] **Test phase separation** (plan for static, apply for runtime validation)
- [ ] **Meta-arguments compatibility** verified with child modules

### Common Patterns
- **DLP Policy**: Use `res-dlp-policy` pattern with connector classification
- **Environment Export**: Use `utl-export-environments` for data collection
- **Governance Suite**: Use `ptn-governance-suite` for multiple resource deployment

### Quality Gates Summary
1. **Format & Syntax**: Must pass `terraform fmt -check` and `terraform validate`
2. **Testing**: Must meet minimum assertion requirements with all tests passing
3. **Security**: Must use OIDC authentication and no hardcoded secrets
4. **Documentation**: Must include comprehensive variable descriptions and output summaries
5. **File Organization**: Must follow AVM-inspired structure with appropriate file separation
6. **Child Module Compliance**: `res-*` modules must be compatible with meta-arguments (no provider/backend blocks)
7. **Pattern Module Orchestration**: `ptn-*` modules must orchestrate only, never create resources directly
8. **Test Phase Separation**: Pattern modules must separate static (plan) from runtime (apply) validation

### Anti-Pattern Detection Gates
**Automated checks to prevent architectural violations:**
- **Pattern Module Resource Check**: Fail if `ptn-*` modules contain `resource` blocks
- **Child Module Provider Check**: Fail if `res-*` modules contain `provider` or `backend` blocks
- **Test Phase Validation**: Fail if plan phase tests evaluate module outputs or computed values
- **Meta-Argument Compatibility**: Fail if child modules cannot be used with `for_each` or `depends_on`

*Remember: These guidelines support the PPCC25 demonstration goals of showing effective Power Platform governance through Infrastructure as Code while maintaining alignment with baseline principles of security, simplicity, and modularity.*