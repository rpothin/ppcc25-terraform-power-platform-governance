#!/bin/bash
# ==============================================================================
# Common Utilities Library
# ==============================================================================
# Provides common utility functions used across multiple scripts
# ==============================================================================

# Source color utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/colors.sh"

# Function to clean up sensitive variables from environment
cleanup_vars() {
    local var_names=("$@")
    
    # Prevent double cleanup
    if [[ "${CLEANUP_DONE:-}" == "true" ]]; then
        return 0
    fi
    
    print_status "Cleaning up sensitive variables from memory..."
    
    # Clear specified variables or use defaults
    if [[ ${#var_names[@]} -eq 0 ]]; then
        # Default set of sensitive variables
        var_names=(
            "AZURE_CLIENT_ID" "AZURE_TENANT_ID" "AZURE_SUBSCRIPTION_ID"
            "RESOURCE_GROUP_NAME" "STORAGE_ACCOUNT_NAME" "CONTAINER_NAME"
            "GITHUB_OWNER" "GITHUB_REPO" "SP_NAME"
            "CONFIRM" "DELETE_CONFIRM" "REMOVE_ENV"
        )
    fi
    
    # Clear all specified variables
    for var_name in "${var_names[@]}"; do
        unset "$var_name"
    done
    
    # Clear bash history of this session (if running interactively)
    if [[ $- == *i* ]]; then
        history -c 2>/dev/null || true
    fi
    
    # Mark cleanup as done
    CLEANUP_DONE=true
    
    print_success "Sensitive variables cleared from memory"
}

# Function to handle script interruption
handle_script_interruption() {
    local script_name="${1:-script}"
    print_warning "$script_name interrupted by user"
    print_status "Some operations may have been partially completed"
    print_status "You can run this script again to complete or continue the process"
    print_status "or use individual scripts for specific components"
    exit 1
}

# Function to setup error handling with cleanup
setup_error_handling() {
    local cleanup_function="$1"
    
    if [[ -n "$cleanup_function" ]]; then
        trap "$cleanup_function" EXIT SIGINT SIGTERM
    else
        trap 'handle_script_interruption' SIGINT SIGTERM
    fi
}

# Function to prompt for continuation
prompt_continue() {
    local message="${1:-Press Enter to continue or Ctrl+C to abort...}"
    echo -e "${YELLOW}$message${NC}"
    echo -n "Press Enter to continue or Ctrl+C to abort..."
    read -r
    echo ""
}

# Function to get user confirmation
get_user_confirmation() {
    local message="$1"
    local default="${2:-N}"
    local response_var="$3"
    
    if [[ "$default" == "y" || "$default" == "Y" ]]; then
        echo -n "$message (Y/n): "
    else
        echo -n "$message (y/N): "
    fi
    
    read -r RESPONSE
    
    # Use default if empty response
    if [[ -z "$RESPONSE" ]]; then
        RESPONSE="$default"
    fi
    
    # Set response variable if provided
    if [[ -n "$response_var" ]]; then
        declare -g "$response_var=$RESPONSE"
    fi
    
    # Return success if confirmed
    if [[ "$RESPONSE" == "y" || "$RESPONSE" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get deletion confirmation
get_deletion_confirmation() {
    local resource_description="$1"
    
    print_danger_zone "You are about to permanently delete $resource_description. This action cannot be undone!"
    echo ""
    
    if ! get_user_confirmation "Are you absolutely sure you want to proceed?"; then
        print_error "Operation cancelled by user"
        return 1
    fi
    
    echo -n "Type 'DELETE' to confirm: "
    read -r DELETE_CONFIRM
    if [[ "$DELETE_CONFIRM" != "DELETE" ]]; then
        print_error "Operation cancelled - confirmation not received"
        return 1
    fi
    
    print_success "Deletion confirmed. Proceeding with resource removal..."
    return 0
}

# Function to run a script with error handling
run_script_with_handling() {
    local script_path="$1"
    local script_description="$2"
    local is_optional="${3:-false}"
    
    print_step "Running $script_description..."
    echo ""
    
    if [[ ! -f "$script_path" ]]; then
        if [[ "$is_optional" == "true" ]]; then
            print_warning "Script not found: $script_path (optional)"
            return 1
        else
            print_error "Script not found: $script_path"
            return 1
        fi
    fi
    
    # Make script executable
    chmod +x "$script_path"
    
    # Run the script
    if bash "$script_path"; then
        print_success "$script_description completed successfully"
        echo ""
        return 0
    else
        if [[ "$is_optional" == "true" ]]; then
            print_warning "$script_description failed but continuing..."
            echo ""
            return 1
        else
            print_error "$script_description failed"
            echo ""
            
            if get_user_confirmation "Do you want to continue with the remaining steps?"; then
                print_status "Continuing with remaining steps..."
                echo ""
                return 1
            else
                print_error "Operation aborted by user"
                exit 1
            fi
        fi
    fi
}

# Function to validate JSON with jq
validate_json() {
    local json_data="$1"
    local description="${2:-JSON data}"
    
    if echo "$json_data" | jq empty 2>/dev/null; then
        return 0
    else
        print_error "Invalid JSON in $description"
        return 1
    fi
}

# Function to mask sensitive values for display
mask_sensitive_value() {
    local value="$1"
    local show_chars="${2:-8}"
    local mask_chars="${3:-4}"
    
    if [[ -n "$value" && ${#value} -gt $((show_chars + mask_chars)) ]]; then
        echo "${value:0:$show_chars}...${value: -$mask_chars}"
    else
        echo "$value"
    fi
}

# Function to create a secure temporary file
create_secure_temp_file() {
    local prefix="${1:-temp}"
    local temp_file=$(mktemp -t "${prefix}.XXXXXX")
    chmod 600 "$temp_file"
    echo "$temp_file"
}

# Function to securely remove temporary files
cleanup_temp_files() {
    local temp_files=("$@")
    
    for temp_file in "${temp_files[@]}"; do
        if [[ -f "$temp_file" ]]; then
            # Securely overwrite and remove
            shred -u "$temp_file" 2>/dev/null || rm -f "$temp_file"
        fi
    done
}

# Function to wait with spinner
wait_with_spinner() {
    local duration="$1"
    local message="${2:-Waiting}"
    
    local spinner_chars="/-\\|"
    local end_time=$((SECONDS + duration))
    
    echo -n "$message "
    
    while [[ $SECONDS -lt $end_time ]]; do
        for ((i=0; i<${#spinner_chars}; i++)); do
            echo -ne "\b${spinner_chars:$i:1}"
            sleep 0.2
            if [[ $SECONDS -ge $end_time ]]; then
                break 2
            fi
        done
    done
    
    echo -e "\b✓"
}

# Function to retry operation with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local base_delay="$2"
    local max_delay="$3"
    shift 3
    local command=("$@")
    
    local attempt=1
    local delay=$base_delay
    
    while [[ $attempt -le $max_attempts ]]; do
        print_status "Attempt $attempt of $max_attempts: ${command[*]}"
        
        if "${command[@]}"; then
            print_success "Command succeeded on attempt $attempt"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            print_warning "Attempt $attempt failed. Waiting ${delay}s before retry..."
            sleep "$delay"
            
            # Exponential backoff with max delay
            delay=$((delay * 2))
            if [[ $delay -gt $max_delay ]]; then
                delay=$max_delay
            fi
        fi
        
        ((attempt++))
    done
    
    print_error "Command failed after $max_attempts attempts"
    return 1
}

# Export functions for use in other scripts
export -f cleanup_vars handle_script_interruption setup_error_handling
export -f prompt_continue get_user_confirmation get_deletion_confirmation
export -f run_script_with_handling validate_json mask_sensitive_value
export -f create_secure_temp_file cleanup_temp_files wait_with_spinner retry_with_backoff
