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

# Source the configuration loader
source "$SCRIPT_DIR/config-loader.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display header
display_header() {
    print_status "==============================================================="
    print_status "Power Platform Terraform Governance - Complete Setup"
    print_status "==============================================================="
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
    
    print_status ""
    print_status "STEP: $description"
    print_status "Running: $script_name"
    print_status "----------------------------------------"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    
    # Make script executable
    chmod +x "$script_path"
    
    # Run the script
    if "$script_path"; then
        print_success "✓ $description completed successfully"
        return 0
    else
        print_error "✗ $description failed"
        return 1
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    local errors=0
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        errors=$((errors + 1))
    fi
    
    # Check Power Platform CLI
    if ! command -v pac &> /dev/null; then
        print_error "Power Platform CLI is not installed"
        errors=$((errors + 1))
    fi
    
    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed"
        errors=$((errors + 1))
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        print_error "Prerequisites validation failed with $errors errors"
        print_error "Please install the missing tools and try again"
        return 1
    fi
    
    print_success "Prerequisites validated successfully"
    return 0
}

# Function to check Azure authentication
check_azure_auth() {
    print_status "Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
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
}

# Run the main function
main "$@"