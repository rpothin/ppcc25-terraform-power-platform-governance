# Provider Configuration Architecture: versions.tf vs providers.tf

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

---

## Overview

This document explains the architectural distinction between `versions.tf` and `providers.tf` files in the PPCC25 Power Platform governance repository, clarifying their complementary roles and when each should be used in child modules versus standalone configurations.

---

## The Two-File Pattern

Terraform provider management is split across two files with distinct responsibilities:

### `versions.tf` - Provider Requirements Declaration

**Purpose:** Declares **what** providers are needed and **which versions** are compatible.

**Responsibilities:**
- Minimum Terraform version constraints
- Provider source locations (registry URLs)
- Provider version constraints
- Backend configuration declarations

**Think of it as:** The "shopping list" - what ingredients you need and where to get them.

### `providers.tf` - Provider Configuration & Authentication

**Purpose:** Configures **how** providers authenticate and behave.

**Responsibilities:**
- Authentication methods (OIDC, service principals, etc.)
- Provider-specific features and settings
- Provider aliases for multi-instance scenarios
- Regional or environment-specific configurations

**Think of it as:** The "recipe instructions" - how to prepare and use those ingredients.

---

## Side-by-Side Comparison

### Example: Power Platform Provider

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# versions.tf - PROVIDER REQUIREMENTS
# ═══════════════════════════════════════════════════════════════════════════
# Answers: "What do I need to download?"

terraform {
  required_version = ">= 1.5.0"  # Minimum Terraform CLI version
  
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"  # WHERE: Provider registry location
      version = "~> 3.8"                     # WHICH: Compatible version range
    }
  }
}
```

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# providers.tf - PROVIDER CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
# Answers: "How do I authenticate and use it?"

provider "powerplatform" {
  # HOW: OIDC authentication method
  # WHERE: Environment variables provide credentials
  # WHY: Zero Trust security - no stored secrets
  
  # Authentication happens automatically via environment variables:
  # - POWER_PLATFORM_USE_OIDC=true
  # - POWER_PLATFORM_CLIENT_ID (from GitHub secrets)
  # - POWER_PLATFORM_TENANT_ID (from GitHub secrets)
}
```

---

## The Terraform Execution Flow

Understanding when each file is used helps clarify their roles:

### Phase 1: `terraform init` (uses `versions.tf`)

```bash
$ terraform init

┌─────────────────────────────────────────────────────────────────┐
│ 1. Read versions.tf                                             │
│    ✓ Terraform version: >= 1.5.0 (current: 1.12.2)             │
│                                                                  │
│ 2. Identify required providers                                  │
│    ✓ powerplatform from microsoft/power-platform               │
│    ✓ Version constraint: ~> 3.8 (any 3.8.x)                    │
│                                                                  │
│ 3. Download providers                                           │
│    ✓ Downloading microsoft/power-platform v3.8.2...            │
│    ✓ Installed to .terraform/providers/                        │
│                                                                  │
│ 4. Initialize backend                                           │
│    ✓ Azure Storage backend with OIDC                           │
│    ✓ State key: ptn-azure-vnet-extension.tfstate              │
└─────────────────────────────────────────────────────────────────┘
```

**Result:** Providers downloaded and ready to use, but not yet configured.

### Phase 2: `terraform plan`/`apply` (uses `providers.tf`)

```bash
$ terraform plan

┌─────────────────────────────────────────────────────────────────┐
│ 1. Read providers.tf                                            │
│    ✓ Found provider "powerplatform" configuration              │
│                                                                  │
│ 2. Check environment for OIDC variables                         │
│    ✓ POWER_PLATFORM_USE_OIDC=true                              │
│    ✓ POWER_PLATFORM_CLIENT_ID=12345678-...                     │
│    ✓ POWER_PLATFORM_TENANT_ID=87654321-...                     │
│                                                                  │
│ 3. Authenticate using OIDC                                      │
│    ✓ Exchange GitHub OIDC token for Power Platform token       │
│    ✓ Token valid for: 1 hour                                   │
│                                                                  │
│ 4. Execute Terraform operations                                 │
│    ✓ Read current state from Azure Storage                     │
│    ✓ Query Power Platform API for current resources            │
│    ✓ Calculate infrastructure changes                          │
└─────────────────────────────────────────────────────────────────┘
```

**Result:** Provider authenticated and ready to make API calls.

---

## Child Modules vs Standalone Configurations

This is where the architecture becomes critical for AVM compliance.

### Rule 1: Child Modules - `versions.tf` ONLY

**Child modules** are Terraform modules called by other modules (parent/pattern modules).

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# configurations/res-environment/versions.tf
# ═══════════════════════════════════════════════════════════════════════════
# Child module - declares requirements only

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}

# ✅ NO providers.tf file
# ✅ NO backend block
# WHY: Configuration inherited from parent module
```

**Files in child module:**
```
configurations/res-environment/
├── main.tf          ✅ Resource definitions
├── variables.tf     ✅ Input variables
├── outputs.tf       ✅ Outputs
├── versions.tf      ✅ Provider requirements ONLY
└── providers.tf     ❌ NOT PRESENT (would break for_each/count)
```

**Why no `providers.tf`?**
1. **Provider Inheritance:** Child modules inherit provider configuration from their parent
2. **Meta-Argument Compatibility:** Having `providers.tf` prevents using `for_each`, `count`, `depends_on`
3. **AVM Compliance:** Azure Verified Module specification TFNFR27 requires this pattern
4. **Single Source of Truth:** Parent controls all authentication, preventing conflicts

### Rule 2: Standalone Configurations - Both Files Required

**Standalone configurations** are Terraform root modules deployed directly (not called as child modules).

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# configurations/ptn-environment-group/versions.tf
# ═══════════════════════════════════════════════════════════════════════════
# Standalone/root module - declares requirements

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
  
  backend "azurerm" {
    use_oidc = true
  }
}
```

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# configurations/ptn-environment-group/providers.tf
# ═══════════════════════════════════════════════════════════════════════════
# Standalone/root module - configures authentication

provider "powerplatform" {
  # OIDC authentication via environment variables
  # Set by GitHub Actions workflows
}
```

**Files in standalone configuration:**
```
configurations/ptn-environment-group/
├── main.tf          ✅ Module orchestration
├── variables.tf     ✅ Input variables
├── outputs.tf       ✅ Outputs
├── versions.tf      ✅ Requirements + backend
├── providers.tf     ✅ Authentication config
└── locals.tf        ✅ Data transformations
```

**Why both files?**
1. **Explicit Configuration:** Makes authentication visible for educational purposes
2. **Self-Documenting:** Anyone reading the code understands the security model
3. **OIDC Demonstration:** Shows Zero Trust pattern for PPCC25 presentation
4. **Workflow Integration:** Documents environment variables needed by GitHub Actions

---

## Provider Inheritance in Action

### Example: Pattern Module Calling Child Module

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# Parent: configurations/ptn-environment-group/providers.tf
# ═══════════════════════════════════════════════════════════════════════════

provider "powerplatform" {
  # OIDC authentication configured here
  # This provider instance will be used by ALL child modules
}
```

```terraform
# ═══════════════════════════════════════════════════════════════════════════
# Parent: configurations/ptn-environment-group/main.tf
# ═══════════════════════════════════════════════════════════════════════════

module "environment_group" {
  source = "../res-environment-group"  # ← Uses parent's provider
  
  display_name = var.name
  description  = var.description
}

module "environments" {
  source   = "../res-environment"  # ← Uses parent's provider
  for_each = local.template_environments
  
  environment = each.value.environment
  dataverse   = each.value.dataverse
  
  depends_on = [module.environment_group]  # ← This works because no providers.tf
}
```

**What happens:**
1. Parent's `providers.tf` creates a provider instance with OIDC auth
2. Terraform passes this provider instance to child modules
3. Child modules validate version compatibility via their `versions.tf`
4. All modules use the same authenticated provider instance
5. Meta-arguments (`for_each`, `depends_on`) work correctly

---

## Decision Matrix: Which Files Do I Need?

| Configuration Type | Deploy Method | versions.tf | providers.tf | backend block |
|-------------------|---------------|-------------|--------------|---------------|
| **Pure Child Module** | Called by parent only | ✅ Required | ❌ Never | ❌ Never |
| **Standalone Config** | GitHub Actions workflow | ✅ Required | ✅ Required | ✅ Required |
| **Dual-Purpose Module** | Both ways | ✅ Required | ✅ Required | ✅ In versions.tf |

### PPCC25 Repository Examples

| Configuration | Type | versions.tf | providers.tf | Status |
|---------------|------|-------------|--------------|--------|
| `res-environment` | Pure child | ✅ Yes | ❌ No | ✅ Correct |
| `res-environment-group` | Pure child | ✅ Yes | ❌ No | ✅ Correct |
| `res-environment-settings` | Pure child | ✅ Yes | ❌ No | ✅ Correct |
| `res-dlp-policy` | Standalone | ✅ Yes | ✅ Yes | ✅ Complete |
| `ptn-environment-group` | Standalone | ✅ Yes | ✅ Yes | ✅ Complete |
| `ptn-azure-vnet-extension` | Standalone | ✅ Yes | ✅ Yes | ✅ Complete |

---

## Educational Benefits for PPCC25

Adding `providers.tf` to standalone configurations provides significant educational value:

### 1. **Explicit OIDC Pattern**
```terraform
provider "powerplatform" {
  # OIDC authentication via environment variables:
  # - POWER_PLATFORM_USE_OIDC=true      ← Enables OIDC
  # - POWER_PLATFORM_CLIENT_ID          ← Azure AD app ID
  # - POWER_PLATFORM_TENANT_ID          ← Azure AD tenant ID
}
```

**Without `providers.tf`:** Attendees must infer authentication from workflow files.
**With `providers.tf`:** Authentication method immediately visible in Terraform code.

### 2. **Zero Trust Demonstration**
```terraform
provider "powerplatform" {
  # WHY: No explicit configuration here - OIDC uses environment variables
  # This is the Zero Trust pattern: no secrets in code, only temporary tokens
  
  # Token exchange happens automatically with GitHub Actions
}
```

Shows the transition from ClickOps (stored credentials) to IaC (OIDC tokens).

### 3. **Self-Documenting Infrastructure**
```terraform
# ⚙️ REQUIRED ENVIRONMENT VARIABLES:
# Set by GitHub Actions workflows:
#   - POWER_PLATFORM_USE_OIDC=true
#   - POWER_PLATFORM_CLIENT_ID (from GitHub secrets)
#   - POWER_PLATFORM_TENANT_ID (from GitHub secrets)
```

Attendees can understand requirements without reading workflow documentation.

### 4. **Hybrid Scenarios Clarity**
```terraform
provider "azurerm" {
  features {}
  # OIDC: ARM_USE_OIDC, ARM_CLIENT_ID, ARM_TENANT_ID
}

provider "powerplatform" {
  # OIDC: POWER_PLATFORM_USE_OIDC, POWER_PLATFORM_CLIENT_ID
}
```

Shows how Azure and Power Platform governance work together with dual OIDC.

---

## Common Misconceptions

### ❌ Misconception 1: "Child modules need providers.tf for clarity"

**Reality:** Child modules with `providers.tf` cannot use `for_each`/`count`.

```terraform
# This FAILS:
module "environments" {
  source   = "../res-environment"  # Has providers.tf
  for_each = local.template_environments  # ← ERROR!
  
  # Error: "Module with provider config cannot use for_each"
}
```

**Solution:** Remove `providers.tf` from child modules, inherit from parent.

### ❌ Misconception 2: "versions.tf and providers.tf are interchangeable"

**Reality:** They serve completely different purposes at different execution phases.

- `versions.tf` → Used during `terraform init` (download phase)
- `providers.tf` → Used during `terraform plan/apply` (execution phase)

### ❌ Misconception 3: "Standalone configs work without providers.tf"

**Reality:** They work but authentication is implicit, not explicit.

**Without `providers.tf`:** Works but unclear how authentication happens.
**With `providers.tf`:** Clear, documented, educational.

---

## Best Practices Summary

### For Child Modules (res-*)

✅ **DO:**
- Include minimal `versions.tf` with provider requirements only
- Document that provider is inherited from parent
- Keep modules focused on resource logic

❌ **DON'T:**
- Add `providers.tf` (breaks meta-arguments)
- Add `backend` blocks (breaks module reusability)
- Configure provider authentication

### For Standalone Configurations (ptn-*, deployed configs)

✅ **DO:**
- Include comprehensive `versions.tf` with backend configuration
- Include detailed `providers.tf` with authentication documentation
- Use comments to explain OIDC pattern and required env vars
- Document educational value for presentation

❌ **DON'T:**
- Leave provider configuration implicit
- Skip documentation of environment variables
- Mix backend configuration into `providers.tf`

### For GitHub Workflows

✅ **DO:**
- Set all provider environment variables in workflow files
- Use OIDC for all authentication (Azure + Power Platform)
- Reference the `providers.tf` documentation in workflow comments

❌ **DON'T:**
- Store credentials in secrets (use OIDC instead)
- Hardcode subscription IDs or tenant IDs in workflows
- Skip explaining the OIDC pattern in workflow documentation

---

## Troubleshooting Guide

### Problem: "Module cannot use for_each"

**Symptom:**
```
Error: Module instance count/for_each not allowed

Module "environments" has provider "powerplatform" configured, which is
not compatible with for_each meta-argument.
```

**Cause:** Child module has `providers.tf` file.

**Solution:** Remove `providers.tf` from child module.

### Problem: "Provider not configured"

**Symptom:**
```
Error: Provider configuration not present

Provider "powerplatform" is not configured.
```

**Cause:** Standalone configuration missing `providers.tf`.

**Solution:** Add `providers.tf` to root/standalone configuration.

### Problem: "Authentication failed"

**Symptom:**
```
Error: Failed to authenticate with Power Platform

OIDC authentication failed: missing POWER_PLATFORM_CLIENT_ID
```

**Cause:** Environment variables not set in GitHub Actions workflow.

**Solution:** Verify environment variables in workflow file and GitHub secrets.

---

## References & Further Reading

- [Terraform Provider Configuration](https://developer.hashicorp.com/terraform/language/providers/configuration)
- [Terraform Module Providers](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
- [AVM Specification TFNFR27](https://azure.github.io/Azure-Verified-Modules/specs/tf/#id-tfnfr27---category-composition---cross-referencing-modules)
- [Child Module Migration Guide](./child-module-migration-power-platform-governance.md)
- [PPCC25 Baseline Instructions](../../.github/instructions/baseline.instructions.md)

---

## Conclusion

The separation of concerns between `versions.tf` and `providers.tf` is fundamental to Terraform's architecture:

- **`versions.tf`** declares requirements → enables `terraform init`
- **`providers.tf`** configures authentication → enables `terraform plan/apply`

For the PPCC25 demonstration:
- **Child modules** (`res-*`): Only `versions.tf` for AVM compliance
- **Standalone configs** (deployed): Both files for educational clarity

This architecture enables:
- ✅ Proper module composition with `for_each`/`count`
- ✅ AVM compliance and best practices
- ✅ Educational value for conference presentation
- ✅ Zero Trust security with OIDC authentication
- ✅ Self-documenting infrastructure code

---

*Last updated: September 30, 2025*
