#!/bin/bash
# ==============================================================================
# Prerequisites Validation Utilities
# ==============================================================================
# Provides common prerequisite validation functions for all scripts
# ==============================================================================

# Source color utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/colors.sh"

# Function to check if a command exists
command_exists() {
    local cmd="$1"
    command -v "$cmd" &> /dev/null
}

# Function to validate Azure CLI and authentication
validate_azure_cli() {
    local require_auth="${1:-true}"
    
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it first."
        print_status "Installation: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi
    
    print_success "✓ Azure CLI is installed"
    
    if [[ "$require_auth" == "true" ]]; then
        if ! az account show &> /dev/null; then
            print_error "You are not logged in to Azure. Please run 'az login' first."
            return 1
        fi
        print_success "✓ Azure CLI is authenticated"
    fi
    
    return 0
}

# Function to validate Power Platform CLI and authentication
validate_power_platform_cli() {
    local require_auth="${1:-true}"
    local is_optional="${2:-false}"
    
    if ! command_exists pac; then
        if [[ "$is_optional" == "true" ]]; then
            print_warning "⚠ Power Platform CLI is not installed (optional for this operation)"
            return 0
        else
            print_error "Power Platform CLI is not installed. Please install it first."
            print_status "Installation: https://docs.microsoft.com/en-us/power-platform/developer/cli/introduction"
            return 1
        fi
    fi
    
    print_success "✓ Power Platform CLI is installed"
    
    if [[ "$require_auth" == "true" ]]; then
        if ! pac auth list &> /dev/null; then
            if [[ "$is_optional" == "true" ]]; then
                print_warning "⚠ Power Platform CLI is not authenticated (skipping Power Platform operations)"
                return 0
            else
                print_error "You are not logged in to Power Platform. Please run 'pac auth create' first."
                print_status "You need Power Platform tenant admin privileges."
                return 1
            fi
        fi
        print_success "✓ Power Platform CLI is authenticated"
    fi
    
    return 0
}

# Function to validate GitHub CLI and authentication
validate_github_cli() {
    local require_auth="${1:-true}"
    
    if ! command_exists gh; then
        print_error "GitHub CLI is not installed. Please install it first."
        print_status "Installation: https://cli.github.com/"
        return 1
    fi
    
    print_success "✓ GitHub CLI is installed"
    
    if [[ "$require_auth" == "true" ]]; then
        if ! gh auth status &> /dev/null; then
            print_error "You are not logged in to GitHub. Please run 'gh auth login' first."
            return 1
        fi
        print_success "✓ GitHub CLI is authenticated"
    fi
    
    return 0
}

# Function to validate jq
validate_jq() {
    if ! command_exists jq; then
        print_error "jq is not installed. Please install it first."
        print_status "Installation: apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
        return 1
    fi
    
    print_success "✓ jq is installed"
    return 0
}

# Function to validate Terraform
validate_terraform() {
    local is_optional="${1:-false}"
    
    if ! command_exists terraform; then
        if [[ "$is_optional" == "true" ]]; then
            print_warning "⚠ Terraform is not installed (optional for this operation)"
            return 0
        else
            print_error "Terraform is not installed. Please install it first."
            print_status "Installation: https://www.terraform.io/downloads.html"
            return 1
        fi
    fi
    
    print_success "✓ Terraform is installed"
    return 0
}

# Function to validate all common prerequisites
validate_common_prerequisites() {
    local require_azure_auth="${1:-true}"
    local require_github_auth="${2:-false}"
    local require_powerplatform_auth="${3:-false}"
    local powerplatform_optional="${4:-false}"
    local terraform_optional="${5:-true}"
    
    print_status "Validating prerequisites..."
    
    local all_good=true
    
    # Validate Azure CLI
    if ! validate_azure_cli "$require_azure_auth"; then
        all_good=false
    fi
    
    # Validate jq (required for JSON parsing)
    if ! validate_jq; then
        all_good=false
    fi
    
    # Validate GitHub CLI if required
    if [[ "$require_github_auth" == "true" ]]; then
        if ! validate_github_cli "$require_github_auth"; then
            all_good=false
        fi
    fi
    
    # Validate Power Platform CLI if required
    if [[ "$require_powerplatform_auth" == "true" ]]; then
        if ! validate_power_platform_cli "$require_powerplatform_auth" "$powerplatform_optional"; then
            all_good=false
        fi
    fi
    
    # Validate Terraform if required
    if [[ "$terraform_optional" == "false" ]]; then
        if ! validate_terraform "$terraform_optional"; then
            all_good=false
        fi
    fi
    
    if [[ "$all_good" == "true" ]]; then
        print_success "All prerequisites validated successfully"
        return 0
    else
        print_error "Prerequisites validation failed. Please install missing tools and try again."
        return 1
    fi
}

# Function to check Azure permissions
check_azure_permissions() {
    local subscription_id="$1"
    local client_id="$2"
    
    if [[ -z "$subscription_id" ]]; then
        print_error "Subscription ID is required for permission check"
        return 1
    fi
    
    # Check if user can read the subscription
    if ! az account show --subscription "$subscription_id" &> /dev/null; then
        print_error "Cannot access subscription: $subscription_id"
        return 1
    fi
    
    print_success "✓ Subscription access confirmed"
    
    # If client ID is provided, check service principal permissions
    if [[ -n "$client_id" ]]; then
        # Check if service principal exists and has permissions
        if az role assignment list --assignee "$client_id" --scope "/subscriptions/$subscription_id" &> /dev/null; then
            print_success "✓ Service principal permissions confirmed"
        else
            print_warning "⚠ Service principal permissions could not be verified"
        fi
    fi
    
    return 0
}

# Export functions for use in other scripts
export -f command_exists validate_azure_cli validate_power_platform_cli
export -f validate_github_cli validate_jq validate_terraform
export -f validate_common_prerequisites check_azure_permissions
