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
# - NOW: Auto-remediation capabilities for common formatting issues
#
# 🔧 USAGE EXAMPLES:
# - ./scripts/utils/validate-yaml.sh --all-actions    # All composite actions
# - ./scripts/utils/validate-yaml.sh --all-github     # All .github YAML files  
# - ./scripts/utils/validate-yaml.sh file.yml         # Single file validation
# - ./scripts/utils/validate-yaml.sh --autofix --all-github  # Auto-fix all GitHub YAML files
# - ./scripts/utils/validate-yaml.sh --all-github --autofix  # Auto-fix (flexible order)
# - ./scripts/utils/validate-yaml.sh --autofix file.yml      # Auto-fix specific file
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# === CONFIGURATION ===
readonly SCRIPT_NAME="$(basename "$0")"
# Dynamically determine project root - works in both dev container and CI
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# === AUTO-FIX FLAGS ===
AUTOFIX_ENABLED=false
AUTOFIX_APPLIED=false

echo "🔍 YAML Validation Script for Power Platform Governance"
echo "======================================================"
echo "📂 Project root: $PROJECT_ROOT"
echo

# === ENHANCED INPUT VALIDATION ===
if [ $# -eq 0 ]; then
    echo "Usage: $SCRIPT_NAME [OPTIONS] <file1.yml> [file2.yml] ..."
    echo ""
    echo "OPTIONS:"
    echo "  --autofix              Apply automatic fixes to common YAML issues"
    echo "  --all-actions          Validate all composite actions"
    echo "  --all-github           Validate all .github YAML files"
    echo ""
    echo "EXAMPLES:"
    echo "  $SCRIPT_NAME --all-github                    # Validate only"
    echo "  $SCRIPT_NAME --autofix --all-github          # Validate and auto-fix"
    echo "  $SCRIPT_NAME --all-github --autofix          # Validate and auto-fix (flexible order)"
    echo "  $SCRIPT_NAME --autofix file.yml              # Auto-fix specific file"
    exit 1
fi

# === FILE DISCOVERY FUNCTIONS ===
# Keep the exact working functions with proper stderr handling

find_composite_actions() {
    echo "🔍 Looking for composite actions in: $PROJECT_ROOT/.github/actions" >&2
    local files
    files=$(find "$PROJECT_ROOT/.github/actions" -name "action.yml" 2>/dev/null || true)
    if [ -n "$files" ]; then
        echo "$files"
    else
        echo "⚠️  No action.yml files found in $PROJECT_ROOT/.github/actions" >&2
        echo "📁 Directory structure:" >&2
        ls -la "$PROJECT_ROOT/.github/actions" 2>/dev/null || echo "Directory does not exist" >&2
    fi
}

find_github_yaml_files() {
    echo "🔍 Looking for YAML files in: $PROJECT_ROOT/.github" >&2
    local files
    files=$(find "$PROJECT_ROOT/.github" -name "*.yml" -o -name "*.yaml" 2>/dev/null || true)
    if [ -n "$files" ]; then
        echo "$files"
    else
        echo "⚠️  No YAML files found in $PROJECT_ROOT/.github" >&2
        echo "📁 Directory structure:" >&2
        ls -la "$PROJECT_ROOT/.github" 2>/dev/null || echo "Directory does not exist" >&2
    fi
}

# === AUTO-FIX FUNCTIONS ===
apply_yaml_autofix() {
    local file="$1"
    local fixes_applied=false
    
    echo "🛠️  Applying auto-fixes to: $(basename "$file")" >&2
    
    # Backup original file
    cp "$file" "${file}.backup"
    
    # Fix 1: Ensure document start marker
    if ! grep -q "^---" "$file"; then
        echo "  ✨ Adding document start marker (---)" >&2
        sed -i '1i---' "$file"
        fixes_applied=true
    fi
    
    # Fix 2: Fix common indentation issues (if yamlfixer is available)
    if command -v yamlfixer >/dev/null 2>&1; then
        echo "  ✨ Running yamlfixer for style improvements" >&2
        if yamlfixer --config-file "$PROJECT_ROOT/.yamllint" "$file" 2>/dev/null; then
            fixes_applied=true
        fi
    else
        # Manual fixes for common issues
        echo "  ✨ Applying manual formatting fixes" >&2
        
        # Fix trailing whitespace
        if sed -i 's/[[:space:]]*$//' "$file"; then
            fixes_applied=true
        fi
        
        # Ensure file ends with newline
        if [ -n "$(tail -c1 "$file")" ]; then
            echo >> "$file"
            fixes_applied=true
        fi
    fi
    
    # Fix 3: Validate and report if fixes were successful
    if [ "$fixes_applied" = true ]; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo "  ✅ Auto-fixes applied successfully" >&2
            rm "${file}.backup"  # Remove backup on success
            AUTOFIX_APPLIED=true
            return 0
        else
            echo "  ❌ Auto-fixes caused syntax errors, reverting" >&2
            mv "${file}.backup" "$file"
            return 1
        fi
    else
        echo "  ℹ️  No fixes needed" >&2
        rm "${file}.backup"
        return 0
    fi
}

# === VALIDATION FUNCTIONS ===
validate_yaml_syntax() {
    local file="$1"
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "✅ YAML syntax: Valid"
        return 0
    else
        echo "❌ YAML syntax: FAILED"
        echo "   Error: Invalid YAML structure"
        
        # Offer auto-fix if enabled
        if [ "$AUTOFIX_ENABLED" = true ]; then
            echo "   🛠️  Attempting auto-fix..."
            if apply_yaml_autofix "$file"; then
                echo "   ✅ Auto-fix successful, re-validating..."
                # Re-validate after fix
                if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                    echo "✅ YAML syntax: Valid (after auto-fix)"
                    return 0
                else
                    echo "❌ YAML syntax: Still invalid after auto-fix"
                    return 1
                fi
            else
                echo "   ❌ Auto-fix failed"
                return 1
            fi
        fi
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
        if [[ -f "$PROJECT_ROOT/.yamllint" ]]; then
            if yamllint "$file" >/dev/null 2>&1; then
                echo "✅ Yamllint: No issues found"
                return 0
            else
                echo "⚠️  Yamllint: Some style warnings found"
                
                # Apply auto-fix if enabled
                if [ "$AUTOFIX_ENABLED" = true ]; then
                    echo "   🛠️  Attempting style auto-fix..."
                    if apply_yaml_autofix "$file"; then
                        # Re-validate style after fix
                        if yamllint "$file" >/dev/null 2>&1; then
                            echo "✅ Yamllint: Fixed (after auto-fix)"
                            return 0
                        else
                            echo "⚠️  Yamllint: Some issues remain after auto-fix (not blocking)"
                            return 0
                        fi
                    else
                        echo "   ❌ Style auto-fix failed (not blocking)"
                        return 0
                    fi
                else
                    echo "   💡 Run with --autofix to automatically fix style issues"
                    return 0
                fi
            fi
        else
            local yamllint_config='{extends: default, rules: {line-length: {max: 100, allow-non-breakable-words: true, allow-non-breakable-inline-mappings: true}, truthy: {check-keys: false}, comments: {min-spaces-from-content: 1}}}'
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

# === ENHANCED ARGUMENT PARSING ===
# Parse arguments properly to handle --autofix in any position

# Initialize variables
target_flag=""
files=()

# Process all arguments to find flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --autofix)
            AUTOFIX_ENABLED=true
            echo "🛠️  Auto-fix mode enabled"
            shift
            ;;
        --all-actions)
            if [[ -n "$target_flag" ]]; then
                echo "❌ Cannot specify multiple target flags"
                exit 1
            fi
            target_flag="--all-actions"
            shift
            ;;
        --all-github)
            if [[ -n "$target_flag" ]]; then
                echo "❌ Cannot specify multiple target flags"
                exit 1
            fi
            target_flag="--all-github"
            shift
            ;;
        -*)
            echo "❌ Unknown option: $1"
            exit 1
            ;;
        *)
            # Individual files
            files+=("$1")
            shift
            ;;
    esac
done

# Handle the target flag and populate files array
if [[ "$target_flag" == "--all-actions" ]]; then
    echo "🔍 Validating all composite actions..."
    mapfile -t files < <(find_composite_actions)
elif [[ "$target_flag" == "--all-github" ]]; then
    echo "🔍 Validating all GitHub YAML files..."
    mapfile -t files < <(find_github_yaml_files)
elif [[ ${#files[@]} -eq 0 ]]; then
    echo "❌ No files specified for validation"
    echo "Use --all-actions, --all-github, or specify individual files"
    exit 1
fi

echo "Found ${#files[@]} file(s) to validate"
if [ "$AUTOFIX_ENABLED" = true ]; then
    echo "🛠️  Auto-fix mode is ENABLED"
fi
echo

# === VALIDATION LOOP ===
validation_failed=false
files_processed=0

for file in "${files[@]}"; do
    # Skip empty lines or invalid files
    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "⚠️  Skipping invalid file: $file" >&2
        continue
    fi
    
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
    files_processed=$((files_processed + 1))
done

# === FINAL STATUS REPORT ===
echo "📊 Processing Summary"
echo "===================="
echo "Files processed: $files_processed"

if [ "$AUTOFIX_ENABLED" = true ]; then
    if [ "$AUTOFIX_APPLIED" = true ]; then
        echo "🛠️  Auto-fixes applied: YES"
        echo "💡 Tip: Review the changes and commit if satisfied"
        echo "📝 Use 'git diff' to see what was changed"
    else
        echo "🛠️  Auto-fixes applied: NO (no fixes needed)"
    fi
fi

if [ "$validation_failed" = true ]; then
    echo "❌ Some files failed validation!"
    if [ "$AUTOFIX_ENABLED" = false ]; then
        echo "💡 Tip: Run with --autofix to automatically fix common issues"
        echo "Example: $SCRIPT_NAME --autofix --all-github"
    fi
    exit 1
else
    echo "🎉 All files validated successfully!"
    if [ "$AUTOFIX_APPLIED" = true ]; then
        echo "✨ Auto-fixes were applied - please review and commit changes"
    fi
fi