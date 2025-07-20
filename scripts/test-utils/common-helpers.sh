#!/bin/bash
# Shared Test Utilities for Power Platform Terraform Configurations
# 
# This file contains common helper functions and utilities used across
# multiple configuration tests in the repository.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track test results (global variables)
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function for test status reporting
test_status() {
    local test_name="$1"
    local status="$2"
    
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to validate Terraform configuration syntax without backend
validate_terraform_syntax() {
    local config_dir="$1"
    local temp_dir="/tmp/tf-syntax-test-$$"
    
    echo "Validating Terraform syntax for: $config_dir"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Copy main configuration files (exclude backend configuration)
    cp "$config_dir"/*.tf "$temp_dir/" 2>/dev/null || true
    
    # Remove backend configuration from main.tf if it exists
    if [ -f "$temp_dir/main.tf" ]; then
        sed '/backend "azurerm"/,/}/d' "$temp_dir/main.tf" > "$temp_dir/main-no-backend.tf"
        mv "$temp_dir/main-no-backend.tf" "$temp_dir/main.tf"
    fi
    
    # Change to temp directory and test
    local current_dir="$(pwd)"
    cd "$temp_dir"
    
    local result=0
    if terraform init >/dev/null 2>&1 && terraform validate >/dev/null 2>&1; then
        result=0
    else
        result=1
    fi
    
    # Clean up
    cd "$current_dir"
    rm -rf "$temp_dir"
    
    return $result
}

# Helper function to check required environment variables for authenticated tests
check_auth_requirements() {
    local missing_vars=()
    
    if [ -z "$ARM_CLIENT_ID" ]; then
        missing_vars+=("ARM_CLIENT_ID")
    fi
    
    if [ -z "$ARM_TENANT_ID" ]; then
        missing_vars+=("ARM_TENANT_ID")
    fi
    
    if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
        missing_vars+=("ARM_SUBSCRIPTION_ID")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing authentication variables: ${missing_vars[*]}${NC}"
        return 1
    fi
    
    return 0
}

# Helper function to print test summary
print_test_summary() {
    local config_name="$1"
    
    echo ""
    echo "========================================"
    echo "🧪 $config_name Test Summary"
    echo "========================================"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Some tests failed.${NC}"
        return 1
    fi
}

# Helper function to check terraform-docs availability and version
check_terraform_docs() {
    if command_exists terraform-docs; then
        echo -e "${BLUE}ℹ️  terraform-docs version: $(terraform-docs version)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  terraform-docs not available${NC}"
        return 1
    fi
}
