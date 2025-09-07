---
mode: agent
model: Claude Sonnet 4
description: Systematically investigate, diagnose, and fix integration test errors in Terraform configurations with comprehensive validation
---

# Integration Test Error Investigation and Resolution Protocol

## 🎯 **Task Definition**

You are tasked with systematically investigating and resolving integration test failures in Terraform configurations. This prompt provides a proven methodology that ensures thorough analysis, proper fixes, and comprehensive validation before considering the task complete.

## 📋 **Mandatory Workflow Steps**

### **Phase 1: Investigation and Analysis**

#### **Step 1.1: Create Project Tracking**
```markdown
ALWAYS create a todo list using manage_todo_list tool with these components:
1. Analyze test failures and identify root causes
2. Categorize distinct errors (by file, line, error type)  
3. Formulate fix propositions and select recommendations
4. Implement recommended fixes following project standards
5. Execute validation pipeline (formatting, syntax, local validation)
6. Commit changes only after all validations pass
```

#### **Step 1.2: Error Categorization Matrix**
For each test failure, document:
- **Error Location**: File path and line number
- **Error Type**: Plan-phase vs Apply-phase vs Configuration vs Syntax
- **Error Message**: Exact error text from test output
- **Root Cause**: Why the error occurs (timing, resource access, validation logic)
- **Impact Scope**: Which test runs are affected

#### **Step 1.3: Terraform Testing Phase Analysis**
Critically evaluate each failing assertion based on Terraform testing phases:

**Plan Phase Validation** (command = plan):
- ✅ **VALID**: Variable validation, resource count, static configuration
- ✅ **VALID**: Planned attributes that are deterministic
- ❌ **INVALID**: Runtime resource attributes (IDs, computed values)
- ❌ **INVALID**: Cross-resource comparisons involving provider-generated values
- ❌ **INVALID**: Output validation (outputs not available during plan)

**Apply Phase Validation** (command = apply):
- ✅ **VALID**: All runtime resource attributes
- ✅ **VALID**: Cross-resource relationships and comparisons
- ✅ **VALID**: Output validation and integration testing
- ✅ **VALID**: End-to-end functionality verification

### **Phase 2: Solution Development**

#### **Step 2.1: Root Cause Analysis**
Use the `think` tool to analyze each error systematically:
```markdown
For each error, document:
1. **Immediate Cause**: What specific code or logic is failing
2. **Underlying Cause**: Why this failure pattern occurs
3. **Best Practice Violation**: Which Terraform/testing principle is violated
4. **Precedent Review**: Are there existing patterns in the codebase to follow?
```

#### **Step 2.2: Fix Strategy Selection**
Prioritize solutions in this order:
1. **Phase Separation**: Move assertions to appropriate test phase
2. **Logic Correction**: Fix conditional logic or validation rules
3. **Configuration Update**: Adjust resource or variable configuration
4. **Test Restructure**: Reorganize test structure if needed

#### **Step 2.3: Implementation Requirements**
- **MANDATORY**: Follow all guidelines in `.github/instructions/baseline.instructions.md`
- **MANDATORY**: Follow all standards in `.github/instructions/terraform-iac.instructions.md`  
- **MANDATORY**: Maintain backward compatibility unless explicitly changing behavior
- **MANDATORY**: Preserve test coverage - don't just delete failing tests

### **Phase 3: Implementation**

#### **Step 3.1: Code Changes**
When implementing fixes:
- Use `multi_replace_string_in_file` for multiple related changes
- Include 3-5 lines of context before/after changes
- Add explanatory comments for WHY changes were made
- Follow project naming conventions and patterns

#### **Step 3.2: Documentation Updates**
If fixes affect functionality or usage:
- Update relevant `_header.md` and `_footer.md` files
- Add troubleshooting guidance for similar issues
- Document any behavior changes in commit messages

### **Phase 4: Validation Pipeline** ⚠️ **CRITICAL PHASE**

#### **Step 4.1: Formatting Validation**
```bash
# MANDATORY: Must pass before proceeding
terraform fmt --recursive
```

#### **Step 4.2: Syntax Validation** 
```bash
# MANDATORY: Must pass before proceeding
terraform validate
```

#### **Step 4.3: Project-Specific Validation**
```bash
# MANDATORY: Must pass before proceeding
./scripts/utils/terraform-local-validation.sh --autofix [module-name]
```

#### **Step 4.4: Validation Success Criteria**
- ✅ All formatting checks pass with no changes needed
- ✅ All syntax validation passes 
- ✅ Local validation script reports "All configurations are valid!"
- ✅ No regression in other module functionality

### **Phase 5: Quality Assurance**

#### **Step 5.1: Change Review**
Before committing, verify:
- All original test assertions are preserved (moved, not deleted)
- Error messages are clear and actionable
- Code follows established patterns in the codebase
- Comments explain WHY changes were needed

#### **Step 5.2: Git Commit Standards**
```bash
# Commit message format:
git commit -m "fix: Brief description of what was fixed

- Detailed explanation of changes made
- Which errors were resolved  
- Which testing phases were affected
- Reference to testing best practices followed

Fixes: [error description]"
```

## 🚨 **Critical Success Criteria**

### **Task is NOT Complete Until:**
- [ ] All integration test errors are categorized and analyzed
- [ ] Root causes are identified with clear explanations
- [ ] Fixes follow proper Terraform testing phase separation
- [ ] All validation pipeline steps pass successfully
- [ ] Changes are committed with descriptive commit messages
- [ ] No regressions are introduced in other functionality

### **Task is Complete When:**
- [ ] All `terraform fmt --recursive` checks pass
- [ ] All `terraform validate` checks pass  
- [ ] Local validation script reports success for affected modules
- [ ] Changes follow project coding standards and patterns
- [ ] Test coverage is maintained or improved
- [ ] Git history shows clean, descriptive commits

## 🛠️ **Common Error Patterns and Solutions**

### **Pattern 1: Plan Phase Runtime Access**
**Symptoms**: "Unknown condition value" errors during plan
**Solution**: Move runtime attribute validation to apply phase

### **Pattern 2: Cross-Resource Dependencies**
**Symptoms**: Resource reference failures or null values
**Solution**: Verify depends_on relationships and resource ordering

### **Pattern 3: Provider State Issues**
**Symptoms**: "Request url must be an absolute url" or similar provider errors
**Solution**: Check resource creation timing and provider configuration

### **Pattern 4: Conditional Logic Errors**
**Symptoms**: Incorrect resource counts or unexpected resource creation
**Solution**: Review conditional expressions and variable validation

## 📚 **Reference Documentation**

- **Project Standards**: `.github/instructions/baseline.instructions.md`
- **Terraform Standards**: `.github/instructions/terraform-iac.instructions.md`
- **Validation Script**: `scripts/utils/terraform-local-validation.sh`
- **Testing Best Practices**: [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)

## 🎯 **Expected Outcome**

Upon completion, you should have:
1. **Clean test suite** with no plan/apply phase violations
2. **Comprehensive test coverage** maintained across all scenarios
3. **Validated code** that passes all project quality gates
4. **Clear documentation** of changes and rationale
5. **Reliable foundation** for future development and testing

Remember: **Quality over speed** - thorough validation prevents future issues and maintains project reliability.