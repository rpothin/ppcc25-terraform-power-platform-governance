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
- [ ] **main.tf** - Primary resource definitions
- [ ] **variables.tf** - Input parameters (all with validation blocks)
- [ ] **outputs.tf** - Anti-corruption layer outputs only
- [ ] **versions.tf** - Provider and version constraints
- [ ] **tests/integration.tftest.hcl** - Test assertions (minimum per module type)

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
- [ ] **utl-* modules**: Minimum 15 test assertions
- [ ] **res-* modules**: Minimum 20 test assertions + lifecycle blocks
- [ ] **ptn-* modules**: Minimum 25 test assertions
- [ ] All tests use consolidated assertion blocks (performance optimization)

## 📚 Azure Verified Modules (AVM) Foundation

**AVM principles serve as the northstar for all Terraform code:**
- Implement AVM-inspired patterns even with Power Platform provider limitations
- Document all AVM compliance exceptions with clear justification
- Maintain AVM quality standards for testing, documentation, and governance
- Plan for future transition to full AVM compliance when technically feasible

### Module Classifications
- **Resource Modules (`res-*`)**: Deploy primary Power Platform resources (DLP policies, environments)
- **Pattern Modules (`ptn-*`)**: Deploy multiple resources using composable patterns (governance suites)
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
   ignore_changes  = [display_name, tags]    # Allow manual changes without drift
  }
}
```

*Why lifecycle blocks: Manual changes in Power Platform admin center should not cause Terraform drift.*

**Documentation requirement:** Include lifecycle behavior explanation in module README.

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

### Test Coverage Requirements
**Minimum test patterns by module type:**

- **All modules**: Basic structure, input validation, output presence
- **utl-* modules**: Data transformation accuracy, error handling, performance validation
- **res-* modules**: Resource planning, lifecycle behavior validation, state management
- **ptn-* modules**: Multi-resource orchestration, dependency validation, rollback scenarios

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

## 📋 Quick Reference

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

*Remember: These guidelines support the PPCC25 demonstration goals of showing effective Power Platform governance through Infrastructure as Code while maintaining alignment with baseline principles of security, simplicity, and modularity.*