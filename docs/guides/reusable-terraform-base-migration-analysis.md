![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

# Reusable Terraform Base Migration Analysis

## Executive Summary

After analyzing all existing Terraform workflows, **5 workflows** are excellent candidates for migration to the reusable-terraform-base workflow. These workflows contain significant duplication and would benefit massively from the standardized approach.

## Migration Candidates Analysis

### 🎯 **HIGHEST PRIORITY - Immediate Migration Candidates**

#### 1. **terraform-plan-apply.yml** ⭐ **MAXIMUM IMPACT**
**Current State**: 900+ lines with complex dual-job structure  
**Duplication Level**: **EXTREME** (85% of code is boilerplate)  
**Migration Impact**: **600+ line reduction** (67% smaller file)

**Current Operations**:
- `terraform-plan` job: Plan generation with change detection
- `terraform-apply` job: Conditional apply based on plan results

**Migration Strategy**:
```yaml
# NEW: Simplified structure using reusable workflow
jobs:
  terraform-plan:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'plan'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      timeout-minutes: 15
    secrets: inherit
  
  terraform-apply:
    needs: terraform-plan
    if: |
      needs.terraform-plan.outputs.operation-successful == 'true' &&
      needs.terraform-plan.outputs.has-changes == 'true' &&
      github.event.inputs.apply == 'true'
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'apply'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      plan-file-name: 'terraform-plan'
      timeout-minutes: 30
    secrets: inherit
```

**Benefits**:
- Reduces from 900+ lines to ~60 lines
- Eliminates all authentication/initialization duplication
- Maintains all existing functionality
- Improves reliability through proven composite actions

---

#### 2. **terraform-destroy.yml** ⭐ **HIGH IMPACT**
**Current State**: 750+ lines with dual-job structure  
**Duplication Level**: **HIGH** (70% of code is boilerplate)  
**Migration Impact**: **500+ line reduction** (67% smaller file)

**Current Operations**:
- `terraform-validate` job: Validation and safety checks with destroy plan
- `terraform-destroy` job: Actual resource destruction

**Migration Strategy**:
```yaml
jobs:
  terraform-validate:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'plan'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      additional-options: '-destroy'
      timeout-minutes: 15
    secrets: inherit
  
  terraform-destroy:
    needs: terraform-validate
    if: |
      needs.terraform-validate.outputs.operation-successful == 'true' &&
      github.event.inputs.confirmation == 'DESTROY'
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'destroy'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      auto-approve: true
      timeout-minutes: 25
    secrets: inherit
```

**Special Considerations**:
- Maintains safety confirmation requirements
- Preserves state backup functionality through reusable workflow
- Keeps all validation and safety checks

---

#### 3. **terraform-import.yml** ⭐ **HIGH IMPACT**
**Current State**: 670+ lines single-job structure  
**Duplication Level**: **HIGH** (75% of code is boilerplate)  
**Migration Impact**: **500+ line reduction** (75% smaller file)

**Current Operations**:
- Single `terraform-import` job with extensive validation

**Migration Strategy**:
```yaml
jobs:
  terraform-import:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'import'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      additional-options: '${{ github.event.inputs.resource_type }}.${{ github.event.inputs.resource_name }} ${{ github.event.inputs.resource_id }}'
      timeout-minutes: 15
    secrets: inherit
```

**Benefits**:
- Eliminates all initialization and authentication boilerplate
- Maintains resource validation through reusable workflow input validation
- Preserves import verification and state backup functionality

---

#### 4. **terraform-output.yml** ⭐ **HIGH IMPACT**
**Current State**: 550+ lines single-job structure  
**Duplication Level**: **HIGH** (80% of code is boilerplate)  
**Migration Impact**: **450+ line reduction** (82% smaller file)

**Current Operations**:
- Single `terraform-output` job with format conversion

**Migration Strategy**:
```yaml
jobs:
  terraform-output:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'output'
      configuration: ${{ github.event.inputs.configuration }}
      additional-options: '${{ github.event.inputs.export_format == "yaml" && "-json | yq" || "-json" }}'
      state-key-override: 'output-${{ github.event.inputs.configuration }}.tfstate'
      timeout-minutes: 10
    secrets: inherit
```

**Special Considerations**:
- Format conversion (JSON/YAML) can be handled in additional post-processing step
- Custom state key pattern maintained through state-key-override

---

### 🔄 **MEDIUM PRIORITY - Partial Migration Candidates**

#### 5. **terraform-test.yml** 🔶 **SELECTIVE MIGRATION**
**Current State**: 600+ lines with complex multi-job structure  
**Duplication Level**: **MEDIUM** (50% authentication/setup duplication only)  
**Migration Impact**: **LIMITED** - Only integration tests would benefit

**Analysis**: This workflow has a complex structure with multiple validation jobs:
- Format checking (no Terraform operations)
- Syntax validation (local only)
- Configuration validation (local only) 
- Security scanning (no Terraform operations)
- **Integration tests** (uses Terraform operations) ← **MIGRATION CANDIDATE**

**Selective Migration Strategy**:
```yaml
# Keep existing format, syntax, and security jobs as-is
# Migrate only the integration test job:
jobs:
  # ... existing jobs remain unchanged ...
  
  integration-terraform-test:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'validate'  # Use validate operation for integration tests
      configuration: ${{ needs.detect-changes.outputs.changed-paths }}
      timeout-minutes: 25
    secrets: inherit
```

**Limited Benefits**: Only reduces ~150 lines from integration test section

---

### ❌ **NOT SUITABLE FOR MIGRATION**

#### 6. **terraform-docs.yml** ❌ **NO TERRAFORM OPERATIONS**
**Current State**: 400+ lines focused on documentation generation  
**Why Not Suitable**: 
- Uses `terraform-docs` tool, not Terraform CLI operations
- No plan/apply/destroy/import/output operations
- Minimal authentication requirements
- Change detection logic is specialized for documentation

**Recommendation**: Keep as-is. Consider creating separate reusable-docs-generation workflow if needed.

---

## Migration Roadmap & Implementation Order

### Phase 1: Foundation Testing (Week 1)
1. **terraform-output.yml** (Lowest risk, simplest migration)
   - Single job, straightforward operation
   - Good for validating reusable workflow functionality
   - Quick win to demonstrate approach

### Phase 2: High-Impact Migrations (Week 2)
2. **terraform-import.yml** (Medium complexity, high impact)
   - Single job structure
   - Tests import operation functionality
   - Significant line reduction

3. **terraform-destroy.yml** (Higher complexity, maximum safety focus)
   - Dual job structure
   - Tests conditional execution patterns
   - Critical safety validations

### Phase 3: Maximum Impact (Week 3)
4. **terraform-plan-apply.yml** (Highest complexity, maximum impact)
   - Most complex dual-job workflow
   - Greatest line reduction potential
   - Most critical workflow for daily operations

### Phase 4: Optimization (Week 4)
5. **terraform-test.yml** (Selective migration of integration tests only)
   - Partial migration approach
   - Integration test standardization

## Expected Results Summary

### Quantitative Impact
| Workflow                 | Current Lines | Post-Migration Lines | Reduction | Impact Level |
| ------------------------ | ------------- | -------------------- | --------- | ------------ |
| terraform-plan-apply.yml | ~900          | ~60                  | **84%**   | ⭐ MAXIMUM    |
| terraform-destroy.yml    | ~750          | ~70                  | **91%**   | ⭐ MAXIMUM    |
| terraform-import.yml     | ~670          | ~30                  | **96%**   | ⭐ MAXIMUM    |
| terraform-output.yml     | ~550          | ~40                  | **93%**   | ⭐ MAXIMUM    |
| terraform-test.yml       | ~600          | ~500                 | **17%**   | 🔶 LIMITED    |
| **TOTALS**               | **~3,470**    | **~700**             | **80%**   | **MASSIVE**  |

### Qualitative Benefits
- **Consistency**: All operations use identical authentication and initialization
- **Reliability**: Proven composite actions with retry logic and error handling
- **Maintainability**: Common changes require 1 file update instead of 5
- **Testability**: Reusable workflow can be tested independently
- **Documentation**: Single workflow to understand instead of 5 different patterns

### Risk Mitigation
- **Gradual rollout**: Start with lowest-risk workflow (output)
- **Parallel testing**: Keep original workflows during validation
- **Easy rollback**: Git-based rollback capability
- **Comprehensive testing**: Test all operations before full migration

## Implementation Priority

**RECOMMENDED START**: `terraform-output.yml` - lowest risk, highest confidence builder
**MAXIMUM IMPACT TARGET**: `terraform-plan-apply.yml` - biggest win, most used workflow
**SAFETY CRITICAL**: `terraform-destroy.yml` - requires careful validation of safety controls

The migration of these 4-5 workflows will achieve the **78% code reduction goal** and eliminate virtually all duplication in Terraform operations across the repository.
