#!/bin/bash
# ==============================================================================
# Power Platform Terraform Governance - Complete Setup Script
# ==============================================================================
# This script orchestrates the complete setup process for the Power Platform
# Terraform governance solution. It runs all the necessary setup scripts in
# the correct order and provides a streamlined setup experience.
# ==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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

print_header() {
    echo -e "${CYAN}${BOLD}$1${NC}"
}

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

# Function to display banner
show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "============================================================================="
    echo "  Power Platform Terraform Governance - Complete Setup"
    echo "============================================================================="
    echo -e "${NC}"
    echo "This script will set up everything needed to run Terraform configurations"
    echo "for Power Platform governance, including:"
    echo ""
    echo "  1. Azure AD Service Principal with OIDC for GitHub"
    echo "  2. Power Platform registration with tenant admin privileges"
    echo "  3. Azure resources for Terraform state storage"
    echo "  4. GitHub repository secrets for CI/CD"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed and authenticated"
    echo "  - Power Platform CLI installed and authenticated (with tenant admin)"
    echo "  - GitHub CLI installed and authenticated"
    echo "  - jq installed for JSON processing"
    echo ""
    echo -e "${YELLOW}Note: You must have Power Platform tenant admin privileges to complete this setup.${NC}"
    echo ""
}

# Function to validate prerequisites
validate_prerequisites() {
    print_header "Validating Prerequisites"
    
    local all_good=true
    
    # Check Azure CLI
    if command -v az &> /dev/null; then
        print_success "✓ Azure CLI is installed"
        if az account show &> /dev/null; then
            print_success "✓ Azure CLI is authenticated"
        else
            print_error "✗ Azure CLI is not authenticated. Please run 'az login'"
            all_good=false
        fi
    else
        print_error "✗ Azure CLI is not installed"
        all_good=false
    fi
    
    # Check Power Platform CLI
    if command -v pac &> /dev/null; then
        print_success "✓ Power Platform CLI is installed"
        if pac auth list &> /dev/null; then
            print_success "✓ Power Platform CLI is authenticated"
        else
            print_error "✗ Power Platform CLI is not authenticated. Please run 'pac auth create'"
            all_good=false
        fi
    else
        print_error "✗ Power Platform CLI is not installed"
        all_good=false
    fi
    
    # Check GitHub CLI
    if command -v gh &> /dev/null; then
        print_success "✓ GitHub CLI is installed"
        if gh auth status &> /dev/null; then
            print_success "✓ GitHub CLI is authenticated"
        else
            print_error "✗ GitHub CLI is not authenticated. Please run 'gh auth login'"
            all_good=false
        fi
    else
        print_error "✗ GitHub CLI is not installed"
        all_good=false
    fi
    
    # Check jq
    if command -v jq &> /dev/null; then
        print_success "✓ jq is installed"
    else
        print_error "✗ jq is not installed"
        all_good=false
    fi
    
    # Check openssl (for random generation)
    if command -v openssl &> /dev/null; then
        print_success "✓ openssl is installed"
    else
        print_error "✗ openssl is not installed"
        all_good=false
    fi
    
    if [[ "$all_good" != true ]]; then
        print_error "Prerequisites validation failed. Please install missing tools and try again."
        exit 1
    fi
    
    print_success "All prerequisites validated successfully"
    echo ""
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
    
    print_status "Making scripts executable..."
    
    chmod +x "$script_dir/01-create-service-principal.sh"
    chmod +x "$script_dir/02-create-terraform-backend.sh"
    chmod +x "$script_dir/03-create-github-secrets.sh"
    
    print_success "Scripts made executable"
}

# Function to run script with error handling
run_script() {
    local script_path="$1"
    local script_name="$2"
    
    print_step "Running $script_name..."
    echo ""
    
    if [[ -f "$script_path" ]]; then
        if bash "$script_path"; then
            print_success "$script_name completed successfully"
            echo ""
        else
            print_error "$script_name failed"
            exit 1
        fi
    else
        print_error "Script not found: $script_path"
        exit 1
    fi
}

# Function to prompt for continuation
prompt_continue() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    echo -n "Press Enter to continue or Ctrl+C to abort..."
    read -r
    echo ""
}

# Function to display final summary
show_final_summary() {
    print_header "Setup Complete!"
    echo ""
    print_success "🎉 Power Platform Terraform Governance setup completed successfully!"
    echo ""
    print_status "What was created:"
    print_status "  ✓ Azure AD Service Principal with OIDC trust for GitHub"
    print_status "  ✓ Power Platform registration with tenant admin privileges"
    print_status "  ✓ Azure Resource Group for Terraform state storage"
    print_status "  ✓ Azure Storage Account with proper security configuration"
    print_status "  ✓ GitHub repository secrets for CI/CD authentication"
    print_status "  ✓ GitHub environment for additional security"
    echo ""
    print_status "Next steps:"
    print_status "  1. Review the created Azure resources in the Azure Portal"
    print_status "  2. Check the GitHub secrets in your repository settings"
    print_status "  3. Run the GitHub Actions workflow to deploy your first configuration"
    print_status "  4. Monitor the workflow execution in the Actions tab"
    echo ""
    print_status "Available configurations:"
    print_status "  - 02-dlp-policy: Data Loss Prevention policies"
    print_status "  - 03-environment: Power Platform environments"
    echo ""
    print_status "Documentation:"
    print_status "  - Check the configurations/ folder for detailed README files"
    print_status "  - Review the .github/workflows/ folder for CI/CD configuration"
    echo ""
    print_success "Happy governance! 🚀"
}

# Function to handle script interruption
cleanup() {
    print_warning "Setup interrupted by user"
    print_status "You can resume the setup by running this script again"
    print_status "Already completed steps will be skipped automatically"
    exit 1
}

# Main execution function
main() {
    # Set up signal handlers
    trap cleanup SIGINT SIGTERM
    
    # Get script directory
    local script_dir
    script_dir="$(get_script_dir)"
    
    # Show banner
    show_banner
    
    # Ask for confirmation before starting
    echo -n "Do you want to proceed with the complete setup? (y/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
    echo ""
    
    # Validate prerequisites
    validate_prerequisites
    
    # Make scripts executable
    make_scripts_executable "$script_dir"
    
    # Step 1: Create Service Principal
    print_header "Step 1: Create Service Principal with OIDC"
    print_status "This step will create an Azure AD Service Principal with OIDC trust for GitHub"
    print_status "and register it with Power Platform for tenant admin access."
    prompt_continue "Make sure you have both Azure and Power Platform admin privileges."
    
    run_script "$script_dir/01-create-service-principal.sh" "Service Principal Creation"
    
    # Step 2: Create Terraform Backend
    print_header "Step 2: Create Terraform Backend Resources"
    print_status "This step will create Azure resources for storing Terraform state files"
    print_status "including Resource Group, Storage Account, and Container."
    prompt_continue "This will create billable Azure resources."
    
    run_script "$script_dir/02-create-terraform-backend.sh" "Terraform Backend Creation"
    
    # Step 3: Create GitHub Secrets
    print_header "Step 3: Create GitHub Secrets"
    print_status "This step will create all required GitHub secrets for the CI/CD workflow"
    print_status "including Azure credentials and Terraform backend configuration."
    prompt_continue "Make sure you have admin access to the GitHub repository."
    
    run_script "$script_dir/03-create-github-secrets.sh" "GitHub Secrets Creation"
    
    # Show final summary
    show_final_summary
}

# Run the main function
main "$@"
