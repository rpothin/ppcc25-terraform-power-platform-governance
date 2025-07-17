#!/bin/bash
# ==============================================================================
# GitHub Authentication and Operations Utilities
# ==============================================================================
# Provides common GitHub authentication and operations functions
# ==============================================================================

# Source color utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/colors.sh"

# Function to test GitHub secrets access
test_github_secrets_access() {
    local repo="$1"
    local environment_name="${2:-production}"
    
    print_status "Testing secrets access for repository: $repo (environment: $environment_name)"
    
    if gh secret list --repo "$repo" --env "$environment_name" --json name &> /dev/null; then
        print_success "✅ GitHub secrets access confirmed"
        return 0
    else
        print_warning "❌ GitHub secrets access failed"
        return 1
    fi
}

# Function to perform GitHub login with required scopes
perform_github_login() {
    print_status "🔐 Authenticating with GitHub (this will open your browser)..."
    
    # Clear any existing token that might have insufficient scopes
    unset GITHUB_TOKEN
    
    # Authenticate with required scopes for secrets and environment management
    if gh auth login --scopes "repo"; then
        print_success "✅ GitHub authentication successful!"
        
        # Verify the new authentication works
        if gh api user --silent &> /dev/null; then
            print_success "✅ GitHub authentication verified and working"
            return 0
        else
            print_error "GitHub authentication succeeded but API access failed"
            return 1
        fi
    else
        print_error "GitHub authentication failed"
        return 1
    fi
}

# Function to authenticate with GitHub (with retry logic)
authenticate_github() {
    print_status "Checking GitHub authentication..."
    
    # Clear any existing GITHUB_TOKEN that might interfere
    unset GITHUB_TOKEN
    
    # First, check if user is logged in to GitHub at all
    if ! gh auth status &> /dev/null; then
        print_status "Not logged in to GitHub. Authentication required."
        perform_github_login
        return $?
    fi
    
    # Check if we have the repo scope needed for secrets and environments
    if gh auth status --show-token &> /dev/null; then
        print_status "Testing GitHub authentication with current token..."
        
        # Check if we have the proper token scopes
        local token_scopes=$(gh auth status --show-token 2>/dev/null | grep "Token scopes:" | cut -d: -f2 | tr -d ' ')
        
        if [[ "$token_scopes" == *"repo"* ]]; then
            if gh api user --silent &> /dev/null; then
                print_success "GitHub authentication verified and working"
                return 0
            else
                print_warning "API access failed with current token"
            fi
        else
            print_warning "Current GitHub token has insufficient scopes: $token_scopes"
        fi
    fi
    
    # If we get here, we need to re-authenticate
    print_status "GitHub re-authentication required for secrets and environment management..."
    perform_github_login
    return $?
}

# Function to verify repository access and permissions
verify_repository_access() {
    local github_repository="$1"
    local require_admin="${2:-true}"
    
    print_status "Verifying repository access..."
    
    # Check if repository exists and user has access
    if gh repo view "$github_repository" &> /dev/null; then
        print_success "Repository access verified"
    else
        print_error "Cannot access repository $github_repository"
        print_error "Please ensure the repository exists and you have access"
        return 1
    fi
    
    # Check admin access if required
    if [[ "$require_admin" == "true" ]]; then
        local permission=$(gh api "repos/$github_repository" --jq '.permissions.admin' 2>/dev/null)
        if [[ "$permission" != "true" ]]; then
            print_error "You need admin access to the repository for this operation"
            return 1
        fi
        print_success "Admin access confirmed"
    fi
    
    return 0
}

# Function to ensure GitHub secrets access
ensure_github_secrets_access() {
    local github_repository="$1"
    local environment_name="${2:-production}"
    
    # Test secrets access
    if ! test_github_secrets_access "$github_repository" "$environment_name"; then
        print_warning "Secrets access test failed. Attempting re-authentication..."
        
        if perform_github_login; then
            # Test again after re-authentication
            if test_github_secrets_access "$github_repository" "$environment_name"; then
                print_success "Secrets access restored after re-authentication"
                return 0
            else
                print_error "Secrets access still failed after re-authentication"
                return 1
            fi
        else
            print_error "Re-authentication failed"
            return 1
        fi
    fi
    
    return 0
}

# Function to create or update GitHub secret
create_github_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local github_repository="$3"
    local environment_name="${4:-production}"
    
    print_status "Creating secret: $secret_name"
    
    # Create or update the secret securely in the specified environment
    if echo "$secret_value" | gh secret set "$secret_name" --repo "$github_repository" --env "$environment_name" 2>/dev/null; then
        print_success "✓ Secret $secret_name created successfully"
        return 0
    else
        print_error "✗ Failed to create secret $secret_name"
        return 1
    fi
}

# Function to delete GitHub secret
delete_github_secret() {
    local secret_name="$1"
    local github_repository="$2"
    local environment_name="${3:-production}"
    
    print_status "Removing secret: $secret_name"
    
    # Try to remove the secret
    if gh secret delete "$secret_name" --repo "$github_repository" --env "$environment_name" 2>/dev/null; then
        print_success "✓ Secret $secret_name removed successfully"
        return 0
    else
        # Check if secret exists to determine if it's a failure or not found
        local existing_secrets=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null || echo "")
        
        if echo "$existing_secrets" | grep -q "^$secret_name$" 2>/dev/null; then
            print_error "✗ Failed to remove secret $secret_name"
            return 1
        else
            print_warning "⚠ Secret $secret_name not found (may have been already removed)"
            return 0
        fi
    fi
}

# Function to create GitHub environment
create_github_environment() {
    local github_repository="$1"
    local environment_name="${2:-production}"
    
    print_status "Creating GitHub environment: $environment_name"
    
    # Create environment with basic protection rules
    if gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$github_repository/environments/$environment_name" \
        -F "deployment_branch_policy[protected_branches]=true" \
        -F "deployment_branch_policy[custom_branch_policies]=false" \
        > /dev/null 2>&1; then
        
        print_success "Environment '$environment_name' created successfully"
        return 0
    else
        print_error "Failed to create environment '$environment_name'"
        return 1
    fi
}

# Function to delete GitHub environment
delete_github_environment() {
    local github_repository="$1"
    local environment_name="${2:-production}"
    
    print_status "Deleting GitHub environment: $environment_name"
    
    # Check if environment exists
    if ! gh api "repos/$github_repository/environments/$environment_name" &> /dev/null; then
        print_warning "Environment '$environment_name' not found"
        return 0
    fi
    
    # Delete environment
    if gh api "repos/$github_repository/environments/$environment_name" --method DELETE &> /dev/null; then
        print_success "✓ Environment '$environment_name' removed successfully"
        return 0
    else
        print_warning "⚠ Failed to remove environment '$environment_name'"
        return 1
    fi
}

# Function to verify secrets were created
verify_github_secrets() {
    local github_repository="$1"
    local environment_name="${2:-production}"
    shift 2
    local required_secrets=("$@")
    
    print_status "Verifying created secrets..."
    
    # List all environment secrets
    local existing_secrets=$(gh secret list --repo "$github_repository" --env "$environment_name" --json name --jq '.[].name' 2>/dev/null)
    
    # Check each required secret
    local all_found=true
    for secret in "${required_secrets[@]}"; do
        if echo "$existing_secrets" | grep -q "^$secret$"; then
            print_success "✓ Secret $secret verified"
        else
            print_error "✗ Secret $secret not found"
            all_found=false
        fi
    done
    
    if [[ "$all_found" == "true" ]]; then
        print_success "All required secrets verified successfully"
        return 0
    else
        print_error "Some secrets verification failed"
        return 1
    fi
}

# Export functions for use in other scripts
export -f test_github_secrets_access perform_github_login authenticate_github
export -f verify_repository_access ensure_github_secrets_access
export -f create_github_secret delete_github_secret
export -f create_github_environment delete_github_environment verify_github_secrets
