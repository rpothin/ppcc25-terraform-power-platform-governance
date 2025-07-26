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
- Keep individual files under 200 lines when possible
- Group related resources logically within files
- Use meaningful comments that explain "why" decisions were made

### Mandatory Format and Syntax Validation
**All Terraform code must pass validation before completion or merge:**

1. Run `terraform fmt -check` to ensure proper formatting
2. If issues found, run `terraform fmt` to auto-correct
3. Run `terraform validate` to ensure syntax correctness
4. Do not consider code complete until both checks pass

*Why: This process ensures AVM compliance, CI/CD reliability, and consistent code quality.*

### File Organization (AVM-Inspired)
```
configurations/{module-name}/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input parameters with validation
├── outputs.tf          # Discrete outputs (anti-corruption layer)
├── versions.tf         # Provider and version constraints
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
  use_oidc = true  # Enhanced security over client secrets
}
```

*Why `~> 3.8`: This version provides stable Power Platform resource management while allowing patch updates.*

### Authentication and Security
- **OIDC authentication** for all Azure and Power Platform connections (no client secrets)
- **Azure Storage backend** with OIDC for state management
- **Never hardcode** sensitive values in configuration files
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
    error_message = "Display name must be 50 characters or less for Power Platform compatibility."
  }
  
  validation {
    condition     = contains(["Business", "NonBusiness"], var.dlp_policy_config.default_connectors_classification)
    error_message = "Connector classification must be either 'Business' or 'NonBusiness'."
  }
}
```

**Forbidden Practices:**
- ❌ `type = any` (use explicit object types)
- ❌ Variables without validation rules
- ❌ Single-line descriptions (use HEREDOC format)

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
  }
}

# ❌ Bad: Exposing entire resource object
output "dlp_policy" {
  value = powerplatform_data_loss_prevention_policy.this  # Security/schema concerns
}
```

*Why anti-corruption layer: Protects downstream consumers from provider schema changes and prevents accidental exposure of sensitive attributes.*

## 🛡️ Advanced Requirements (AVM Compliance)

### Lifecycle Management (Resource Modules Only)
**All `res-*` modules must include lifecycle protection:**

```hcl
resource "powerplatform_data_loss_prevention_policy" "this" {
  display_name = var.dlp_policy_config.display_name
  # ... other arguments ...

  lifecycle {
    prevent_destroy = true                    # Protect against accidental deletion
    ignore_changes  = [display_name, tags]    # Allow manual changes without drift
  }
}
```

*Why lifecycle blocks: DLP policies are critical governance resources that should not be accidentally destroyed. Manual changes in Power Platform admin center should not cause Terraform drift.*

**Documentation requirement:** Include lifecycle behavior explanation in module README.

### Strong Variable Validation (All Modules)
**Every object variable must include property-level validation:**

- **Explicit object types** for all complex variables (no `any` type)
- **Validation blocks** for each object property
- **HEREDOC descriptions** with properties, examples, and validation reasoning
- **Clear error messages** that guide users toward correct values

### Testing Coverage Requirements
**Minimum test assertions by module type:**

| Module Type | Minimum Assertions | Required Test Types |
|-------------|-------------------|-------------------|
| `utl-*` | 15+ | `plan` only |
| `res-*` | 20+ | Both `plan` and `apply` |
| `ptn-*` | 25+ | Both `plan` and `apply` |

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

### Documentation Standards
**Auto-generate documentation using terraform-docs:**
- Include `.terraform-docs.yml` configuration
- Provide usage examples in module README
- Document troubleshooting guidance for common Power Platform issues
- Reference official Microsoft documentation

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

### Module Checklist
- [ ] Uses provider version `~> 3.8`
- [ ] All variables have explicit types and validation
- [ ] Outputs use anti-corruption layer pattern
- [ ] `res-*` modules include lifecycle blocks
- [ ] Tests meet minimum assertion requirements
- [ ] Documentation auto-generated with terraform-docs
- [ ] Passes `terraform fmt -check` and `terraform validate`

### Common Patterns
- **DLP Policy**: Use `res-dlp-policy` pattern with connector classification
- **Environment Export**: Use `utl-export-environments` for data collection
- **Governance Suite**: Use `ptn-governance-suite` for multiple resource deployment

*Remember: These guidelines support the PPCC25 demonstration goals of showing effective Power Platform governance through Infrastructure as Code.*