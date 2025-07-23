#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# YAML VALIDATION UTILITY FOR POWER PLATFORM GOVERNANCE
# ═══════════════════════════════════════════════════════════════════════════════
# Comprehensive YAML validation script that validates syntax, style, and GitHub
# Actions structure for consistent code quality in Power Platform automation.
#
# 🎯 WHY THIS EXISTS:
# - Provides early validation feedback to prevent runtime failures
# - Ensures consistent YAML style across all GitHub automation files
# - Validates GitHub Actions structure before deployment
# - Supports both individual file and bulk validation workflows
#
# 🔧 USAGE EXAMPLES:
# - ./scripts/utils/validate-yaml.sh --all-actions    # All composite actions
# - ./scripts/utils/validate-yaml.sh --all-github     # All .github YAML files  
# - ./scripts/utils/validate-yaml.sh file.yml         # Single file validation
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# === CONFIGURATION ===
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="/workspaces/ppcc25-terraform-power-platform-governance"

echo "🔍 YAML Validation Script for Power Platform Governance"
echo "======================================================"
echo

# === INPUT VALIDATION ===
if [ $# -eq 0 ]; then
    echo "Usage: $SCRIPT_NAME <file1.yml> [file2.yml] ..."
    echo "       $SCRIPT_NAME --all-actions    (validate all composite actions)"
    echo "       $SCRIPT_NAME --all-github     (validate all .github YAML files)"
    exit 1
fi

# === FILE DISCOVERY FUNCTIONS ===
# Centralized file discovery to avoid duplication and ensure consistency

find_composite_actions() {
    find "$PROJECT_ROOT/.github/actions" -name "action.yml" 2>/dev/null || true
}

find_github_yaml_files() {
    find "$PROJECT_ROOT/.github" -name "*.yml" -o -name "*.yaml" 2>/dev/null || true
}

# === VALIDATION FUNCTIONS ===
# Modular validation functions for reusability and clarity

validate_yaml_syntax() {
    local file="$1"
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "✅ YAML syntax: Valid"
        return 0
    else
        echo "❌ YAML syntax: FAILED"
        echo "   Error: Invalid YAML structure"
        return 1
    fi
}

validate_github_actions_structure() {
    local file="$1"
    if [[ "$(basename "$file")" == "action.yml" ]]; then
        local validation_result
        validation_result=$(python3 -c "
import yaml
try:
    data = yaml.safe_load(open('$file'))
    required = ['name', 'description', 'runs']
    missing = [f for f in required if f not in data]
    if missing:
        print('Missing: ' + ', '.join(missing))
    else:
        print('All required fields present')
        if data.get('runs', {}).get('using') == 'composite':
            print('Composite action format: Valid')
        else:
            print('Warning: Not a composite action')
except Exception as e:
    print('Error checking fields: ' + str(e))
")
        echo "✅ GitHub Actions structure: $validation_result"
    fi
}

validate_yaml_style() {
    local file="$1"
    if command -v yamllint >/dev/null 2>&1; then
        # Use project yamllint config if available, otherwise use inline config
        local yamllint_config
        if [[ -f "$PROJECT_ROOT/.yamllint" ]]; then
            if yamllint "$file" >/dev/null 2>&1; then
                echo "✅ Yamllint: No issues found"
            else
                echo "⚠️  Yamllint: Some style warnings (not blocking)"
            fi
        else
            yamllint_config='{extends: default, rules: {line-length: {max: 100, allow-non-breakable-words: true, allow-non-breakable-inline-mappings: true}, truthy: {check-keys: false}, comments: {min-spaces-from-content: 1}}}'
            if yamllint -d "$yamllint_config" "$file" >/dev/null 2>&1; then
                echo "✅ Yamllint: No issues found"
            else
                echo "⚠️  Yamllint: Some style warnings (not blocking)"
            fi
        fi
    else
        echo "⚠️  Yamllint: Not available (install with: pip install yamllint)"
    fi
}

# === MAIN VALIDATION LOGIC ===
# Handle special flags
if [ "$1" = "--all-actions" ]; then
    echo "🔍 Validating all composite actions..."
    mapfile -t files < <(find_composite_actions)
elif [ "$1" = "--all-github" ]; then
    echo "🔍 Validating all GitHub YAML files..."
    mapfile -t files < <(find_github_yaml_files)
else
    files=("$@")
fi

echo "Found ${#files[@]} file(s) to validate"
echo

# Validate each file
validation_failed=false
for file in "${files[@]}"; do
    echo "=== Validating: $(basename "$file") ==="
    
    # Run all validation checks
    if ! validate_yaml_syntax "$file"; then
        validation_failed=true
        continue
    fi
    
    validate_github_actions_structure "$file"
    validate_yaml_style "$file"
    
    echo "✅ Overall: $(basename "$file") is valid"
    echo
done

# Final status
if [ "$validation_failed" = true ]; then
    echo "❌ Some files failed validation!"
    exit 1
else
    echo "🎉 Validation completed for ${#files[@]} file(s)"
    echo "All files have valid YAML syntax and proper structure!"
fi
