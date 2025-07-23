---
mode: agent
---

# Dependabot Groups Patterns Update Task

## 🎯 Task Definition

**Objective:** Automatically update Dependabot configuration groups patterns by systematically analyzing the codebase to identify all current and potential dependencies, ensuring comprehensive coverage while maintaining logical groupings.

## 📋 Specific Requirements

### 1. Codebase Analysis Phase

**GitHub Actions Analysis:**
- Scan `.github/workflows/*.yml` files for all action references (e.g., `actions/checkout@v4`, `azure/login@v2`)
- Scan `.github/actions/*/action.yml` files for composite action dependencies
- Extract action namespaces and patterns (e.g., `actions/*`, `azure/*`, `hashicorp/*`)
- Identify version pinning strategies and update frequency requirements

**Terraform Dependencies Analysis:**
- Scan `configurations/*/main.tf` and `modules/*/main.tf` for provider requirements
- Extract provider sources from `terraform` blocks and `required_providers`
- Identify provider namespaces (e.g., `microsoft/power-platform`, `hashicorp/azurerm`)
- Analyze version constraints and compatibility requirements

**Docker Dependencies Analysis:**
- Scan `.devcontainer/devcontainer.json` for base images and features
- Check for `Dockerfile` references and base image patterns
- Identify container registries and image naming patterns
- Extract feature dependencies and tool installations

**Development Dependencies Analysis:**
- Scan `devcontainer.json` features for development tools
- Identify VS Code extensions and development utilities
- Check for language-specific tooling (Go, Python, Node.js)
- Analyze tool version requirements and update patterns

**Documentation Dependencies Analysis:**
- Check `docs/go.mod` for Hugo modules and themes
- Scan for git submodules in `.gitmodules`
- Identify documentation build dependencies
- Check for external theme or plugin references

### 2. Pattern Generation Phase

**Generate Comprehensive Patterns:**
- Create specific patterns for identified dependencies
- Group by logical categories (Microsoft, HashiCorp, Docker registries)
- Include both current and anticipated future dependencies
- Apply wildcard patterns strategically to reduce maintenance overhead

**Pattern Validation:**
- Ensure patterns don't conflict or overlap inappropriately
- Validate pattern specificity vs. maintainability balance
- Test patterns against current dependency names
- Check for potential false positives or missed dependencies

### 3. Configuration Update Phase

**Update Dependabot Configuration:**
- Replace existing patterns in `.github/dependabot.yml`
- Maintain existing group structure and naming conventions
- Preserve security-focused grouping priorities
- Keep existing scheduling and PR limit configurations

**Documentation Updates:**
- Update inline comments explaining pattern choices
- Document pattern maintenance strategy
- Include examples of dependencies covered by each pattern
- Add notes about anticipated future dependencies

## 🔒 Constraints

### Security Requirements
- **Maintain security-first approach** - Critical security dependencies must remain in priority groups
- **Preserve permission principles** - GitHub Actions patterns must reflect elevated permission requirements
- **Keep infrastructure separation** - Terraform providers must maintain separate grouping from development tools

### Maintenance Constraints
- **Minimize pattern complexity** - Avoid over-engineering patterns that require frequent updates
- **Balance specificity vs. coverage** - Patterns should be specific enough to be meaningful but broad enough to catch new dependencies
- **Preserve existing workflow** - Don't break existing PR workflows or review processes

### Performance Constraints
- **Respect PR limits** - Ensure patterns don't exceed configured `open-pull-requests-limit`
- **Maintain update frequency** - Patterns should align with existing scheduling strategy
- **Avoid pattern conflicts** - Ensure clear priority order for overlapping patterns

## ✅ Success Criteria

### Coverage Verification
- [ ] **100% of current dependencies** are covered by appropriate patterns
- [ ] **Anticipated dependencies** are covered by forward-looking patterns
- [ ] **No ungrouped PRs** for dependencies that should logically be grouped
- [ ] **Pattern efficiency** - Minimal pattern count while maintaining logical separation

### Maintenance Reduction
- [ ] **Reduced maintenance overhead** - Patterns require updates only for major new dependency categories
- [ ] **Clear pattern logic** - Each pattern's purpose and coverage is well-documented
- [ ] **Future-proof design** - Patterns accommodate likely future dependencies without modification

### Quality Assurance
- [ ] **YAML syntax validation** - Configuration passes yamllint and actionlint checks
- [ ] **Pattern testing** - All patterns successfully match intended dependencies
- [ ] **Documentation completeness** - All pattern choices are explained and justified
- [ ] **Backward compatibility** - Existing PR workflows continue to function

## 🔍 Validation Steps

### Pre-Update Analysis
1. **Inventory current dependencies** - Create comprehensive list of all current dependencies across all ecosystems
2. **Map dependency patterns** - Identify naming patterns and logical groupings
3. **Assess pattern gaps** - Identify dependencies not covered by current patterns
4. **Predict future dependencies** - Anticipate likely additions based on project roadmap

### Post-Update Verification
1. **Pattern coverage test** - Verify all current dependencies match appropriate patterns
2. **Conflict detection** - Ensure no pattern conflicts or unexpected groupings
3. **Syntax validation** - Run YAML validation tools to ensure configuration correctness
4. **Documentation review** - Verify all pattern choices are documented and justified

## 📁 File Scope

**Primary Target:**
- `.github/dependabot.yml` - Main configuration file to update

**Analysis Sources:**
- `.github/workflows/*.yml` - GitHub Actions workflows
- `.github/actions/*/action.yml` - Composite actions
- `configurations/*/main.tf` - Terraform configurations
- `modules/*/main.tf` - Terraform modules
- `.devcontainer/devcontainer.json` - Development container configuration
- `docs/go.mod` - Hugo documentation dependencies
- `.gitmodules` - Git submodules (if present)

**Documentation Updates:**
- Update inline comments in `dependabot.yml`
- Consider updating `CHANGELOG.md` if changes are significant
- Update any related documentation in `docs/` if dependency management process changes

## 🎯 Expected Outcome

A comprehensive, maintainable Dependabot configuration that:
- **Automatically groups** all current and anticipated dependencies appropriately
- **Reduces maintenance overhead** through strategic pattern design
- **Maintains security priorities** while improving coverage
- **Provides clear documentation** of pattern logic and coverage
- **Enables predictable PR management** with consistent grouping behavior