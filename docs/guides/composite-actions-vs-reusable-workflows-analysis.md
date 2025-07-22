![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

# Composite Actions vs Reusable Workflows: Architectural Analysis

## Executive Summary

After analyzing the existing composite actions and proposed reusable workflows, there is **significant overlap** in functionality. This document provides a detailed analysis and recommends a **hybrid approach** that maximizes the strengths of both patterns while minimizing duplication and maintenance overhead.

## Current State Analysis

### Existing Composite Actions (4 actions, ~400 lines)

1. **`detect-terraform-changes`** (150+ lines)
   - Sophisticated change detection with multiple detection methods
   - File-based change detection (git diff)
   - Terraform plan-based change detection
   - Output parsing and workflow control
   - **Strength**: Highly specialized, reusable across workflows

2. **`generate-workflow-metadata`** (100+ lines)
   - AVM-compliant metadata generation
   - Git information extraction
   - Workflow context gathering
   - **Strength**: Standardized metadata across all workflows

3. **`terraform-init-with-backend`** (150+ lines)
   - Robust initialization with retry logic
   - Standardized state naming conventions
   - Network propagation handling
   - Azure backend configuration
   - **Strength**: Enterprise-grade reliability and error handling

4. **`jit-network-access`** (50+ lines)
   - Dynamic IP detection and firewall management
   - Azure Storage Account access control
   - **Strength**: Security-focused, side-effect management

### Proposed Reusable Workflows (5 workflows)

1. **`terraform-validate.yml`** - Code quality and validation
2. **`terraform-plan.yml`** - Planning and change detection
3. **`terraform-apply.yml`** - Infrastructure deployment
4. **`terraform-output.yml`** - Output extraction
5. **`terraform-destroy.yml`** - Resource cleanup

## Overlap Analysis Matrix

| Function            | Existing Action               | Proposed Workflow       | Overlap Level       |
| ------------------- | ----------------------------- | ----------------------- | ------------------- |
| Change Detection    | `detect-terraform-changes`    | `terraform-plan.yml`    | **HIGH** (80%)      |
| Metadata Generation | `generate-workflow-metadata`  | All workflows           | **MEDIUM** (50%)    |
| Initialization      | `terraform-init-with-backend` | All terraform workflows | **HIGH** (90%)      |
| Network Access      | `jit-network-access`          | All terraform workflows | **COMPLETE** (100%) |
| Authentication      | Built into workflows          | All terraform workflows | **COMPLETE** (100%) |
| State Management    | Built into workflows          | All terraform workflows | **HIGH** (85%)      |

## Key Architectural Insights

### Composite Actions Excel At:
- **Granular reusability**: Single-purpose, highly focused functionality
- **Cross-workflow usage**: Can be used in any workflow or even third-party workflows
- **Complex logic**: Better for sophisticated algorithms and conditional processing
- **Side effects**: Managing external resources (firewall rules, network access)
- **Rapid iteration**: Easier to test and debug in isolation

### Reusable Workflows Excel At:
- **End-to-end orchestration**: Managing complete terraform operations
- **Standardized patterns**: Ensuring consistent workflow structure across configurations
- **Centralized maintenance**: Single point of update for entire terraform processes
- **Job-level controls**: Managing runners, environments, and job-level settings
- **Workflow-level features**: Matrix builds, environment protection, approval gates

## Recommended Hybrid Architecture

### Phase 1: Enhance Existing Actions (Immediate)

Keep and enhance the existing composite actions as they provide unique value:

1. **Keep `detect-terraform-changes`** as-is
   - Already highly sophisticated
   - Provides granular change detection capabilities
   - Can be used independently by reusable workflows

2. **Keep `generate-workflow-metadata`** as-is
   - AVM compliance requires this standardization
   - Provides consistent metadata across all operations

3. **Enhance `terraform-init-with-backend`**
   - Add support for workspace selection
   - Add validation steps
   - Improve error reporting

4. **Keep `jit-network-access`** as-is
   - Security-critical functionality
   - Pure side-effect management
   - Works well as standalone action

### Phase 2: Create Focused Reusable Workflows (Strategic)

Implement 3 focused reusable workflows that **use** the existing composite actions:

#### 1. `terraform-validate-and-plan.yml`
```yaml
# Combines validation, planning, and change detection
# Uses: detect-terraform-changes, generate-workflow-metadata, terraform-init-with-backend
jobs:
  validate-and-plan:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/jit-network-access
        with:
          action: add
      - uses: ./.github/actions/terraform-init-with-backend
      - uses: ./.github/actions/detect-terraform-changes
      - uses: ./.github/actions/generate-workflow-metadata
      - name: Terraform Validate
        run: terraform validate
      - name: Terraform Plan
        run: terraform plan -out=plan.tfplan
      - uses: ./.github/actions/jit-network-access
        with:
          action: remove
```

#### 2. `terraform-apply.yml`
```yaml
# Handles deployment with comprehensive error handling
# Uses: all existing composite actions
```

#### 3. `terraform-output-and-destroy.yml`
```yaml
# Handles output extraction and cleanup operations
# Uses: terraform-init-with-backend, jit-network-access
```

### Phase 3: Migration Strategy (Tactical)

1. **Update existing workflows** to use new reusable workflows
2. **Migrate gradually** - one workflow at a time
3. **Maintain backward compatibility** during transition
4. **Deprecate old patterns** only after full migration

## Benefits of Hybrid Approach

### ✅ Advantages

1. **Leverages existing investment**: 400+ lines of proven, robust code
2. **Maintains flexibility**: Composite actions can be used independently
3. **Reduces duplication**: Reusable workflows eliminate workflow-level duplication
4. **Improves maintainability**: Best of both patterns
5. **Enables gradual migration**: No big-bang changes required
6. **Preserves specialization**: Each component does what it does best

### ⚠️ Considerations

1. **Slight complexity increase**: Two patterns to maintain
2. **Learning curve**: Team needs to understand both patterns
3. **Documentation overhead**: Need to document the interaction patterns

## Implementation Roadmap

### Week 1-2: Action Enhancement
- Enhance `terraform-init-with-backend` with additional features
- Add comprehensive testing for all actions
- Update action documentation

### Week 3-4: Reusable Workflow Creation
- Create `terraform-validate-and-plan.yml`
- Create `terraform-apply.yml`  
- Create `terraform-output-and-destroy.yml`
- Comprehensive testing of new workflows

### Week 5-6: Migration
- Migrate `terraform-validate.yml` to use new reusable workflow
- Migrate `terraform-plan.yml` to use new reusable workflow
- Migrate remaining workflows one by one

### Week 7: Cleanup
- Remove deprecated workflow patterns
- Update documentation
- Team training on new patterns

## Expected Results

### Quantified Benefits
- **Code reduction**: ~1,200 lines eliminated (60% of current duplication)
- **Maintenance points**: Reduced from 25 to 12 (52% reduction)
- **Action reusability**: 4 actions available for any workflow
- **Workflow standardization**: 3 consistent patterns for all terraform operations

### Qualitative Improvements
- **Better separation of concerns**: Actions handle logic, workflows handle orchestration
- **Enhanced testability**: Each component can be tested independently
- **Improved debugging**: Clearer failure isolation
- **Future-proof architecture**: Supports both current and future workflow patterns

## Conclusion

The hybrid approach maximizes the value of existing composite actions while gaining the benefits of reusable workflows. This strategy provides the best long-term architecture for maintainability, reusability, and team productivity.

**Recommendation**: Proceed with the hybrid approach rather than replacing existing actions entirely.
