# Architecture Decisions

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

**Purpose**: Understanding key architectural decisions and their rationale  
**Audience**: Developers and architects implementing or adapting this solution  
**Format**: Decision records with context, reasoning, and implications

---

## Overview

This document explains the major architectural decisions made in the PPCC25 Power Platform governance demonstration. Each decision is presented with its context, the problem it solves, the chosen solution, alternatives considered, and implications for implementation.

---

## Decision 1: Child Module Pattern for Resource Management

### Context

When designing the infrastructure code structure, we faced a choice: should pattern modules (ptn-*) directly create resources, or should they orchestrate separate resource modules (res-*)?

### Problem

**Direct Resource Creation (Anti-Pattern)**:
```hcl
# Pattern module directly creating resources
resource "powerplatform_environment_group" "this" {
  display_name = var.name
}

resource "powerplatform_environment" "environments" {
  for_each = var.environments
  # ... direct creation
}
```

This approach has several issues:
- Violates Azure Verified Module (AVM) principles
- Creates code duplication when multiple patterns need same resources
- Makes testing more complex
- Prevents reuse of resource logic
- Mixes orchestration concerns with resource management

### Solution: Child Module Architecture

**Pattern modules orchestrate, resource modules create**:

```hcl
# Pattern module orchestrates child modules
module "environment_group" {
  source = "../res-environment-group"
  display_name = var.name
}

module "environments" {
  source   = "../res-environment"
  for_each = local.environments
  # ...
}
```

**Resource module focuses on single resource type**:
```hcl
# res-environment module
resource "powerplatform_environment" "this" {
  # Single responsibility: Environment creation
}
```

### Why This Works

#### Modularity
Each resource module has a single responsibility. This makes:
- Code easier to understand
- Changes isolated and safer
- Testing more focused
- Maintenance simpler

#### Reusability
Resource modules can be used by multiple pattern modules:
```hcl
# Both of these can use res-environment:
ptn-environment-group → res-environment
res-environment (standalone) → (itself)
```

#### AVM Compliance
Follows Azure Verified Module specification TFNFR27:
- Child modules focus on resource logic
- Parent modules handle orchestration
- Provider configuration centralized

#### Composability
Pattern modules can easily combine multiple resources:
```hcl
module "vnet_extension" {
  # Combines multiple Azure networking resources
  source = "../ptn-azure-vnet-extension"
}
```

### Alternatives Considered

**Alternative 1: Monolithic Modules**
- Single large module with all resources
- ❌ Rejected: Hard to maintain, test, and reuse

**Alternative 2: Flat Configuration Files**
- No modules, just resource definitions
- ❌ Rejected: Extreme duplication across environments

**Alternative 3: Dynamic Module Generation**
- Generate modules programmatically
- ❌ Rejected: Over-engineered for demonstration needs

### Implications

#### For Child Modules (res-*)
- Must not contain `providers.tf` (breaks `for_each`)
- Only include `versions.tf` with provider requirements
- Focus purely on resource logic
- Should be reusable across patterns

#### For Pattern Modules (ptn-*)
- Must include both `versions.tf` and `providers.tf`
- Focus on orchestration and data transformation
- Use locals for variable mapping between modules
- Manage dependencies with `depends_on`

#### For Testing
- Child modules need provider configuration in tests
- Pattern modules test orchestration logic
- Integration tests validate end-to-end flows

---

## Decision 2: Provider Configuration Strategy

### Context

Terraform provider configuration can be placed in different files and at different levels of the module hierarchy. Where should we configure authentication?

### Problem

**The Provider Paradox**:
- **Too centralized**: Unclear how child modules work
- **Too distributed**: Breaks meta-arguments (for_each, count)
- **Implicit configuration**: Poor educational value for demonstrations

### Solution: Strategic Provider Placement

**Child Modules: versions.tf ONLY**:
```hcl
# configurations/res-environment/versions.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
# NO providers.tf file in child modules
```

**Standalone Configurations: Both Files**:
```hcl
# configurations/ptn-environment-group/versions.tf
terraform {
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

```hcl
# configurations/ptn-environment-group/providers.tf
provider "powerplatform" {
  # OIDC authentication via environment variables:
  # - POWER_PLATFORM_USE_OIDC=true
  # - POWER_PLATFORM_CLIENT_ID
  # - POWER_PLATFORM_TENANT_ID
}
```

### Why Two Separate Files?

#### Different Execution Phases

**Phase 1: terraform init (uses versions.tf)**:
```
1. Read versions.tf
2. Identify required providers
3. Download providers from registry
4. Initialize backend
```

**Phase 2: terraform plan/apply (uses providers.tf)**:
```
1. Read providers.tf
2. Authenticate using configured method
3. Execute Terraform operations
```

#### Different Purposes

| File | Purpose | Contains | Used When |
|------|---------|----------|-----------|
| versions.tf | Requirements | Provider source, version constraints, backend config | terraform init |
| providers.tf | Configuration | Authentication method, features, aliases | terraform plan/apply |

### The Meta-Argument Limitation

**Why child modules can't have providers.tf**:

```hcl
# This FAILS:
module "environments" {
  source   = "../res-environment"  # Has providers.tf
  for_each = local.environments    # ← ERROR!
}

# Error: "Module with provider config cannot use for_each"
```

**Why?**
- Terraform restrictions on modules with provider blocks
- Provider configuration creates ambiguity
- Not unique to AVM - standard Terraform behavior
- Documented in Terraform provider configuration docs

**Solution: Remove providers.tf from child modules**:
```hcl
# This WORKS:
module "environments" {
  source   = "../res-environment"  # No providers.tf
  for_each = local.environments    # ✅ Works!
  # Provider inherited from parent
}
```

### Provider Inheritance Flow

```
Root Module (ptn-environment-group)
├── providers.tf         ← Configures OIDC auth
├── versions.tf          ← Declares requirements
│
└── Calls Child Module (res-environment)
    ├── versions.tf      ← Validates compatibility
    └── NO providers.tf  ← Inherits from parent
```

**What happens:**
1. Parent creates authenticated provider instance
2. Terraform passes provider to child modules
3. Child validates version compatibility
4. All modules share same authentication
5. Meta-arguments work correctly

### Educational Value for PPCC25

Including `providers.tf` in standalone configurations provides teaching opportunities:

**Explicit OIDC Pattern**:
```hcl
provider "powerplatform" {
  # WHY: Zero Trust security pattern
  # Authentication via temporary OIDC tokens, not stored credentials
  
  # Set by GitHub Actions:
  # - POWER_PLATFORM_USE_OIDC=true
  # - POWER_PLATFORM_CLIENT_ID (from secrets)
  # - POWER_PLATFORM_TENANT_ID (from secrets)
}
```

**Self-Documenting**:
- Attendees immediately see authentication method
- No need to search through workflow files
- Clear connection between code and security

**Hybrid Scenario Clarity**:
```hcl
provider "azurerm" {
  features {}
  # Azure OIDC: ARM_USE_OIDC, ARM_CLIENT_ID
}

provider "powerplatform" {
  # Power Platform OIDC: POWER_PLATFORM_USE_OIDC
}
```

Shows multi-cloud governance patterns.

### Alternatives Considered

**Alternative 1: All modules have providers.tf**
- ❌ Rejected: Breaks for_each, violates AVM

**Alternative 2: No providers.tf anywhere**
- ❌ Rejected: Implicit authentication, poor educational value

**Alternative 3: Single provider configuration file at root**
- ❌ Rejected: Not standard Terraform practice

### Implications

#### For File Organization
```
Child Module Structure:
res-environment/
├── main.tf          ✅
├── variables.tf     ✅
├── outputs.tf       ✅
├── versions.tf      ✅
└── providers.tf     ❌ NEVER

Standalone Configuration Structure:
ptn-environment-group/
├── main.tf          ✅
├── variables.tf     ✅
├── outputs.tf       ✅
├── versions.tf      ✅
├── providers.tf     ✅ REQUIRED
└── locals.tf        ✅
```

#### For Development Workflow
1. Create child modules first (res-*)
2. Test with provider in test files
3. Create pattern modules (ptn-*)
4. Pattern modules configure provider
5. Child modules inherit automatically

#### For Troubleshooting
```bash
# Module can't use for_each?
→ Check if child module has providers.tf
→ Remove it, provider inherits from parent

# Provider not configured?
→ Check if standalone config has providers.tf
→ Add it to root/standalone configuration

# Authentication failed?
→ Check environment variables in workflow
→ Verify GitHub secrets configured
```

---

## Decision 3: Prevent Destroy Lifecycle Management

### Context

Terraform's `prevent_destroy` lifecycle rule prevents accidental deletion of critical resources. Should we enforce this in demonstration modules?

### Problem

**The Safety vs Flexibility Trade-off**:

**Too Restrictive**:
```hcl
resource "powerplatform_environment" "this" {
  lifecycle {
    prevent_destroy = true  # Blocks ALL destroys
  }
}
```
- Hard to clean up demo environments
- Requires manual state manipulation
- Complicates iterative development

**Too Permissive**:
```hcl
# No prevent_destroy at all
resource "powerplatform_environment" "this" {
  # Can be destroyed accidentally
}
```
- Risk of accidental production deletion
- No technical safeguards beyond process

### Solution: Context-Aware Lifecycle Rules

**For PPCC25 Demonstration**:
```hcl
# Do NOT enforce prevent_destroy in demo
# Reason: Workflow protections are sufficient
resource "powerplatform_environment" "this" {
  # Rely on workflow safeguards:
  # - Manual dispatch only
  # - Explicit confirmation required
  # - Production environment protection
  # - Pre-destroy validation
}
```

**For Production Adoption**:
```hcl
# Conditional prevent_destroy based on environment
resource "powerplatform_environment" "this" {
  lifecycle {
    prevent_destroy = var.environment_type == "Production"
  }
}
```

### Current Workflow Protections

Our `terraform-destroy.yml` workflow already implements:

**Process Controls**:
- Manual workflow dispatch (no auto-trigger)
- Case-sensitive confirmation ("DESTROY")
- Required destroy reason documentation
- Comprehensive audit trail

**Technical Controls**:
- Production environment protection
- Pre-destroy validation checks
- Resource existence verification
- State backup before destruction
- OIDC authentication (no stored credentials)

**Example workflow protection**:
```yaml
- name: Confirm Destruction
  if: inputs.confirm_destroy != 'DESTROY'
  run: |
    echo "::error::Destruction not confirmed"
    echo "You must type 'DESTROY' exactly to proceed"
    exit 1
```

### Why This Decision Makes Sense

#### For Demonstrations
- **Simplicity**: Focuses on workflow-based governance
- **Flexibility**: Easy cleanup between demo runs
- **Educational**: Shows process controls, not just technical ones
- **Practical**: Reflects real-world DevOps practices

#### For Production
- **Defense in Depth**: Multiple layers of protection
- **Compliance**: Satisfies audit requirements
- **Safety**: Final technical safeguard
- **Flexibility**: Can override in emergencies

### Decision Matrix

| Context | Use prevent_destroy? | Primary Protection |
|---------|---------------------|-------------------|
| PPCC25 Demo | No | Workflow controls + manual confirmation |
| Development | No | Workflow controls + easy recreation |
| UAT/Staging | Optional | Workflow controls + environment protection |
| Production | Yes | Workflow + technical + prevent_destroy |

### Alternatives Considered

**Alternative 1: Always enforce prevent_destroy**
- ❌ Rejected: Too rigid for demonstrations and development

**Alternative 2: Never use prevent_destroy**
- ❌ Rejected: Insufficient for production scenarios

**Alternative 3: Manual state manipulation for demos**
- ❌ Rejected: Poor educational example, error-prone

### Implications

#### For Demo Environment Management
```bash
# Easy cleanup without prevent_destroy
terraform destroy -var-file=dev.tfvars
# Works immediately after workflow confirmation
```

#### For Production Implementation
```hcl
# Add conditional lifecycle after PPCC25
variable "environment_type" {
  type = string
  validation {
    condition     = contains(["Development", "Sandbox", "Production"], var.environment_type)
    error_message = "Invalid environment type"
  }
}

resource "powerplatform_environment" "this" {
  lifecycle {
    prevent_destroy = var.environment_type == "Production"
    
    # WHY: Production environments should require state manipulation to destroy
    # WHY: Non-production environments should be easy to recreate
  }
}
```

#### For Documentation
- Emphasize workflow protections in demos
- Document when prevent_destroy should be added
- Provide examples of conditional implementation
- Explain defense-in-depth strategy

---

## Common Patterns Across Decisions

### Pattern 1: Educational Value First

Every decision prioritizes teaching:
- Explicit over implicit configuration
- Simple over clever solutions
- Self-documenting code structures
- Clear connections between concepts

### Pattern 2: Defense in Depth

Security uses multiple layers:
- OIDC authentication (no stored secrets)
- Workflow protections (manual confirmation)
- Environment protection (production gates)
- Technical safeguards (optional prevent_destroy)

### Pattern 3: AVM Compliance

All decisions align with Azure Verified Modules:
- Child module patterns
- Provider configuration strategies
- Testing approaches
- Documentation standards

### Pattern 4: Flexibility for Context

Solutions adapt to different needs:
- Demonstrations prioritize simplicity
- Production prioritizes safety
- Development prioritizes speed
- All contexts maintain security

---

## Applying These Decisions

### For New Modules

**Creating a child module (res-*)**:
```bash
# File structure
mkdir configurations/res-new-resource
cd configurations/res-new-resource

# Required files
touch main.tf variables.tf outputs.tf versions.tf
# Note: NO providers.tf

# versions.tf content
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
EOF
```

**Creating a pattern module (ptn-*)**:
```bash
# File structure
mkdir configurations/ptn-new-pattern
cd configurations/ptn-new-pattern

# Required files
touch main.tf variables.tf outputs.tf versions.tf providers.tf locals.tf
# Note: INCLUDE providers.tf

# providers.tf content
cat > providers.tf << 'EOF'
provider "powerplatform" {
  # OIDC authentication via environment variables
  # Educational documentation here
}
EOF
```

### For Adapting to Production

**Step 1: Enable prevent_destroy conditionally**:
```hcl
variable "environment_type" {
  type = string
}

resource "powerplatform_environment" "this" {
  lifecycle {
    prevent_destroy = var.environment_type == "Production"
  }
}
```

**Step 2: Add approval requirements**:
```yaml
# .github/workflows/terraform-apply.yml
environment:
  name: ${{ inputs.environment_type }}
  # Production environment has required reviewers in GitHub
```

**Step 3: Implement backup strategies**:
```yaml
- name: Backup State Before Changes
  run: |
    az storage blob upload \
      --account-name $STORAGE_ACCOUNT \
      --container-name backups \
      --name "backup-$(date +%Y%m%d-%H%M%S).tfstate"
```

### For Troubleshooting

**Issue: Module can't use for_each**
```bash
# Diagnosis
grep -r "provider \"" configurations/res-*/

# Solution
# Remove providers.tf from child modules
rm configurations/res-environment/providers.tf
```

**Issue: Authentication not working**
```bash
# Diagnosis
echo $POWER_PLATFORM_USE_OIDC
echo $POWER_PLATFORM_CLIENT_ID

# Solution
# Verify providers.tf exists in root configuration
ls configurations/ptn-*/providers.tf
```

**Issue: Destroy blocked unexpectedly**
```bash
# Diagnosis
grep -A5 "lifecycle" configurations/*/main.tf

# Solution
# Check if prevent_destroy is enabled
# For demos: Should be false or conditional
# For production: Should be true
```

---

## Evolution of These Decisions

These architectural decisions will evolve:

### Post-PPCC25 Review

After the conference presentation:
1. Gather feedback on educational clarity
2. Assess real-world adoption challenges
3. Evaluate production implementation experiences
4. Update based on community insights

### Production Hardening

For production use:
1. Add conditional prevent_destroy
2. Implement comprehensive backup strategies
3. Add advanced monitoring and alerting
4. Expand approval workflows

### Community Contributions

As the community grows:
1. Document new patterns discovered
2. Add alternative approaches that work
3. Share lessons learned from implementations
4. Refine based on scale experiences

---

## References

### Internal Documentation
- **[Common Patterns](../reference/common-patterns.md)** - Reusable configuration patterns
- **[Configuration Catalog](../reference/configuration-catalog.md)** - All available modules
- **[Module Reference](../reference/module-reference.md)** - Detailed specifications
- **[Getting Started Tutorial](../tutorials/01-getting-started.md)** - Hands-on learning

### External Standards
- [Azure Verified Modules Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [Terraform Provider Configuration](https://developer.hashicorp.com/terraform/language/providers/configuration)
- [Terraform Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [AVM TFNFR27 - Provider Configuration](https://azure.github.io/Azure-Verified-Modules/specs/tf/#id-tfnfr27---category-composition---cross-referencing-modules)

### Baseline Guidelines
- [PPCC25 Baseline Instructions](/.github/instructions/baseline.instructions.md)
- [Terraform IaC Standards](/.github/instructions/terraform-iac.instructions.md)
- [GitHub Automation Standards](/.github/instructions/github-automation.instructions.md)

---

## Conclusion

These architectural decisions create a foundation that:

**Enables Learning**:
- Clear structure for understanding
- Explicit over implicit patterns
- Self-documenting code organization

**Supports Scaling**:
- Modular, reusable components
- AVM-compliant patterns
- Production-ready when needed

**Maintains Security**:
- OIDC authentication throughout
- Multiple protection layers
- Defense-in-depth approach

**Balances Trade-offs**:
- Demo simplicity vs production safety
- Educational value vs technical rigor
- Flexibility vs control

The decisions documented here reflect the current best understanding of the requirements for the PPCC25 demonstration. As the project evolves and the community grows, these decisions should be revisited and refined based on real-world experience and feedback.

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0  
**Maintained By**: PPCC25 Core Team  
**Feedback**: [GitHub Discussions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
