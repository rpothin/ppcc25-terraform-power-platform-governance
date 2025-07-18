#!/bin/bash
# ==============================================================================
# Power Platform Terraform Governance - Complete Cleanup Script
# ==============================================================================
# This script orchestrates the complete cleanup process for the Power Platform
# Terraform governance solution. It runs all the necessary cleanup scripts in
# reverse order and provides a streamlined cleanup experience.
#
# This script uses the configuration-driven approach, loading settings from
# the config.env file created during setup. This eliminates the need for
# repetitive prompts and provides a consistent user experience.
# ==============================================================================

set -e  # Exit on any error

# Load utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/utils.sh"

# Function to display banner
show_banner() {
    print_banner "Power Platform Terraform Governance - Complete Cleanup"
    echo "This script will clean up everything created by the setup process,"
    echo "including:"
    echo ""
    echo "  1. GitHub repository secrets and environments"
    echo "  2. Azure resources for Terraform state storage"
    echo "  3. Azure AD Service Principal and Power Platform registration"
    echo ""
    print_danger_zone "This will permanently delete all resources!"
    echo ""
    echo "What will be removed:"
    echo "  - All GitHub secrets for CI/CD authentication"
    echo "  - GitHub production environment (optional)"
    echo "  - Azure Storage Account with all Terraform state files"
    echo "  - Azure Resource Group (optional)"
    echo "  - Azure AD Service Principal and App Registration"
    echo "  - Power Platform application registration"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed and authenticated"
    echo "  - Power Platform CLI installed and authenticated (optional)"
    echo "  - GitHub CLI installed and authenticated"
    echo "  - config.env file from setup process must exist"
    echo ""
    print_warning "Note: You must have admin privileges to complete this cleanup."
    print_warning "Note: This script uses configuration from the config.env file created during setup."
    echo ""
}

# Function to validate prerequisites
validate_prerequisites() {
    print_header "Validating Prerequisites"
    
    # Use the common validation function (all tools required, PowerPlatform optional)
    validate_common_prerequisites true true true true false
}

# Function to get script directory
get_script_dir() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$script_dir"
}

# Function to check if script exists
check_script() {
    local script_path="$1"
    if [[ -f "$script_path" ]]; then
        return 0
    else
        print_error "Script not found: $script_path"
        return 1
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    local script_dir="$1"
    
    print_status "Making cleanup scripts executable..."
    
    chmod +x "$script_dir/cleanup-github-secrets-config.sh"
    chmod +x "$script_dir/cleanup-terraform-backend-config.sh"
    chmod +x "$script_dir/cleanup-service-principal-config.sh"
    
    print_success "Scripts made executable"
}

# Function to run script with error handling
run_script() {
    local script_path="$1"
    local script_name="$2"
    local is_optional="${3:-false}"
    
    run_script_with_handling "$script_path" "$script_name" "$is_optional"
    return $?
}

# Function to prompt for continuation
prompt_continue() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    echo -n "Press Enter to continue or Ctrl+C to abort..."
    read -r
    echo ""
}

# Function to get cleanup scope
get_cleanup_scope() {
    print_header "Cleanup Scope Selection"
    echo "You can choose to clean up specific components or everything:"
    echo ""
    echo "  1. Complete cleanup (all components)"
    echo "  2. GitHub secrets only"
    echo "  3. Terraform backend only"
    echo "  4. Service principal only"
    echo "  5. Custom selection"
    echo ""
    
    while true; do
        echo -n "Please select cleanup scope (1-5): "
        read -r SCOPE_CHOICE
        
        case $SCOPE_CHOICE in
            1)
                export CLEANUP_GITHUB=true
                export CLEANUP_BACKEND=true
                export CLEANUP_SERVICE_PRINCIPAL=true
                break
                ;;
            2)
                export CLEANUP_GITHUB=true
                export CLEANUP_BACKEND=false
                export CLEANUP_SERVICE_PRINCIPAL=false
                break
                ;;
            3)
                export CLEANUP_GITHUB=false
                export CLEANUP_BACKEND=true
                export CLEANUP_SERVICE_PRINCIPAL=false
                break
                ;;
            4)
                export CLEANUP_GITHUB=false
                export CLEANUP_BACKEND=false
                export CLEANUP_SERVICE_PRINCIPAL=true
                break
                ;;
            5)
                echo ""
                echo -n "Clean up GitHub secrets? (y/N): "
                read -r GITHUB_CHOICE
                export CLEANUP_GITHUB=$([[ "$GITHUB_CHOICE" == "y" || "$GITHUB_CHOICE" == "Y" ]] && echo true || echo false)
                
                echo -n "Clean up Terraform backend? (y/N): "
                read -r BACKEND_CHOICE
                export CLEANUP_BACKEND=$([[ "$BACKEND_CHOICE" == "y" || "$BACKEND_CHOICE" == "Y" ]] && echo true || echo false)
                
                echo -n "Clean up Service Principal? (y/N): "
                read -r SP_CHOICE
                export CLEANUP_SERVICE_PRINCIPAL=$([[ "$SP_CHOICE" == "y" || "$SP_CHOICE" == "Y" ]] && echo true || echo false)
                break
                ;;
            *)
                print_error "Invalid choice. Please select 1-5."
                ;;
        esac
    done
    
    echo ""
    print_status "Cleanup scope selected:"
    print_status "  GitHub secrets: $([[ "$CLEANUP_GITHUB" == "true" ]] && echo "✓ Yes" || echo "✗ No")"
    print_status "  Terraform backend: $([[ "$CLEANUP_BACKEND" == "true" ]] && echo "✓ Yes" || echo "✗ No")"
    print_status "  Service Principal: $([[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]] && echo "✓ Yes" || echo "✗ No")"
    echo ""
}

# Function to confirm cleanup
confirm_cleanup() {
    print_header "Final Confirmation"
    
    print_danger_zone "You are about to permanently delete resources. This action cannot be undone!"
    echo ""
    echo "Selected cleanup scope:"
    
    if [[ "$CLEANUP_GITHUB" == "true" ]]; then
        echo "  🗑️  GitHub secrets and environments"
    fi
    
    if [[ "$CLEANUP_BACKEND" == "true" ]]; then
        echo "  🗑️  Terraform backend (including ALL state files)"
    fi
    
    if [[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]]; then
        echo "  🗑️  Service Principal and Power Platform registration"
    fi
    
    echo ""
    print_warning "Make sure you have backed up any important data before proceeding."
    echo ""
    
    if ! get_deletion_confirmation "the selected resources"; then
        exit 1
    fi
    
    echo ""
    print_success "Cleanup confirmed. Proceeding with resource deletion..."
    echo ""
}

# Function to display final summary
show_final_summary() {
    print_header "Cleanup Complete!"
    echo ""
    
    local overall_success=true
    
    if [[ "$CLEANUP_GITHUB" == "true" || "$CLEANUP_BACKEND" == "true" || "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]]; then
        print_success "🧹 Power Platform Terraform Governance cleanup process completed!"
        echo ""
        print_status "Cleanup Results:"
        
        if [[ "$CLEANUP_GITHUB" == "true" ]]; then
            if [[ "$GITHUB_CLEANUP_SUCCESS" == "true" ]]; then
                print_status "  ✓ GitHub repository secrets and environments - SUCCESS"
            else
                print_status "  ✗ GitHub repository secrets and environments - FAILED/PARTIAL"
                overall_success=false
            fi
        fi
        
        if [[ "$CLEANUP_BACKEND" == "true" ]]; then
            if [[ "$BACKEND_CLEANUP_SUCCESS" == "true" ]]; then
                print_status "  ✓ Terraform state storage and Azure resources - SUCCESS"
            else
                print_status "  ✗ Terraform state storage and Azure resources - FAILED/PARTIAL"
                overall_success=false
            fi
        fi
        
        if [[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]]; then
            if [[ "$SP_CLEANUP_SUCCESS" == "true" ]]; then
                print_status "  ✓ Azure AD Service Principal and Power Platform registration - SUCCESS"
            else
                print_status "  ✗ Azure AD Service Principal and Power Platform registration - FAILED/PARTIAL"
                overall_success=false
            fi
        fi
        
        echo ""
        
        if [[ "$overall_success" == "true" ]]; then
            print_status "✅ All selected components cleaned up successfully!"
        else
            print_warning "⚠️  Some components may need manual cleanup"
            print_status "Check the output above for details on what failed"
        fi
        
        echo ""
        print_status "Next steps:"
        print_status "  1. Verify resources are deleted in the Azure Portal"
        print_status "  2. Check that GitHub secrets are removed from repository settings"
        if [[ "$overall_success" != "true" ]]; then
            print_status "  3. Manually clean up any remaining resources that failed"
            print_status "  4. Re-run individual cleanup scripts if needed"
        fi
        print_status "  5. Run setup.sh again if you need to recreate the environment"
        echo ""
    else
        print_warning "No cleanup actions were selected"
    fi
    
    if [[ "$overall_success" == "true" ]]; then
        print_success "Cleanup process completed successfully! 🎉"
    else
        print_warning "Cleanup process completed with some issues. Please review the output above."
    fi
}

# Function to handle script interruption
cleanup_handler() {
    # Finalize timing even on interruption
    finalize_script_timing
    
    handle_script_interruption "Cleanup"
}

# Main execution function
main() {
    # Initialize cleanup scope variables
    export CLEANUP_GITHUB=false
    export CLEANUP_BACKEND=false
    export CLEANUP_SERVICE_PRINCIPAL=false
    
    # Initialize timing for the entire script
    init_script_timing "Power Platform Terraform Governance - Complete Cleanup"
    
    # Set up signal handlers
    trap cleanup_handler SIGINT SIGTERM
    
    # Get script directory
    start_timing "initialization" "Script initialization and setup"
    local script_dir
    script_dir="$(get_script_dir)"
    
    # Show banner
    show_banner
    end_timing "initialization"
    
    # Ask for initial confirmation
    start_timing "user_confirmation" "User confirmation and scope selection"
    echo -n "Do you want to proceed with the cleanup process? (y/N): "
    read -r INITIAL_CONFIRM
    if [[ "$INITIAL_CONFIRM" != "y" && "$INITIAL_CONFIRM" != "Y" ]]; then
        print_error "Cleanup cancelled by user"
        finalize_script_timing
        exit 1
    fi
    echo ""
    end_timing "user_confirmation"
    
    # Validate prerequisites
    start_timing "prerequisites" "Prerequisites validation"
    validate_prerequisites
    end_timing "prerequisites"
    
    # Get cleanup scope
    start_timing "scope_selection" "Cleanup scope selection"
    get_cleanup_scope
    end_timing "scope_selection"
    
    # Final confirmation
    start_timing "final_confirmation" "Final confirmation and safety checks"
    confirm_cleanup
    end_timing "final_confirmation"
    
    # Make scripts executable
    start_timing "script_preparation" "Script preparation and setup"
    make_scripts_executable "$script_dir"
    end_timing "script_preparation"
    
    # Show progress estimate
    get_timing_summary
    
    local cleanup_steps=0
    [[ "$CLEANUP_GITHUB" == "true" ]] && cleanup_steps=$((cleanup_steps + 1))
    [[ "$CLEANUP_BACKEND" == "true" ]] && cleanup_steps=$((cleanup_steps + 1))
    [[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]] && cleanup_steps=$((cleanup_steps + 1))
    
    estimate_remaining_time $cleanup_steps 0 "cleanup phases"
    
    # Initialize success tracking
    GITHUB_CLEANUP_SUCCESS=false
    BACKEND_CLEANUP_SUCCESS=false
    SP_CLEANUP_SUCCESS=false
    
    local completed_steps=0
    
    # Step 1: Cleanup GitHub Secrets (reverse order - first thing to remove)
    if [[ "$CLEANUP_GITHUB" == "true" ]]; then
        start_timing "github_cleanup" "GitHub secrets and environments cleanup"
        print_header "Step 1: Cleanup GitHub Secrets"
        print_status "This step will remove all GitHub secrets and environments"
        print_status "created during the setup process."
        prompt_continue "This will break any existing GitHub Actions workflows."
        
        # Set flag to indicate we're running from main cleanup script
        export CLEANUP_MAIN_SCRIPT=true
        
        echo "[DEBUG] About to run GitHub cleanup script"
        
        # Temporarily disable exit on error for this specific call
        set +e
        "$script_dir/cleanup-github-secrets-config.sh" --non-interactive
        local github_exit_code=$?
        set -e
        
        echo "[DEBUG] GitHub cleanup script returned exit code: $github_exit_code"
        
        if [[ $github_exit_code -eq 0 ]]; then
            GITHUB_CLEANUP_SUCCESS=true
            echo "[DEBUG] GitHub cleanup marked as successful"
        else
            GITHUB_CLEANUP_SUCCESS=false
            echo "[DEBUG] GitHub cleanup marked as failed"
        fi
        end_timing "github_cleanup"
        
        echo "[DEBUG] About to increment completed_steps. Current value: $completed_steps"
        completed_steps=$((completed_steps + 1))
        echo "[DEBUG] completed_steps after increment: $completed_steps"
        echo "[DEBUG] About to call estimate_remaining_time with: total=$cleanup_steps, completed=$completed_steps"
        
        estimate_remaining_time $cleanup_steps $completed_steps "cleanup phases"
        
        echo "[DEBUG] Completed GitHub cleanup section, proceeding to backend cleanup check"
    fi
    
    echo "[DEBUG] Checking if CLEANUP_BACKEND is true: $CLEANUP_BACKEND"
    
    # Step 2: Cleanup Terraform Backend (second - remove infrastructure)
    if [[ "$CLEANUP_BACKEND" == "true" ]]; then
        echo "[DEBUG] Starting Terraform backend cleanup section"
        start_timing "backend_cleanup" "Terraform backend and Azure resources cleanup"
        print_header "Step 2: Cleanup Terraform Backend"
        print_status "This step will remove the Azure resources used for Terraform state storage"
        print_status "including Storage Account, Container, and optionally Resource Group."
        prompt_continue "This will permanently delete all Terraform state files."
        
        # Set flag to indicate we're running from main cleanup script
        export CLEANUP_MAIN_SCRIPT=true
        
        # For complete cleanup (scope 1), also delete the resource group
        if [[ "$SCOPE_CHOICE" == "1" ]]; then
            export DELETE_RESOURCE_GROUP="y"
        fi
        
        # Run the script with the --non-interactive flag
        echo "[DEBUG] About to run Terraform backend cleanup script"
        
        # Temporarily disable exit on error for this specific call
        set +e
        "$script_dir/cleanup-terraform-backend-config.sh" --non-interactive
        local backend_exit_code=$?
        set -e
        
        echo "[DEBUG] Terraform backend cleanup script returned exit code: $backend_exit_code"
        
        if [[ $backend_exit_code -eq 0 ]]; then
            BACKEND_CLEANUP_SUCCESS=true
            echo "[DEBUG] Terraform backend cleanup marked as successful"
        else
            BACKEND_CLEANUP_SUCCESS=false
            echo "[DEBUG] Terraform backend cleanup marked as failed"
        fi
        end_timing "backend_cleanup"
        
        completed_steps=$((completed_steps + 1))
        estimate_remaining_time $cleanup_steps $completed_steps "cleanup phases"
    fi
    
    # Step 3: Cleanup Service Principal (last - remove authentication)
    if [[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]]; then
        start_timing "service_principal_cleanup" "Service Principal and Power Platform registration cleanup"
        print_header "Step 3: Cleanup Service Principal"
        print_status "This step will remove the Azure AD Service Principal and App Registration"
        print_status "as well as the Power Platform application registration."
        prompt_continue "This will remove all authentication credentials."
        
        # Set flag to indicate we're running from main cleanup script
        export CLEANUP_MAIN_SCRIPT=true
        
        # Run the script with the --non-interactive flag
        echo "[DEBUG] About to run Service Principal cleanup script"
        
        # Temporarily disable exit on error for this specific call
        set +e
        "$script_dir/cleanup-service-principal-config.sh" --non-interactive
        local sp_exit_code=$?
        set -e
        
        echo "[DEBUG] Service Principal cleanup script returned exit code: $sp_exit_code"
        
        if [[ $sp_exit_code -eq 0 ]]; then
            SP_CLEANUP_SUCCESS=true
            echo "[DEBUG] Service Principal cleanup marked as successful"
        else
            SP_CLEANUP_SUCCESS=false
            echo "[DEBUG] Service Principal cleanup marked as failed"
        fi
        end_timing "service_principal_cleanup"
        
        completed_steps=$((completed_steps + 1))
    fi
    
    # Show final summary
    start_timing "final_summary" "Final summary and documentation"
    show_final_summary
    end_timing "final_summary"
    
    # Finalize timing and show comprehensive summary
    finalize_script_timing
    
    # Save timing report
    local overall_success=true
    [[ "$CLEANUP_GITHUB" == "true" && "$GITHUB_CLEANUP_SUCCESS" != "true" ]] && overall_success=false
    [[ "$CLEANUP_BACKEND" == "true" && "$BACKEND_CLEANUP_SUCCESS" != "true" ]] && overall_success=false
    [[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" && "$SP_CLEANUP_SUCCESS" != "true" ]] && overall_success=false
    
}

# Run the main function
main "$@"
