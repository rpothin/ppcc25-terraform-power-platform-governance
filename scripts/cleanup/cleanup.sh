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
    
    return $(run_script_with_handling "$script_path" "$script_name" "$is_optional")
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
                CLEANUP_GITHUB=true
                CLEANUP_BACKEND=true
                CLEANUP_SERVICE_PRINCIPAL=true
                break
                ;;
            2)
                CLEANUP_GITHUB=true
                CLEANUP_BACKEND=false
                CLEANUP_SERVICE_PRINCIPAL=false
                break
                ;;
            3)
                CLEANUP_GITHUB=false
                CLEANUP_BACKEND=true
                CLEANUP_SERVICE_PRINCIPAL=false
                break
                ;;
            4)
                CLEANUP_GITHUB=false
                CLEANUP_BACKEND=false
                CLEANUP_SERVICE_PRINCIPAL=true
                break
                ;;
            5)
                echo ""
                echo -n "Clean up GitHub secrets? (y/N): "
                read -r GITHUB_CHOICE
                CLEANUP_GITHUB=$([[ "$GITHUB_CHOICE" == "y" || "$GITHUB_CHOICE" == "Y" ]] && echo true || echo false)
                
                echo -n "Clean up Terraform backend? (y/N): "
                read -r BACKEND_CHOICE
                CLEANUP_BACKEND=$([[ "$BACKEND_CHOICE" == "y" || "$BACKEND_CHOICE" == "Y" ]] && echo true || echo false)
                
                echo -n "Clean up Service Principal? (y/N): "
                read -r SP_CHOICE
                CLEANUP_SERVICE_PRINCIPAL=$([[ "$SP_CHOICE" == "y" || "$SP_CHOICE" == "Y" ]] && echo true || echo false)
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
    handle_script_interruption "Cleanup"
}

# Main execution function
main() {
    # Set up signal handlers
    trap cleanup_handler SIGINT SIGTERM
    
    # Get script directory
    local script_dir
    script_dir="$(get_script_dir)"
    
    # Show banner
    show_banner
    
    # Ask for initial confirmation
    echo -n "Do you want to proceed with the cleanup process? (y/N): "
    read -r INITIAL_CONFIRM
    if [[ "$INITIAL_CONFIRM" != "y" && "$INITIAL_CONFIRM" != "Y" ]]; then
        print_error "Cleanup cancelled by user"
        exit 1
    fi
    echo ""
    
    # Validate prerequisites
    validate_prerequisites
    
    # Get cleanup scope
    get_cleanup_scope
    
    # Final confirmation
    confirm_cleanup
    
    # Make scripts executable
    make_scripts_executable "$script_dir"
    
    # Initialize success tracking
    GITHUB_CLEANUP_SUCCESS=false
    BACKEND_CLEANUP_SUCCESS=false
    SP_CLEANUP_SUCCESS=false
    
    # Step 1: Cleanup GitHub Secrets (reverse order - first thing to remove)
    if [[ "$CLEANUP_GITHUB" == "true" ]]; then
        print_header "Step 1: Cleanup GitHub Secrets"
        print_status "This step will remove all GitHub secrets and environments"
        print_status "created during the setup process."
        prompt_continue "This will break any existing GitHub Actions workflows."
        
        if run_script "$script_dir/cleanup-github-secrets-config.sh" "GitHub Secrets Cleanup"; then
            GITHUB_CLEANUP_SUCCESS=true
        else
            GITHUB_CLEANUP_SUCCESS=false
        fi
    fi
    
    # Step 2: Cleanup Terraform Backend (second - remove infrastructure)
    if [[ "$CLEANUP_BACKEND" == "true" ]]; then
        print_header "Step 2: Cleanup Terraform Backend"
        print_status "This step will remove the Azure resources used for Terraform state storage"
        print_status "including Storage Account, Container, and optionally Resource Group."
        prompt_continue "This will permanently delete all Terraform state files."
        
        if run_script "$script_dir/cleanup-terraform-backend-config.sh" "Terraform Backend Cleanup"; then
            BACKEND_CLEANUP_SUCCESS=true
        else
            BACKEND_CLEANUP_SUCCESS=false
        fi
    fi
    
    # Step 3: Cleanup Service Principal (last - remove authentication)
    if [[ "$CLEANUP_SERVICE_PRINCIPAL" == "true" ]]; then
        print_header "Step 3: Cleanup Service Principal"
        print_status "This step will remove the Azure AD Service Principal and App Registration"
        print_status "as well as the Power Platform application registration."
        prompt_continue "This will remove all authentication credentials."
        
        if run_script "$script_dir/cleanup-service-principal-config.sh" "Service Principal Cleanup"; then
            SP_CLEANUP_SUCCESS=true
        else
            SP_CLEANUP_SUCCESS=false
        fi
    fi
    
    # Show final summary
    show_final_summary
}

# Run the main function
main "$@"
