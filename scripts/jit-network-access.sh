#!/bin/bash
# ==============================================================================
# Just-In-Time Network Access Manager for Terraform Backend Storage
# ==============================================================================
# This script manages dynamic IP access rules for the Terraform backend storage
# account. It adds and removes IP addresses from the storage account's network
# ACL to provide just-in-time access during GitHub Actions workflows.
# ==============================================================================

set -e  # Exit on any error

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

# Function to validate required parameters
validate_parameters() {
    if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
        print_error "STORAGE_ACCOUNT_NAME environment variable is required"
        exit 1
    fi
    
    if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
        print_error "RESOURCE_GROUP_NAME environment variable is required"
        exit 1
    fi
    
    if [[ -z "$RUNNER_IP" ]]; then
        print_error "RUNNER_IP environment variable is required"
        exit 1
    fi
}

# Function to validate Azure CLI authentication
validate_azure_auth() {
    if ! az account show &> /dev/null; then
        print_error "Azure CLI is not authenticated. Please ensure service principal is logged in."
        exit 1
    fi
}

# Function to get current IP rules from storage account
get_current_ip_rules() {
    print_status "Retrieving current IP rules from storage account: $STORAGE_ACCOUNT_NAME"
    
    az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query 'networkRuleSet.ipRules[].ipAddressOrRange' \
        --output tsv 2>/dev/null || echo ""
}

# Function to add IP address to storage account network rules
add_ip_rule() {
    local ip_address="$1"
    
    print_status "Adding IP address $ip_address to storage account network rules"
    
    # Check if IP is already in the rules
    local current_rules
    current_rules=$(get_current_ip_rules)
    
    if echo "$current_rules" | grep -q "^$ip_address$"; then
        print_warning "IP address $ip_address is already in the network rules"
        return 0
    fi
    
    # Add the IP rule
    if az storage account network-rule add \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --ip-address "$ip_address" \
        --output none; then
        print_success "Successfully added IP address $ip_address to network rules"
        
        # Wait a moment for the rule to propagate
        sleep 5
        
        # Verify the rule was added
        if get_current_ip_rules | grep -q "^$ip_address$"; then
            print_success "IP rule verification successful"
        else
            print_warning "IP rule may not have propagated yet"
        fi
    else
        print_error "Failed to add IP address $ip_address to network rules"
        exit 1
    fi
}

# Function to remove IP address from storage account network rules
remove_ip_rule() {
    local ip_address="$1"
    
    print_status "Removing IP address $ip_address from storage account network rules"
    
    # Check if IP is in the rules
    local current_rules
    current_rules=$(get_current_ip_rules)
    
    if ! echo "$current_rules" | grep -q "^$ip_address$"; then
        print_warning "IP address $ip_address is not in the network rules"
        return 0
    fi
    
    # Remove the IP rule
    if az storage account network-rule remove \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --ip-address "$ip_address" \
        --output none; then
        print_success "Successfully removed IP address $ip_address from network rules"
        
        # Wait a moment for the rule to propagate
        sleep 5
        
        # Verify the rule was removed
        if ! get_current_ip_rules | grep -q "^$ip_address$"; then
            print_success "IP rule removal verification successful"
        else
            print_warning "IP rule may not have been removed yet"
        fi
    else
        print_error "Failed to remove IP address $ip_address from network rules"
        exit 1
    fi
}

# Function to list all current IP rules
list_ip_rules() {
    print_status "Current IP rules for storage account: $STORAGE_ACCOUNT_NAME"
    
    local current_rules
    current_rules=$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query 'networkRuleSet.ipRules[].ipAddressOrRange' \
        --output tsv 2>/dev/null || echo "")
    
    if [[ -z "$current_rules" ]]; then
        print_status "  No IP rules currently configured"
    else
        echo "$current_rules" | while read -r ip; do
            if [[ -n "$ip" ]]; then
                print_status "  - $ip"
            fi
        done
    fi
}

# Function to clean up old IP rules (optional cleanup for failed workflows)
cleanup_old_rules() {
    print_status "Cleaning up potentially stale IP rules..."
    
    local current_rules
    current_rules=$(get_current_ip_rules)
    
    if [[ -z "$current_rules" ]]; then
        print_status "No IP rules to clean up"
        return 0
    fi
    
    # Remove all current IP rules (use with caution)
    echo "$current_rules" | while read -r ip; do
        if [[ -n "$ip" ]]; then
            remove_ip_rule "$ip"
        fi
    done
    
    print_success "Cleanup completed"
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 {add|remove|list|cleanup}"
    echo ""
    echo "Environment variables required:"
    echo "  STORAGE_ACCOUNT_NAME  - Name of the storage account"
    echo "  RESOURCE_GROUP_NAME   - Name of the resource group"
    echo "  RUNNER_IP            - IP address of the GitHub Actions runner"
    echo ""
    echo "Commands:"
    echo "  add      - Add runner IP to storage account network rules"
    echo "  remove   - Remove runner IP from storage account network rules"
    echo "  list     - List all current IP rules"
    echo "  cleanup  - Remove all IP rules (use with caution)"
    echo ""
    echo "Examples:"
    echo "  export STORAGE_ACCOUNT_NAME='stterraformpp1234'"
    echo "  export RESOURCE_GROUP_NAME='rg-terraform-powerplatform-governance'"
    echo "  export RUNNER_IP='52.123.45.67'"
    echo "  $0 add"
    echo "  $0 remove"
}

# Main execution
main() {
    local action="${1:-help}"
    
    case "$action" in
        "add")
            validate_parameters
            validate_azure_auth
            add_ip_rule "$RUNNER_IP"
            ;;
        "remove")
            validate_parameters
            validate_azure_auth
            remove_ip_rule "$RUNNER_IP"
            ;;
        "list")
            if [[ -z "$STORAGE_ACCOUNT_NAME" ]] || [[ -z "$RESOURCE_GROUP_NAME" ]]; then
                print_error "STORAGE_ACCOUNT_NAME and RESOURCE_GROUP_NAME environment variables are required"
                exit 1
            fi
            validate_azure_auth
            list_ip_rules
            ;;
        "cleanup")
            if [[ -z "$STORAGE_ACCOUNT_NAME" ]] || [[ -z "$RESOURCE_GROUP_NAME" ]]; then
                print_error "STORAGE_ACCOUNT_NAME and RESOURCE_GROUP_NAME environment variables are required"
                exit 1
            fi
            validate_azure_auth
            cleanup_old_rules
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run the main function
main "$@"
