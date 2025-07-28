run_enhanced_autofix() {
    local config_path="$1"
    local config_name="$2"
    cd "$config_path"

    # Fix 1: Replace concat() in ignore_changes blocks (legacy, for future-proofing)
    if [[ -f "main.tf" ]] && grep -q "ignore_changes = concat(" main.tf; then
        print_warning "Fixing concat() usage in ignore_changes..."
        sed -i 's/ignore_changes = concat(/ignore_changes = [/g' main.tf
        # Remove closing parenthesis and complex logic (manual review may be needed)
    fi

    # Fix 2: Generate missing outputs.tf
    if [[ ! -f "outputs.tf" ]]; then
        print_warning "Generating missing outputs.tf..."
        cat > outputs.tf << 'EOF'
output "id" {
  description = "The ID of the created resource"
  value       = try(resource.main.id, null)
}
EOF
    fi

    # Fix 3: Update provider version in versions.tf
    if [[ -f "versions.tf" ]] && ! grep -q '~> 3.8' versions.tf; then
        print_warning "Updating provider version in versions.tf..."
        sed -i 's/version = "[^"]*"/version = "~> 3.8"/g' versions.tf
    fi

    # Fix 4: Add .terraform-docs.yml if missing
    if [[ ! -f ".terraform-docs.yml" ]]; then
        print_warning "Generating missing .terraform-docs.yml..."
        cat > .terraform-docs.yml << 'EOF'
output: markdown
output-file: README.md
sections:
  hide:
    - requirements
    - providers
    - modules
    - resources
    - inputs
    - outputs
EOF
    fi

    # Fix 5: Add lifecycle block for res-* modules if missing
    if [[ "$config_name" == res-* ]] && [[ -f "main.tf" ]] && ! grep -q 'lifecycle' main.tf; then
        print_warning "Adding lifecycle block to main.tf..."
        echo -e '\n  lifecycle {\n    ignore_changes = []\n  }' >> main.tf
    fi
}
#!/bin/bash
# ============================================================================== 
# TERRAFORM LOCAL VALIDATION SCRIPT
# ============================================================================== 
# Provides fast, local validation and autofix capabilities for Terraform configurations
# Eliminates the pain of CI/CD feedback loops by running comprehensive checks locally
#
# 🎯 WHY THIS EXISTS:
# - Enables rapid, local validation without waiting for CI/CD pipelines
# - Provides autofix capabilities to resolve common formatting and structure issues
# - Supports both single configuration and bulk validation across all configurations
# - Mirrors the exact validation logic from terraform-single-path-validation.yml workflow
#
# 🔧 CAPABILITIES:
# - Format checking with automatic formatting fixes
# - Syntax validation with detailed error reporting
# - AVM compliance checking with clear guidance (future enhancement)
# - Parallel execution for performance at scale (future enhancement)
# - Progress tracking and comprehensive reporting
#
# 📋 USAGE:
# ./scripts/utils/terraform-local-validation.sh [OPTIONS] [CONFIGURATION_PATHS...]
#
# OPTIONS:
#   --autofix          Apply automatic fixes where possible (format)
#   --format-only      Only run format checks (faster for quick feedback)
#   --syntax-only      Only run syntax validation
#   --quiet            Suppress verbose output, show only errors and summary
#   --help             Show this help message
#
# EXAMPLES:
#   # Validate all configurations with autofix
#   ./scripts/utils/terraform-local-validation.sh --autofix
#
#   # Validate specific configuration
#   ./scripts/utils/terraform-local-validation.sh res-dlp-policy
#
#   # Quick format check with autofix
#   ./scripts/utils/terraform-local-validation.sh --format-only --autofix
# ==============================================================================

set -e
set -u

# Source utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/common.sh"

readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly CONFIGURATIONS_DIR="$REPO_ROOT/configurations"
readonly SCRIPT_NAME="Terraform Local Validation"

AUTOFIX=false
FORMAT_ONLY=false
SYNTAX_ONLY=false
QUIET=false

PASSED_CONFIGS=()
FAILED_CONFIGS=()

show_help() {
    print_banner "Terraform Local Validation Script"
    echo ""
    echo "DESCRIPTION:"
    echo "  Fast, local validation and autofix for Terraform configurations."
    echo "  Eliminates CI/CD feedback loops by running comprehensive checks locally."
    echo ""
    echo "USAGE:"
    echo "  $0 [OPTIONS] [CONFIGURATION_PATHS...]"
    echo ""
    echo "OPTIONS:"
    echo "  --autofix          Apply automatic fixes where possible"
    echo "  --format-only      Only run format checks"
    echo "  --syntax-only      Only run syntax validation"
    echo "  --quiet            Suppress verbose output"
    echo "  --help             Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  # Validate all configurations with autofix"
    echo "  $0 --autofix"
    echo ""
    echo "  # Validate specific configuration"
    echo "  $0 res-dlp-policy"
    echo ""
    echo "  # Quick format check with autofix"
    echo "  $0 --format-only --autofix"
    echo ""
    exit 0
}

validate_prerequisites() {
    local missing_tools=()
    print_check "Validating prerequisites..."
    if ! command -v terraform >/dev/null 2>&1; then
        missing_tools+=("terraform")
    fi
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install the missing tools and try again."
        exit 1
    fi
    print_success "All prerequisites validated"
}

discover_configurations() {
    local discovered_configs=()
    print_check "Discovering Terraform configurations..."
    while IFS= read -r -d '' config_dir; do
        local config_name=$(basename "$config_dir")
        if [[ -f "$config_dir/main.tf" ]]; then
            discovered_configs+=("$config_name")
        fi
    done < <(find "$CONFIGURATIONS_DIR" -maxdepth 1 -type d -print0)
    if [[ ${#discovered_configs[@]} -eq 0 ]]; then
        print_error "No Terraform configurations found in $CONFIGURATIONS_DIR"
        exit 1
    fi
    print_success "Found ${#discovered_configs[@]} configurations: ${discovered_configs[*]}"
    echo "${discovered_configs[@]}"
}

run_format_check() {
    local config_path="$1"
    local config_name="$2"
    local apply_autofix="$3"
    if [[ "$QUIET" != "true" ]]; then
        print_step "Running format check for $config_name..."
    fi
    cd "$config_path"
    local format_check_output
    local format_exit_code=0
    format_check_output=$(terraform fmt -recursive -check -diff 2>&1) || format_exit_code=$?
    if [[ $format_exit_code -eq 0 ]]; then
        if [[ "$QUIET" != "true" ]]; then
            print_success "Format check passed for $config_name"
        fi
        return 0
    else
        if [[ "$apply_autofix" == "true" ]]; then
            if [[ "$QUIET" != "true" ]]; then
                print_warning "Format issues found in $config_name. Applying autofix..."
            fi
            # Apply the formatting fix and capture output
            local format_fix_output
            format_fix_output=$(terraform fmt -recursive 2>&1)
            # Verify the fix was successful by checking again
            if terraform fmt -recursive -check >/dev/null 2>&1; then
                print_success "✨ Autofix applied successfully for $config_name format"
                return 0
            else
                print_error "Autofix failed for $config_name format"
                if [[ "$QUIET" != "true" ]]; then
                    echo "Fix output: $format_fix_output"
                fi
                return 1
            fi
        else
            if [[ "$QUIET" != "true" ]]; then
                print_error "Format issues found in $config_name:"
                echo "$format_check_output"
                print_status "💡 Run with --autofix to automatically fix formatting issues"
            fi
            return 1
        fi
    fi
}

run_syntax_validation() {
    local config_path="$1"
    local config_name="$2"
    if [[ "$QUIET" != "true" ]]; then
        print_step "Running syntax validation for $config_name..."
    fi
    cd "$config_path"
    if ! find . -maxdepth 1 -name "*.tf" -type f | grep -q .; then
        if [[ "$QUIET" != "true" ]]; then
            print_warning "No Terraform files found in $config_name, skipping syntax validation"
        fi
        return 0
    fi
    local init_output
    local init_exit_code=0
    init_output=$(terraform init -backend=false -input=false 2>&1) || init_exit_code=$?
    if [[ $init_exit_code -ne 0 ]]; then
        if [[ "$QUIET" != "true" ]]; then
            print_error "Terraform init failed for $config_name:"
            echo "$init_output"
        fi
        return 1
    fi
    local validate_output
    local validate_exit_code=0
    validate_output=$(terraform validate 2>&1) || validate_exit_code=$?
    if [[ $validate_exit_code -eq 0 ]]; then
        if [[ "$QUIET" != "true" ]]; then
            print_success "Syntax validation passed for $config_name"
        fi
        return 0
    else
        if [[ "$QUIET" != "true" ]]; then
            print_error "Syntax validation failed for $config_name:"
            echo "$validate_output"
            # Provide specific guidance for common issues
            if echo "$validate_output" | grep -q "static list expression is required"; then
                print_status "💡 Tip: ignore_changes requires a static list. Remove concat() or conditional expressions."
            elif echo "$validate_output" | grep -q "Invalid expression"; then
                print_status "💡 Tip: Check for invalid function usage in expressions."
            fi
        fi
        return 1
    fi
}

validate_configuration() {
    local config_name="$1"
    local config_path="$CONFIGURATIONS_DIR/$config_name"
    if [[ ! -d "$config_path" ]]; then
        print_error "Configuration directory not found: $config_path"
        FAILED_CONFIGS+=("$config_name")
        return 1
    fi
    if [[ "$QUIET" != "true" ]]; then
        print_header "Validating configuration: $config_name"
    fi
    local validation_passed=true
    if [[ "$SYNTAX_ONLY" != "true" ]]; then
        if ! run_format_check "$config_path" "$config_name" "$AUTOFIX"; then
            validation_passed=false
            # Enhanced autofix: try to fix common issues if autofix is enabled
            if [[ "$AUTOFIX" == "true" ]]; then
                print_warning "Running enhanced autofix for $config_name..."
                run_enhanced_autofix "$config_path" "$config_name"
                # Re-run format check after autofix
                if run_format_check "$config_path" "$config_name" "false"; then
                    print_success "Enhanced autofix resolved format issues for $config_name."
                else
                    print_error "Enhanced autofix could not resolve all format issues for $config_name."
                fi
            fi
        fi
    fi
    if [[ "$FORMAT_ONLY" != "true" ]]; then
        if ! run_syntax_validation "$config_path" "$config_name"; then
            validation_passed=false
        fi
    fi
    if [[ "$validation_passed" == "true" ]]; then
        PASSED_CONFIGS+=("$config_name")
        if [[ "$QUIET" != "true" ]]; then
            print_success "✅ All checks passed for $config_name"
        fi
    else
        FAILED_CONFIGS+=("$config_name")
        if [[ "$QUIET" != "true" ]]; then
            print_error "❌ Validation failed for $config_name"
        fi
    fi
    echo ""
    return $([[ "$validation_passed" == "true" ]] && echo 0 || echo 1)
}

generate_validation_report() {
    print_banner "🔍 VALIDATION REPORT"
    echo ""
    local total_configs=$((${#PASSED_CONFIGS[@]} + ${#FAILED_CONFIGS[@]}))
    local passed_count=${#PASSED_CONFIGS[@]}
    local failed_count=${#FAILED_CONFIGS[@]}
    print_header "Summary Statistics"
    print_status "Total configurations validated: $total_configs"
    print_success "Passed: $passed_count"
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed: $failed_count"
    else
        print_status "Failed: $failed_count"
    fi
    echo ""
    if [[ ${#PASSED_CONFIGS[@]} -gt 0 ]]; then
        print_header "✅ Passed Configurations"
        for config in "${PASSED_CONFIGS[@]}"; do
            print_success "  $config"
        done
        echo ""
    fi
    if [[ ${#FAILED_CONFIGS[@]} -gt 0 ]]; then
        print_header "❌ Failed Configurations"
        for config in "${FAILED_CONFIGS[@]}"; do
            print_error "  $config"
        done
        echo ""
        print_header "💡 Recommendations"
        print_status "• Run with --autofix to automatically resolve formatting issues"
        print_status "• Run individual configurations for more detailed error output"
    else
        print_status "• All configurations are valid! 🎉"
    fi
    echo ""
}

parse_arguments() {
    local configs_to_validate=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --autofix)
                AUTOFIX=true
                shift
                ;;
            --format-only)
                FORMAT_ONLY=true
                shift
                ;;
            --syntax-only)
                SYNTAX_ONLY=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                configs_to_validate+=("$1")
                shift
                ;;
        esac
    done
    if [[ "$FORMAT_ONLY" == "true" && "$SYNTAX_ONLY" == "true" ]]; then
        print_error "Options --format-only and --syntax-only are mutually exclusive"
        exit 1
    fi
    if [[ ${#configs_to_validate[@]} -eq 0 ]]; then
        readarray -t configs_to_validate <<< "$(discover_configurations)"
    fi
    echo "${configs_to_validate[@]}"
}

main() {
    local configurations
    readarray -t configurations <<< "$(parse_arguments "$@")"
    validate_prerequisites
    for config in "${configurations[@]}"; do
        validate_configuration "$config"
    done
    generate_validation_report
    if [[ ${#FAILED_CONFIGS[@]} -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
