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
    
    return $(run_script_with_handling "$script_path" "$description")
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
    if ! run_setup_script "01-create-service-principal-config.sh" "Create Azure AD Service Principal with OIDC"; then
        return 1
    fi
    
    # Step 2: Create Terraform Backend
    if ! run_setup_script "02-create-terraform-backend-config.sh" "Create Terraform Backend Storage"; then
        return 1
    fi
    
    # Step 3: Create GitHub Secrets
    if ! run_setup_script "03-create-github-secrets-config.sh" "Create GitHub Repository Secrets"; then
        return 1
    fi
    
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
    # Set up error handling
    trap 'handle_error "unknown"' EXIT
    
    # Display header
    display_header
    
    # Initialize configuration
    if ! init_config; then
        exit 1
    fi
    
    # Confirm configuration with user
    if ! confirm_config; then
        exit 1
    fi
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Check authentication
    if ! check_azure_auth; then
        exit 1
    fi
    
    if ! check_power_platform_auth; then
        exit 1
    fi
    
    # Run complete setup
    if ! run_complete_setup; then
        exit 1
    fi
    
    # Display final summary
    display_final_summary
    
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
    else
        echo ""
        print_status "You can run the validation later using:"
        print_status "  ./scripts/setup/validate-setup.sh"
    fi
}

# Run the main function
main "$@"