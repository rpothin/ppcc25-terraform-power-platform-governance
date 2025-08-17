# Power Platform Governance: Migrating res-* Configurations to AVM-Compliant Child Modules

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

---

## Overview

This page documents the architectural transformation journey for the Power Platform governance demonstration, focusing on the migration of `res-*` configurations into proper child modules for orchestration by pattern modules (`ptn-*`). It provides context, rationale, technical details, and lessons learned for future maintainers and contributors.

---

## Background & Initial Issue

### Problem Statement
- **Anti-pattern Detected:** The original `ptn-environment-group` module directly created resources, bypassing the abstraction and reusability provided by `res-*` modules.
- **AVM Violation:** This approach conflicted with Azure Verified Module (AVM) principles and the repository's baseline modularity guidelines.
- **Risks:** Code duplication, maintenance complexity, and inability to scale or reuse resource logic.

### Example of Anti-Pattern
```hcl
# Direct resource creation (not recommended)
resource "powerplatform_environment_group" "this" { ... }
resource "powerplatform_environment" "environments" { ... }
```

---

## Migration Goals

- **Enforce AVM Principles:** Ensure all resource creation is handled by dedicated child modules (`res-*`).
- **Enable Orchestration:** Pattern modules (`ptn-*`) should only orchestrate child modules, not create resources directly.
- **Support Meta-Arguments:** Child modules must be compatible with `for_each`, `count`, and `depends_on`.
- **Centralize Provider Configuration:** Provider blocks should be managed by parent modules, not child modules.
- **Comprehensive Testing:** Integration tests must validate both static configuration and runtime behavior.

---

## Technical Challenges & Solutions

### 1. Child Module Compatibility
- **Issue:** Child modules with provider/backend blocks cannot be used with meta-arguments.
- **Solution:** Remove provider/backend blocks from all `res-*` modules. Minimize `versions.tf` to essential configuration only.

#### Before
```hcl
# Incompatible child module
terraform {
  required_providers { ... }
  backend "azurerm" { ... }
}
provider "powerplatform" { ... }
```

#### After
```hcl
# AVM-compliant child module
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
```

### 2. Module Orchestration Refactoring
- **Action:** Replace direct resource creation in `ptn-environment-group` with module calls to `res-environment-group` and `res-environment`.
- **Variable Transformation:** Use locals to map and transform variables between pattern and resource modules.
- **Dependency Management:** Use `depends_on` to ensure correct resource creation order.

#### Example
```hcl
module "environment_group" {
  source = "../res-environment-group"
  environment_group_config = var.environment_group_config
}

module "environments" {
  source   = "../res-environment"
  for_each = local.transformed_environments
  environment_config = each.value.environment
  dataverse_config   = each.value.dataverse
  depends_on         = [module.environment_group]
}
```

### 3. Integration Test Overhaul
- **Provider Configuration:** Add provider blocks to test files for child module compatibility.
- **Test Phase Separation:** Split tests into `plan_validation` (static) and `apply_validation` (runtime) to avoid unknown value errors.
- **Assertion Coverage:** Ensure 25+ assertions for pattern modules, 20+ for resource modules.

#### Example
```hcl
run "plan_validation" {
  command = plan
  # Static assertions only
}

run "apply_validation" {
  command = apply
  # Runtime assertions only
}
```

### 4. Count Dependency & Lifecycle Precondition
- **Issue:** Using `count` with unknown values caused planning errors.
- **Solution:** Move validation logic to resource `lifecycle` precondition blocks.

#### Example
```hcl
resource "powerplatform_environment" "this" {
  ...
  lifecycle {
    precondition {
      condition     = var.dataverse_config != null
      error_message = "Dataverse configuration is required."
    }
  }
}
```

---

## Results & Validation

- **AVM Compliance:** All `res-*` modules are now proper child modules, compatible with meta-arguments.
- **Pattern Module Orchestration:** `ptn-environment-group` orchestrates resource modules exclusively.
- **Test Coverage:** Integration tests validate both static and runtime behavior, with proper phase separation.
- **Code Quality:** Reduced duplication, improved maintainability, and future-proofed for scaling and Azure integration.

---

## Lessons Learned & Recommendations

1. **Design for Modularity:** Always use child modules for resource logic; pattern modules should orchestrate only.
2. **Centralize Providers:** Keep provider configuration in parent modules and test files.
3. **Test Phase Separation:** Plan for static vs runtime validation in integration tests.
4. **Minimize Child Module Files:** Keep child module files concise and focused.
5. **Follow AVM Standards:** Align with AVM and repository baseline instructions for long-term maintainability.

---

## References
- [Azure Verified Modules (AVM) Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [PPCC25 Baseline Coding Guidelines](../.github/instructions/baseline.instructions.md)
- [Terraform Child Module Patterns](https://developer.hashicorp.com/terraform/language/modules/develop/structure)

---

*Last updated: August 17, 2025*
