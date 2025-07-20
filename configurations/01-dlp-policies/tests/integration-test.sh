#!/bin/bash
set -e

# Load shared test utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/../../../scripts/test-utils/common-helpers.sh"

echo "🧪 Running DLP Export Integration Tests"
echo "========================================"
echo "Configuration: 01-dlp-policies"
echo "Test Location: $(pwd)"
echo "========================================"

# Test 1: Configuration initialization and validation
echo -e "${YELLOW}Test 1: Configuration initialization and validation${NC}"

# Test current configuration directory (we're already in the right place)
echo "Testing configuration in: $(pwd)"

# Check if this is a hello world test (no Power Platform provider)
if ! grep -q "powerplatform" main.tf; then
    echo "Detected Hello World configuration - running simplified tests..."
    
    # For hello world, always use local backend
    echo "Running Hello World tests with local backend..."
    
    # Create a temporary test configuration without backend for hello world testing
    echo "Creating temporary hello world test configuration..."
    mkdir -p /tmp/hello-world-test-config
    cp *.tf /tmp/hello-world-test-config/ 2>/dev/null || true
    
    # Remove backend configuration for hello world testing
    cd /tmp/hello-world-test-config
    sed '/backend "azurerm"/,/}/d' main.tf > main-no-backend.tf
    mv main-no-backend.tf main.tf
    
    # Initialize and validate hello world configuration
    if terraform init > /tmp/init-hello-world.log 2>&1; then
        test_status "Terraform Init (Hello World)" 0
        
        # Validate hello world configuration
        if terraform validate > /tmp/validate-hello-world.log 2>&1; then
            test_status "Terraform Validate (Hello World)" 0
        else
            test_status "Terraform Validate (Hello World)" 1
            echo "Hello world validation log:"
            cat /tmp/validate-hello-world.log
        fi
    else
        test_status "Terraform Init (Hello World)" 1
        echo "Hello world init log:"
        cat /tmp/init-hello-world.log
    fi
    
    # Return to original directory
    ORIGINAL_CONFIG_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
    cd "$ORIGINAL_CONFIG_DIR"
    
elif [ "$RUN_AUTHENTICATED_TESTS" = "true" ] && [ -n "$ARM_CLIENT_ID" ]; then
    echo "Testing with full backend configuration..."
    if terraform init > /tmp/init.log 2>&1; then
        test_status "Terraform Init (Full Config)" 0
        
        # Validate configuration
        if terraform validate > /tmp/validate.log 2>&1; then
            test_status "Terraform Validate (Full Config)" 0
        else
            test_status "Terraform Validate (Full Config)" 1
            echo "Full validation log:"
            cat /tmp/validate.log
        fi
    else
        test_status "Terraform Init (Full Config)" 1
        echo "Full init log:"
        cat /tmp/init.log
    fi
else
    echo "Skipping full configuration test (requires backend configuration and authentication)"
    echo -e "${YELLOW}⚠️  Full Configuration Test: SKIPPED (requires backend config and ARM_CLIENT_ID)${NC}"
    
    # Create a temporary test configuration without backend for validation
    echo "Creating temporary test configuration for syntax validation..."
    mkdir -p /tmp/dlp-test-config
    cp main.tf /tmp/dlp-test-config/
    # Remove backend configuration for syntax testing
    sed '/backend "azurerm"/,/}/d' /tmp/dlp-test-config/main.tf > /tmp/dlp-test-config/main-no-backend.tf
    mv /tmp/dlp-test-config/main-no-backend.tf /tmp/dlp-test-config/main.tf
    
    cd /tmp/dlp-test-config
    if terraform init > /tmp/init-test.log 2>&1; then
        test_status "Terraform Init (Test Config)" 0
        
        # Validate test configuration
        if terraform validate > /tmp/validate-test.log 2>&1; then
            test_status "Terraform Validate (Test Config)" 0
        else
            test_status "Terraform Validate (Test Config)" 1
            echo "Test validation log:"
            cat /tmp/validate-test.log
        fi
    else
        test_status "Terraform Init (Test Config)" 1
        echo "Test init log:"
        cat /tmp/init-test.log
    fi
    
    # Return to original directory - use script directory detection
    ORIGINAL_CONFIG_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
    cd "$ORIGINAL_CONFIG_DIR"
fi

# Test 2: Format check
echo -e "\n${YELLOW}Test 2: Format verification${NC}"
if terraform fmt -check > /tmp/fmt.log 2>&1; then
    test_status "Terraform Format Check" 0
else
    test_status "Terraform Format Check" 1
    echo "Format issues found:"
    cat /tmp/fmt.log
fi

# Test 3: Unit tests execution
echo -e "\n${YELLOW}Test 3: Unit tests execution${NC}"

# Check if this is a hello world test
if ! grep -q "powerplatform" main.tf; then
    echo "Hello World configuration detected - running terraform test directly..."
    
    # For hello world, run terraform test with local backend (no external dependencies)
    cd /tmp/hello-world-test-config
    if terraform test ../../../tests/integration.tftest.hcl > /tmp/hello-world-test.log 2>&1; then
        test_status "Hello World Tests" 0
    else
        test_status "Hello World Tests" 1
        echo "Hello world test log:"
        cat /tmp/hello-world-test.log
    fi
    
    # Return to original directory
    ORIGINAL_CONFIG_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
    cd "$ORIGINAL_CONFIG_DIR"
    
elif [ "$RUN_AUTHENTICATED_TESTS" = "true" ] && check_auth_requirements; then
    echo "Running unit tests with authentication..."
    # Initialize providers for testing (without backend)
    if terraform init -backend=false > /tmp/init-for-tests.log 2>&1; then
        # Now run unit tests with initialized providers
        if terraform test tests/unit.tftest.hcl > /tmp/unit-test.log 2>&1; then
            test_status "Unit Tests" 0
        else
            test_status "Unit Tests" 1
            echo "Unit test log:"
            cat /tmp/unit-test.log
        fi
    else
        echo "Failed to initialize providers for unit tests"
        cat /tmp/init-for-tests.log
        test_status "Unit Tests" 1
    fi
else
    echo "Skipping unit tests (require Power Platform authentication)"
    echo -e "${YELLOW}⚠️  Unit Tests: SKIPPED (requires authentication)${NC}"
fi

# Test 4: Configuration-specific tests
echo -e "\n${YELLOW}Test 4: Configuration-specific integration tests${NC}"

# Check if this is a hello world test
if ! grep -q "powerplatform" main.tf; then
    echo "Hello World configuration - integration tests already run in Test 3"
    echo -e "${GREEN}✅ Integration Tests: COMPLETED (Hello World)${NC}"
elif [ "$RUN_AUTHENTICATED_TESTS" = "true" ]; then
    echo "Running authenticated integration tests..."
    echo "Note: This may take 2-5 minutes for large Power Platform tenants..."
    
    # Set timeout for integration tests (5 minutes)
    if timeout 300 terraform test tests/integration.tftest.hcl > /tmp/config-test.log 2>&1; then
        test_status "Integration Tests (Authenticated)" 0
    else
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            test_status "Integration Tests (Authenticated)" 1
            echo "Integration tests timed out after 5 minutes"
            echo "This may indicate:"
            echo "- Large Power Platform tenant with many DLP policies"
            echo "- Power Platform API latency issues"
            echo "- Network connectivity problems"
        else
            test_status "Integration Tests (Authenticated)" 1
        fi
        echo "Integration test log:"
        cat /tmp/config-test.log
    fi
else
    echo "Skipping authenticated integration tests (RUN_AUTHENTICATED_TESTS not set to true)"
    echo -e "${YELLOW}⚠️  Integration Tests: SKIPPED (requires authentication)${NC}"
fi

# Test 5: Plan execution (requires authentication)
echo -e "\n${YELLOW}Test 5: Plan execution${NC}"

# Check if this is a hello world test
if ! grep -q "powerplatform" main.tf; then
    echo "Hello World configuration - running simple plan execution..."
    
    # For hello world, run plan in the temp directory (no backend)
    cd /tmp/hello-world-test-config
    if terraform plan -out=hello-world.tfplan > /tmp/hello-world-plan.log 2>&1; then
        test_status "Terraform Plan (Hello World)" 0
        # Clean up plan file
        rm -f hello-world.tfplan
    else
        test_status "Terraform Plan (Hello World)" 1
        echo "Hello world plan log:"
        cat /tmp/hello-world-plan.log
    fi
    
    # Return to original directory
    ORIGINAL_CONFIG_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
    cd "$ORIGINAL_CONFIG_DIR"
    
elif [ "$RUN_AUTHENTICATED_TESTS" = "true" ]; then
    echo "Running plan execution test..."
    echo "Note: Plan execution may take 2-5 minutes for large Power Platform tenants..."
    
    # Set timeout for plan execution (5 minutes)
    if timeout 300 terraform plan -out=test.tfplan > /tmp/plan.log 2>&1; then
        test_status "Terraform Plan" 0
        # Clean up plan file
        rm -f test.tfplan
    else
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            test_status "Terraform Plan" 1
            echo "Terraform plan timed out after 5 minutes"
            echo "This may indicate:"
            echo "- Large Power Platform tenant with extensive DLP policies"
            echo "- Power Platform API performance issues"
            echo "- Authentication or network connectivity problems"
        else
            test_status "Terraform Plan" 1
        fi
        echo "Plan log:"
        cat /tmp/plan.log
    fi
else
    echo "Skipping plan execution test (requires authentication)"
    echo -e "${YELLOW}⚠️  Plan Execution: SKIPPED (requires authentication)${NC}"
fi

# Test 6: Documentation validation
echo -e "\n${YELLOW}Test 6: Documentation validation${NC}"

# Check if README.md exists and has required sections
if [ -f "README.md" ]; then
    if grep -q "## Requirements" README.md && grep -q "## Providers" README.md && grep -q "## Outputs" README.md; then
        test_status "Documentation Structure" 0
    else
        test_status "Documentation Structure" 1
        echo "Missing required sections in README.md"
    fi
else
    test_status "Documentation Structure" 1
    echo "README.md not found"
fi

# Test 7: terraform-docs configuration
echo -e "\n${YELLOW}Test 7: terraform-docs configuration${NC}"
if [ -f ".terraform-docs.yml" ]; then
    # Check if terraform-docs can run (if available)
    if check_terraform_docs; then
        if terraform-docs -c .terraform-docs.yml . > /tmp/docs.log 2>&1; then
            test_status "Terraform Docs Generation" 0
        else
            test_status "Terraform Docs Generation" 1
            echo "terraform-docs log:"
            cat /tmp/docs.log
        fi
    else
        echo -e "${YELLOW}⚠️  Terraform Docs: SKIPPED (terraform-docs not installed)${NC}"
    fi
    test_status "Terraform Docs Configuration" 0
else
    test_status "Terraform Docs Configuration" 1
    echo ".terraform-docs.yml not found"
fi

# Summary
print_test_summary "DLP Policies Integration"
