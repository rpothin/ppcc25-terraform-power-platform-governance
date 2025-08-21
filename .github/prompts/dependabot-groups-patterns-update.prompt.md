---
mode: agent
model: Claude Sonnet 4
description: "Systematically analyze codebase and update Dependabot configuration groups patterns for comprehensive dependency coverage"
---

# Dependabot Groups Patterns Update Task

## 🎯 Primary Objective

Update `.github/dependabot.yml` groups patterns by analyzing the entire codebase to ensure 100% dependency coverage with maintainable, forward-looking patterns.

## 📊 Task Execution Framework

### Phase 1: Discovery & Analysis [REQUIRED]

#### Step 1.1: Dependency Discovery
Execute these commands to build comprehensive dependency inventory:

```bash
# GitHub Actions dependencies
echo "=== GitHub Actions Dependencies ==="
grep -h "uses:" .github/workflows/*.yml .github/actions/*/action.yml 2>/dev/null | \
  sed 's/.*uses: *//' | sed 's/@.*//' | sort -u

# Terraform provider dependencies
echo "=== Terraform Providers ==="
grep -h "source.*=" configurations/*/main.tf modules/*/main.tf 2>/dev/null | \
  grep -E '(registry\.terraform\.io|[^/]+/[^/]+)' | sed 's/.*= *//' | tr -d '"' | sort -u

# Docker base images
echo "=== Docker Images ==="
jq -r '.image // empty' .devcontainer/devcontainer.json 2>/dev/null
grep -h "FROM" **/Dockerfile 2>/dev/null | sed 's/FROM *//'

# Development features
echo "=== Dev Container Features ==="
jq -r '.features | keys[]' .devcontainer/devcontainer.json 2>/dev/null
```

#### Step 1.2: Pattern Analysis Matrix
Create dependency analysis table:

| Ecosystem             | Namespace               | Current Count | Pattern Type | Update Frequency |
| --------------------- | ----------------------- | ------------- | ------------ | ---------------- |
| github-actions        | actions/*               | X             | wildcard     | weekly           |
| github-actions        | azure/*                 | X             | wildcard     | weekly           |
| terraform             | microsoft/*             | X             | wildcard     | monthly          |
| docker                | mcr.microsoft.com/*     | X             | prefix       | monthly          |
| devcontainer-features | ghcr.io/devcontainers/* | X             | prefix       | monthly          |

### Phase 2: Pattern Design [REQUIRED]

#### Step 2.1: Pattern Strategy Selection
For each namespace, choose pattern strategy:

```yaml
# Decision Matrix:
# High frequency changes (>5 deps) → Use wildcard: "namespace/*"
# Medium frequency (2-5 deps) → Use prefix: "namespace/common-prefix-*"
# Low frequency (1-2 deps) → Use explicit: "namespace/specific-dep"
# Security critical → Always explicit listing
```

#### Step 2.2: Pattern Validation Rules
Validate each pattern against these criteria:

1. **Coverage Test**: Pattern matches all current dependencies in namespace
2. **Specificity Test**: Pattern doesn't capture unintended dependencies
3. **Future-Proof Test**: Pattern captures likely future additions
4. **Conflict Test**: Pattern doesn't overlap with higher-priority groups

### Phase 3: Implementation [REQUIRED]

#### Step 3.1: Configuration Structure Template
Update `.github/dependabot.yml` following this exact structure:

```yaml
version: 2
updates:
  # ===== SECURITY CRITICAL GROUPS (Priority 1) =====
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "03:00"
      timezone: "America/New_York"
    groups:
      # Group 1: Microsoft Security Dependencies
      microsoft-security:
        patterns:
          - "azure/login*"  # Authentication critical
          - "Azure/load-testing*"  # Infrastructure testing
        update-types:
          - "minor"
          - "patch"
      
      # Group 2: GitHub Core Actions
      github-core:
        patterns:
          - "actions/checkout*"  # Core workflow dependency
          - "actions/setup-*"     # Environment setup
          - "actions/upload-*"    # Artifact management
          - "actions/download-*"  # Artifact retrieval
        
  # ===== INFRASTRUCTURE GROUPS (Priority 2) =====
  - package-ecosystem: "terraform"
    directory: "/configurations"
    schedule:
      interval: "monthly"
    groups:
      # Group 3: Power Platform Providers
      power-platform:
        patterns:
          - "microsoft/power-platform*"
          - "Microsoft/terraform-provider-power*"
      
      # Group 4: Azure Providers
      azure-providers:
        patterns:
          - "hashicorp/azurerm*"
          - "hashicorp/azuread*"
          - "Azure/terraform-*"

  # ===== DEVELOPMENT TOOLS (Priority 3) =====
  - package-ecosystem: "docker"
    directory: "/.devcontainer"
    schedule:
      interval: "monthly"
    groups:
      # Group 5: Development Containers
      dev-containers:
        patterns:
          - "mcr.microsoft.com/devcontainers/*"
          - "ghcr.io/devcontainers/*"
```

#### Step 3.2: Documentation Requirements
Add inline documentation for each pattern:

```yaml
patterns:
  - "azure/*"  # Covers: azure/login, azure/CLI, azure/setup-kubectl
  - "microsoft/power-platform*"  # Current: power-platform v2, Future: power-platform-cli
```

### Phase 4: Validation [REQUIRED]

#### Step 4.1: Automated Validation Script
Create and run validation script:

```bash
#!/bin/bash
# filepath: scripts/validate-dependabot-patterns.sh

echo "Validating Dependabot patterns..."

# Test 1: YAML syntax
yamllint .github/dependabot.yml || exit 1

# Test 2: Pattern coverage
for dep in $(grep -h "uses:" .github/workflows/*.yml | sed 's/.*uses: *//' | sed 's/@.*//' | sort -u); do
  echo "Checking coverage for: $dep"
  # Verify dependency matches at least one pattern
done

# Test 3: No orphaned dependencies
echo "✅ All validations passed"
```

#### Step 4.2: Coverage Report
Generate coverage report showing:
- Total dependencies found: X
- Dependencies covered by patterns: Y
- Coverage percentage: Z%
- Ungrouped dependencies: [list]

## 🚫 Critical Constraints

### MUST NOT:
1. **Break existing workflows** - Preserve all current PR automation
2. **Create overlapping patterns** - Each dependency matches exactly one group
3. **Hardcode versions** - Patterns should be version-agnostic
4. **Mix security levels** - Keep security-critical deps in separate groups
5. **Exceed PR limits** - Respect `open-pull-requests-limit` settings

### MUST:
1. **Maintain priority order** - Security > Infrastructure > Development
2. **Document pattern rationale** - Explain why each pattern exists
3. **Test pattern matching** - Verify patterns work as intended
4. **Preserve scheduling** - Keep existing update schedules
5. **Follow naming conventions** - Use kebab-case for group names

## ✅ Success Metrics

### Quantitative Metrics:
- [ ] **100% dependency coverage** - All identified dependencies match a pattern
- [ ] **<20 total patterns** - Maintain manageable pattern count
- [ ] **0 pattern conflicts** - No overlapping patterns across groups
- [ ] **<5 minute execution** - Task completes efficiently

### Qualitative Metrics:
- [ ] **Clear pattern logic** - Each pattern's purpose is obvious
- [ ] **Future-proof design** - Patterns accommodate growth
- [ ] **Maintenance reduction** - Fewer manual updates needed
- [ ] **Documentation clarity** - Anyone can understand pattern choices

## 🎬 AI Agent Action Sequence

1. **START**: Acknowledge task and confirm understanding
2. **ANALYZE**: Run discovery commands and create dependency inventory
3. **DESIGN**: Generate patterns based on analysis matrix
4. **IMPLEMENT**: Update dependabot.yml with new patterns
5. **VALIDATE**: Run validation script and generate coverage report
6. **DOCUMENT**: Add inline comments explaining each pattern
7. **REPORT**: Provide summary of changes and coverage metrics
8. **END**: Confirm task completion and next steps

## 📝 Expected Deliverables

1. **Updated `.github/dependabot.yml`** with comprehensive patterns
2. **Validation script** at `scripts/validate-dependabot-patterns.sh`
3. **Coverage report** showing pattern effectiveness
4. **Change summary** listing all modifications made

## 🔍 Quality Checklist

Before marking complete, verify:
- [ ] All current dependencies have matching patterns
- [ ] Patterns are documented with examples
- [ ] YAML syntax is valid (passes yamllint)
- [ ] No duplicate or conflicting patterns exist
- [ ] Security dependencies remain prioritized
- [ ] Update schedules are preserved
- [ ] PR limits are respected
- [ ] Future dependencies are considered

## 💡 Pattern Examples Reference

### Effective Patterns:
```yaml
# Wildcard for namespace (catches all)
- "actions/*"

# Prefix matching (catches variations)
- "azure/login*"  # Matches: azure/login, azure/login-v2

# Explicit for security-critical
- "azure/login"  # Exact match only

# Registry prefix for containers
- "mcr.microsoft.com/devcontainers/*"
```

### Avoid These Patterns:
```yaml
# Too broad (catches unintended)
- "*"

# Version-specific (requires updates)
- "actions/checkout@v4"

# Redundant (already covered)
- "actions/checkout"  # If "actions/*" exists
```

---

**AI Agent Instructions**: Follow this guide systematically. Begin with Phase 1 discovery, proceed through each phase sequentially, and provide clear output at each step. Ask for clarification if any requirement is ambiguous. Focus on creating maintainable, comprehensive patterns that reduce future manual updates.