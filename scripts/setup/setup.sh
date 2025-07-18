#!/bin/bash
# ==============================================================================
# Master Setup Script for Power Platform Terraform Governance
# ==============================================================================
# This script orchestrates the complete setup process using configuration
# from config.env file for a streamlined, secure experience
# ==============================================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utility functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Function to display header
display_header() {
    print_banner "Power Platform Terraform Governance - Complete Setup"
    print_status ""
    print_status "This script will:"
    print_status "  1. Create Azure AD Service Principal with OIDC"
    print_status "  2. Create Terraform backend storage"
    print_status "  3. Create GitHub repository secrets"
    print_status ""
    print_status "Using configuration-driven approach for better UX and security"
    print_status ""
}

# Function to run a setup script with configuration
run_setup_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local description="$2"
    
    print_step "Running $description..."
    echo ""
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    
    # Make script executable
    chmod +x "$script_path"
    
    # Run the script directly without subprocess timing complications
    if "$script_path"; then
        print_success "$description completed successfully"
        echo ""
        return 0
    else
        print_error "$description failed"
        echo ""
        return 1
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Use the common validation function
    validate_common_prerequisites true false true false true
}

# Function to check Azure authentication
check_azure_auth() {
    print_status "Checking Azure authentication..."
    
    if ! validate_azure_auth; then
        print_error "You are not logged in to Azure"
        print_error "Please run: az login"
        return 1
    fi
    
    local current_account=$(az account show --query name -o tsv)
    print_success "Azure authentication confirmed: $current_account"
    return 0
}

# Function to check Power Platform authentication
check_power_platform_auth() {
    print_status "Checking Power Platform authentication..."
    
    if ! pac auth list &> /dev/null; then
        print_error "You are not logged in to Power Platform"
        print_error "Please run: pac auth create"
        print_error "You need Power Platform tenant admin privileges"
        return 1
    fi
    
    local current_user=$(pac auth list 2>/dev/null | grep '\*' | awk '{print $4}' 2>/dev/null)
    print_success "Power Platform authentication confirmed: $current_user"
    return 0
}

# Function to run the complete setup process
run_complete_setup() {
    print_status "Starting complete setup process..."
    
    # Step 1: Create Service Principal
    start_timing "service_principal" "Azure AD Service Principal creation with OIDC"
    print_status "Step 1/3: Creating Azure AD Service Principal with OIDC..."
    if ! run_setup_script "01-create-service-principal-config.sh" "Create Azure AD Service Principal with OIDC"; then
        end_timing "service_principal"
        return 1
    fi
    end_timing "service_principal"
    print_success "✓ Step 1 completed successfully"
    
    # Show progress after first step
    estimate_remaining_time 3 1 "setup phases"
    
    # Step 2: Create Terraform Backend
    start_timing "terraform_backend" "Terraform backend storage creation"
    print_status "Step 2/3: Creating Terraform Backend Storage..."
    if ! run_setup_script "02-create-terraform-backend-config.sh" "Create Terraform Backend Storage"; then
        end_timing "terraform_backend"
        return 1
    fi
    end_timing "terraform_backend"
    print_success "✓ Step 2 completed successfully"
    
    # Show progress after second step
    estimate_remaining_time 3 2 "setup phases"
    
    # Step 3: Create GitHub Secrets
    start_timing "github_secrets" "GitHub repository secrets configuration"
    print_status "Step 3/3: Creating GitHub Repository Secrets..."
    if ! run_setup_script "03-create-github-secrets-config.sh" "Create GitHub Repository Secrets"; then
        end_timing "github_secrets"
        return 1
    fi
    end_timing "github_secrets"
    print_success "✓ Step 3 completed successfully"
    
    return 0
}

# Function to display final summary
display_final_summary() {
    print_success ""
    print_success "==============================================================="
    print_success "SETUP COMPLETED SUCCESSFULLY!"
    print_success "==============================================================="
    print_success ""
    print_success "What was created:"
    print_success "  ✓ Azure AD Service Principal with OIDC for GitHub"
    print_success "  ✓ Terraform backend storage with JIT network access"
    print_success "  ✓ GitHub repository secrets for CI/CD"
    print_success ""
    print_success "Configuration used:"
    print_success "  • GitHub Repository: $GITHUB_OWNER/$GITHUB_REPO"
    print_success "  • Resource Group: $RESOURCE_GROUP_NAME"
    print_success "  • Storage Account: $STORAGE_ACCOUNT_NAME"
    print_success "  • Container: $CONTAINER_NAME"
    print_success ""
    print_success "Next steps:"
    print_success "  1. Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO"
    print_success "  2. Navigate to the Actions tab"
    print_success "  3. Run the 'Terraform Plan and Apply' workflow"
    print_success "  4. Select your configuration and environment"
    print_success ""
    print_success "The Power Platform Terraform governance is now ready for use!"
    print_success ""
    print_status "Configuration file: $SCRIPT_DIR/config.env"
    print_status "This file is excluded from version control for security."
}

# Function to handle errors and cleanup
handle_error() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        # Finalize timing even on error
        finalize_script_timing
        
        print_error ""
        print_error "==============================================================="
        print_error "SETUP FAILED"
        print_error "==============================================================="
        print_error ""
        print_error "The setup process failed at step: $1"
        print_error "Exit code: $exit_code"
        print_error ""
        print_error "Troubleshooting:"
        print_error "  • Check the error messages above"
        print_error "  • Verify your configuration in: $SCRIPT_DIR/config.env"
        print_error "  • Ensure you have the required permissions"
        print_error "  • Run individual scripts manually if needed"
        print_error ""
        print_error "You can resume setup by running this script again."
        print_error "Already completed steps will be skipped or updated."
    fi
}

# Main function
main() {
    # Initialize timing for the entire script
    init_script_timing "Power Platform Terraform Governance - Complete Setup"
    
    # Set up error handling
    trap 'handle_error "unknown"' EXIT
    
    # Display header
    start_timing "initialization" "Script initialization and header display"
    display_header
    end_timing "initialization"
    
    # Initialize configuration
    start_timing "config_init" "Configuration initialization and validation"
    if ! init_config; then
        finalize_script_timing
        exit 1
    fi
    end_timing "config_init"
    
    # Confirm configuration with user
    start_timing "config_confirm" "Configuration confirmation with user"
    if ! confirm_config; then
        finalize_script_timing
        exit 1
    fi
    end_timing "config_confirm"
    
    # Validate prerequisites
    start_timing "prerequisites" "Prerequisites validation"
    if ! validate_prerequisites; then
        finalize_script_timing
        exit 1
    fi
    end_timing "prerequisites"
    
    # Check authentication
    start_timing "auth_check" "Authentication validation"
    if ! check_azure_auth; then
        finalize_script_timing
        exit 1
    fi
    
    if ! check_power_platform_auth; then
        finalize_script_timing
        exit 1
    fi
    end_timing "auth_check"
    
    # Show progress estimate
    get_timing_summary
    estimate_remaining_time 3 0 "major setup phases"
    
    # Run complete setup
    start_timing "setup_execution" "Complete setup process execution"
    if ! run_complete_setup; then
        finalize_script_timing
        exit 1
    fi
    end_timing "setup_execution"
    
    # Display final summary
    start_timing "final_summary" "Final summary and documentation"
    display_final_summary
    end_timing "final_summary"
    
    # Finalize timing and show comprehensive summary
    finalize_script_timing
    
    # Disable error trap on successful completion
    trap - EXIT
    
    print_success "Setup script completed successfully!"
    
    # Offer to run validation
    echo ""
    print_status "Would you like to run the setup validation now? This will verify all configurations."
    echo -n "Run validation? (y/N): "
    read -r RUN_VALIDATION
    
    if [[ "$RUN_VALIDATION" == "y" || "$RUN_VALIDATION" == "Y" ]]; then
        echo ""
        print_status "Running setup validation..."
        
        # Time the validation process
        start_timing "validation" "Setup validation process"
        
        # Check if validation script exists
        VALIDATION_SCRIPT="$(dirname "$0")/validate-setup.sh"
        if [[ -f "$VALIDATION_SCRIPT" ]]; then
            if bash "$VALIDATION_SCRIPT" --non-interactive; then
                print_success "✅ Setup validation completed successfully!"
            else
                print_warning "⚠ Setup validation found some issues. Please review the output above."
            fi
        else
            print_error "❌ Validation script not found at: $VALIDATION_SCRIPT"
        fi
        
        end_timing "validation"
        
        # Show validation timing summary
        echo ""
        print_status "⏱️  Validation completed in: $(format_duration ${TIMING_DURATIONS[validation]})"
    else
        echo ""
        print_status "You can run the validation later using:"
        print_status "  ./scripts/setup/validate-setup.sh"
    fi
}

# Run the main function
main "$@"