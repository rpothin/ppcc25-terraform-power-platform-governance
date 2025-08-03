#!/bin/bash
# ============================================================================== 
# TERRAFORM LOCAL VALIDATION SCRIPT - ENHANCED WITH COMPREHENSIVE AUTOFIX
# ============================================================================== 
# Provides fast, local validation and autofix capabilities for Terraform configurations
# Inspired by validate-yaml.sh autofix patterns for comprehensive remediation
#
# 🎯 ENHANCED FEATURES:
# - Comprehensive terraform fmt autofix with backup/restore
# - Intelligent terraform validate autofix for common syntax issues
# - Progressive fix application with validation at each step
# - Detailed reporting of fixes applied
# - Safe rollback on autofix failures
#
# 🔧 CAPABILITIES:
# - Format checking with automatic formatting fixes
# - Syntax validation with intelligent autofix for common issues
# - Provider configuration fixes
# - Missing file generation (outputs.tf, variables.tf, etc.)
# - Legacy syntax remediation (concat(), deprecated functions)
# - AVM compliance fixes
#
# 📋 USAGE:
# ./scripts/utils/terraform-local-validation.sh [OPTIONS] [CONFIGURATION_PATHS...]
#
# OPTIONS:
#   --autofix          Apply automatic fixes where possible
#   --format-only      Only run format checks with autofix
#   --syntax-only      Only run syntax validation with autofix
#   --quiet            Suppress verbose output
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

set -euo pipefail

# Source utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/common.sh"

readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly CONFIGURATIONS_DIR="$REPO_ROOT/configurations"
readonly SCRIPT_NAME="Terraform Local Validation"

# Global flags - Initialize before any output
AUTOFIX=false
FORMAT_ONLY=false
SYNTAX_ONLY=false
QUIET=false
AUTOFIX_APPLIED=false

# Results tracking
PASSED_CONFIGS=()
FAILED_CONFIGS=()

# === ENHANCED AUTOFIX FUNCTIONS ===

apply_terraform_format_autofix() {
    local config_path="$1"
    local config_name="$2"
    local fixes_applied=false
    
    if [[ "$QUIET" != "true" ]]; then
        echo "🛠️  Applying format auto-fixes to: $config_name" >&2
    fi
    
    cd "$config_path"
    
    # Create backup of all .tf and .tfvars files
    local backup_dir="${config_path}/.terraform-backup-$$"
    mkdir -p "$backup_dir"
    
    # Backup all relevant files
    if ls *.tf >/dev/null 2>&1; then
        cp *.tf "$backup_dir/" 2>/dev/null || true
    fi
    if ls *.tfvars >/dev/null 2>&1; then
        cp *.tfvars "$backup_dir/" 2>/dev/null || true
    fi
    if ls tfvars/*.tfvars >/dev/null 2>&1; then
        mkdir -p "$backup_dir/tfvars"
        cp tfvars/*.tfvars "$backup_dir/tfvars/" 2>/dev/null || true
    fi
    
    # Apply terraform fmt recursively
    if terraform fmt -recursive . >/dev/null 2>&1; then
        # Check if any changes were made by comparing with backup
        if ! diff -r "$backup_dir" . >/dev/null 2>&1; then
            fixes_applied=true
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✨ Applied terraform fmt formatting" >&2
            fi
        fi
    fi
    
    # Verify formatting was successful
    if terraform fmt -recursive -check . >/dev/null 2>&1; then
        if [[ "$fixes_applied" == "true" ]]; then
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✅ Format auto-fixes applied successfully" >&2
            fi
            rm -rf "$backup_dir"
            AUTOFIX_APPLIED=true
            return 0
        else
            if [[ "$QUIET" != "true" ]]; then
                echo "  ℹ️  No format fixes needed" >&2
            fi
            rm -rf "$backup_dir"
            return 0
        fi
    else
        if [[ "$QUIET" != "true" ]]; then
            echo "  ❌ Format auto-fixes caused issues, reverting" >&2
        fi
        # Restore from backup
        if [[ -d "$backup_dir" ]]; then
            cp "$backup_dir"/*.tf . 2>/dev/null || true
            cp "$backup_dir"/*.tfvars . 2>/dev/null || true
            if [[ -d "$backup_dir/tfvars" ]]; then
                cp "$backup_dir/tfvars"/*.tfvars tfvars/ 2>/dev/null || true
            fi
        fi
        rm -rf "$backup_dir"
        return 1
    fi
}

apply_terraform_syntax_autofix() {
    local config_path="$1"
    local config_name="$2"
    local fixes_applied=false
    
    if [[ "$QUIET" != "true" ]]; then
        echo "🛠️  Applying syntax auto-fixes to: $config_name" >&2
    fi
    
    cd "$config_path"
    
    # Create comprehensive backup
    local backup_dir="${config_path}/.terraform-syntax-backup-$$"
    mkdir -p "$backup_dir"
    
    # Backup all relevant files
    if ls *.tf >/dev/null 2>&1; then
        cp *.tf "$backup_dir/" 2>/dev/null || true
    fi
    
    # Get current validation errors to understand what to fix
    local validation_output
    if ! validation_output=$(terraform validate 2>&1); then
        
        # Fix 1: concat() in ignore_changes (common validation error)
        if echo "$validation_output" | grep -q "static list expression is required"; then
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✨ Fixing concat() usage in ignore_changes blocks" >&2
            fi
            
            # Find and fix concat() in ignore_changes
            for tf_file in *.tf; do
                if [[ -f "$tf_file" ]] && grep -q "ignore_changes.*concat(" "$tf_file"; then
                    # More sophisticated replacement
                    sed -i 's/ignore_changes = concat(\([^,]*\), \([^)]*\))/ignore_changes = [\1, \2]/g' "$tf_file"
                    sed -i 's/ignore_changes = concat(\([^)]*\))/ignore_changes = [\1]/g' "$tf_file"
                    fixes_applied=true
                fi
            done
        fi
        
        # Fix 2: Invalid function usage
        if echo "$validation_output" | grep -q "Invalid function"; then
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✨ Fixing deprecated function usage" >&2
            fi
            
            # Fix common deprecated functions
            for tf_file in *.tf; do
                if [[ -f "$tf_file" ]]; then
                    # Replace list() with []
                    if sed -i 's/list(/[/g; s/)/]/g' "$tf_file" 2>/dev/null; then
                        fixes_applied=true
                    fi
                    # Replace map() with {}
                    if sed -i 's/map(/{\n/g' "$tf_file" 2>/dev/null; then
                        fixes_applied=true
                    fi
                fi
            done
        fi
        
        # Fix 3: Missing required providers
        if echo "$validation_output" | grep -q "provider.*is required"; then
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✨ Adding missing provider configuration" >&2
            fi
            
            # Generate versions.tf if missing
            if [[ ! -f "versions.tf" ]]; then
                cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.9"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
EOF
                fixes_applied=true
            fi
        fi
        
        # Fix 4: Missing variable declarations
        if echo "$validation_output" | grep -q "variable.*is not declared"; then
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✨ Generating missing variable declarations" >&2
            fi
            
            # Extract undefined variables and create basic declarations
            local undefined_vars
            undefined_vars=$(echo "$validation_output" | grep -o 'variable "[^"]*"' | sed 's/variable "\([^"]*\)"/\1/' | sort -u)
            
            if [[ -n "$undefined_vars" && ! -f "variables.tf" ]]; then
                echo "# Auto-generated variable declarations" > variables.tf
                while read -r var_name; do
                    if [[ -n "$var_name" ]]; then
                        cat >> variables.tf << EOF

variable "$var_name" {
  description = "Auto-generated variable declaration for $var_name"
  type        = string
  default     = null
}
EOF
                        fixes_applied=true
                    fi
                done <<< "$undefined_vars"
            fi
        fi
        
        # Fix 5: Missing outputs.tf (AVM compliance)
        if [[ ! -f "outputs.tf" ]]; then
            if [[ "$QUIET" != "true" ]]; then
                echo "  ✨ Generating missing outputs.tf for AVM compliance" >&2
            fi
            
            cat > outputs.tf << 'EOF'
# Auto-generated outputs for AVM compliance
output "id" {
  description = "The resource ID of the created resource"
  value       = try(local.resource_id, null)
}

output "name" {
  description = "The name of the created resource"
  value       = try(local.resource_name, null)
}
EOF
            fixes_applied=true
        fi
    fi
    
    # Verify fixes were successful
    if [[ "$fixes_applied" == "true" ]]; then
        # Re-initialize and validate
        if terraform init -backend=false -input=false >/dev/null 2>&1; then
            if terraform validate >/dev/null 2>&1; then
                if [[ "$QUIET" != "true" ]]; then
                    echo "  ✅ Syntax auto-fixes applied successfully" >&2
                fi
                rm -rf "$backup_dir"
                AUTOFIX_APPLIED=true
                return 0
            else
                if [[ "$QUIET" != "true" ]]; then
                    echo "  ❌ Syntax auto-fixes caused validation errors, reverting" >&2
                fi
                # Restore from backup
                cp "$backup_dir"/*.tf . 2>/dev/null || true
                rm -rf "$backup_dir"
                return 1
            fi
        else
            if [[ "$QUIET" != "true" ]]; then
                echo "  ❌ Terraform init failed after auto-fixes, reverting" >&2
            fi
            # Restore from backup
            cp "$backup_dir"/*.tf . 2>/dev/null || true
            rm -rf "$backup_dir"
            return 1
        fi
    else
        if [[ "$QUIET" != "true" ]]; then
            echo "  ℹ️  No syntax fixes applied" >&2
        fi
        rm -rf "$backup_dir"
        return 0
    fi
}

# === HELP FUNCTION ===
show_help() {
    echo "=============================================================================="
    echo "TERRAFORM LOCAL VALIDATION SCRIPT - ENHANCED WITH COMPREHENSIVE AUTOFIX"
    echo "=============================================================================="
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

# === PREREQUISITE VALIDATION ===
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

# === CONFIGURATION DISCOVERY ===
discover_configurations() {
    local discovered_configs=()
    print_check "Discovering Terraform configurations..."
    
    if [[ ! -d "$CONFIGURATIONS_DIR" ]]; then
        print_error "Configurations directory not found: $CONFIGURATIONS_DIR"
        exit 1
    fi
    
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

# === ENHANCED FORMAT CHECK ===
run_format_check() {
    local config_path="$1"
    local config_name="$2"
    local apply_autofix="$3"
    
    if [[ "$QUIET" != "true" ]]; then
        print_step "Running format check for $config_name..."
    fi
    
    cd "$config_path"
    
    # Check current format status
    if terraform fmt -recursive -check . >/dev/null 2>&1; then
        if [[ "$QUIET" != "true" ]]; then
            print_success "Format check passed for $config_name"
        fi
        return 0
    else
        if [[ "$apply_autofix" == "true" ]]; then
            if [[ "$QUIET" != "true" ]]; then
                print_warning "Format issues found in $config_name. Applying autofix..."
            fi
            
            if apply_terraform_format_autofix "$config_path" "$config_name"; then
                print_success "✨ Format autofix successful for $config_name"
                return 0
            else
                print_error "❌ Format autofix failed for $config_name"
                return 1
            fi
        else
            if [[ "$QUIET" != "true" ]]; then
                local format_check_output
                format_check_output=$(terraform fmt -recursive -check -diff . 2>&1) || true
                print_error "Format issues found in $config_name:"
                echo "$format_check_output"
                print_status "💡 Run with --autofix to automatically fix formatting issues"
            fi
            return 1
        fi
    fi
}

# === ENHANCED SYNTAX VALIDATION ===
run_syntax_validation() {
    local config_path="$1"
    local config_name="$2"
    local apply_autofix="$3"
    
    if [[ "$QUIET" != "true" ]]; then
        print_step "Running syntax validation for $config_name..."
    fi
    
    cd "$config_path"
    
    # Skip if no .tf files
    if ! find . -maxdepth 1 -name "*.tf" -type f | grep -q .; then
        if [[ "$QUIET" != "true" ]]; then
            print_warning "No Terraform files found in $config_name, skipping syntax validation"
        fi
        return 0
    fi
    
    # Initialize terraform
    if ! terraform init -backend=false -input=false >/dev/null 2>&1; then
        if [[ "$QUIET" != "true" ]]; then
            print_error "Terraform init failed for $config_name"
        fi
        return 1
    fi
    
    # Run validation
    if terraform validate >/dev/null 2>&1; then
        if [[ "$QUIET" != "true" ]]; then
            print_success "Syntax validation passed for $config_name"
        fi
        return 0
    else
        if [[ "$apply_autofix" == "true" ]]; then
            if [[ "$QUIET" != "true" ]]; then
                print_warning "Syntax issues found in $config_name. Applying autofix..."
            fi
            
            if apply_terraform_syntax_autofix "$config_path" "$config_name"; then
                print_success "✨ Syntax autofix successful for $config_name"
                return 0
            else
                print_error "❌ Syntax autofix failed for $config_name"
                return 1
            fi
        else
            if [[ "$QUIET" != "true" ]]; then
                local validation_output
                validation_output=$(terraform validate 2>&1)
                print_error "Syntax validation failed for $config_name:"
                echo "$validation_output"
                # Provide specific guidance for common issues
                if echo "$validation_output" | grep -q "static list expression is required"; then
                    print_status "💡 Tip: ignore_changes requires a static list. Remove concat() or conditional expressions."
                elif echo "$validation_output" | grep -q "Invalid expression"; then
                    print_status "💡 Tip: Check for invalid function usage in expressions."
                fi
                print_status "💡 Run with --autofix to automatically fix common syntax issues"
            fi
            return 1
        fi
    fi
}

# === CONFIGURATION VALIDATION ===
validate_configuration() {
    local config_name="$1"
    local config_path="$CONFIGURATIONS_DIR/$config_name"
    
    if [[ ! -d "$config_path" ]]; then
        print_error "Configuration directory not found: $config_path"
        FAILED_CONFIGS+=("$config_name")
        return 1
    fi
    
    if [[ "$QUIET" != "true" ]]; then
        echo "Validating configuration: $config_name"
    fi
    
    local validation_passed=true
    
    # Run format check with autofix
    if [[ "$SYNTAX_ONLY" != "true" ]]; then
        if ! run_format_check "$config_path" "$config_name" "$AUTOFIX"; then
            validation_passed=false
        fi
    fi
    
    # Run syntax validation with autofix
    if [[ "$FORMAT_ONLY" != "true" ]]; then
        if ! run_syntax_validation "$config_path" "$config_name" "$AUTOFIX"; then
            validation_passed=false
        fi
    fi
    
    # Track results
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

# === ENHANCED REPORTING ===
generate_validation_report() {
    echo ""
    echo "============================================================================="
    echo "  🔍 TERRAFORM VALIDATION REPORT"
    echo "============================================================================="
    echo ""
    echo ""
    echo "Summary Statistics"
    
    local total_configs=$((${#PASSED_CONFIGS[@]} + ${#FAILED_CONFIGS[@]}))
    local passed_count=${#PASSED_CONFIGS[@]}
    local failed_count=${#FAILED_CONFIGS[@]}
    
    print_status "Total configurations validated: $total_configs"
    print_success "Passed: $passed_count"
    
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed: $failed_count"
    else
        print_status "Failed: $failed_count"
    fi
    
    echo ""
    
    # Detailed results
    if [[ ${#PASSED_CONFIGS[@]} -gt 0 ]]; then
        echo "✅ Passed Configurations"
        for config in "${PASSED_CONFIGS[@]}"; do
            print_success "  $config"
        done
        echo ""
    fi
    
    if [[ ${#FAILED_CONFIGS[@]} -gt 0 ]]; then
        echo "❌ Failed Configurations"
        for config in "${FAILED_CONFIGS[@]}"; do
            print_error "  $config"
        done
        echo ""
    else
        print_status "🎉 All configurations are valid!"
        if [[ "$AUTOFIX_APPLIED" == "true" ]]; then
            print_status "✨ Auto-fixes were applied - please review and commit changes"
        fi
    fi
    
    echo ""
}

# === MAIN FUNCTION ===
main() {
    local configs_to_validate=()
    
    # Parse arguments directly in main
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
            -*)
                echo "ERROR: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                configs_to_validate+=("$1")
                shift
                ;;
        esac
    done
    
    # Validation
    if [[ "$FORMAT_ONLY" == "true" && "$SYNTAX_ONLY" == "true" ]]; then
        echo "ERROR: Options --format-only and --syntax-only are mutually exclusive" >&2
        exit 1
    fi

    # Display headers AFTER argument parsing
    echo "🔍 Terraform Validation Script for Power Platform Governance"
    echo "==========================================================="
    echo "📂 Project root: $REPO_ROOT"
    echo

    # Display autofix status after parsing
    if [[ "$AUTOFIX" == "true" ]]; then
        echo "🛠️  Auto-fix mode enabled"
        echo
    fi
    
    validate_prerequisites
    
    # Auto-discover configurations if none specified
    if [[ ${#configs_to_validate[@]} -eq 0 ]]; then
        readarray -t configs_to_validate <<< "$(discover_configurations)"
    fi
    
    for config in "${configs_to_validate[@]}"; do
        # Skip empty entries from array expansion
        if [[ -n "$config" ]]; then
            validate_configuration "$config"
        fi
    done
    
    generate_validation_report
    
    if [[ ${#FAILED_CONFIGS[@]} -gt 0 ]]; then
        if [[ "$AUTOFIX" == "false" ]]; then
            print_status "💡 Tip: Run with --autofix to automatically fix issues"
            print_status "Example: $0 --autofix"
        fi
        exit 1
    else
        if [[ "$AUTOFIX_APPLIED" == "true" ]]; then
            print_status "✨ Auto-fixes were applied - please review and commit changes"
        fi
    fi
}

# Call main with all arguments
main "$@"