#!/bin/bash
# Test Runner for DLP Policies Configuration
#
# This script runs all tests for the 01-dlp-policies configuration
# Usage: ./run-tests.sh [unit|integration|all]

set -e

# Load shared test utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/../../../scripts/test-utils/common-helpers.sh"

# Configuration info
CONFIG_NAME="01-dlp-policies"
CONFIG_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

echo "🧪 Test Runner for $CONFIG_NAME Configuration"
echo "=============================================="
echo "Configuration Directory: $CONFIG_DIR"
echo "Test Mode: ${1:-all}"
echo "=============================================="

# Change to configuration directory
cd "$CONFIG_DIR"

# Determine what tests to run
TEST_MODE="${1:-all}"

case "$TEST_MODE" in
    "unit")
        echo -e "${BLUE}📋 Running Unit Tests Only${NC}"
        if terraform test tests/unit.tftest.hcl; then
            echo -e "${GREEN}✅ Unit tests completed successfully${NC}"
        else
            echo -e "${RED}❌ Unit tests failed${NC}"
            exit 1
        fi
        ;;
    "integration")
        echo -e "${BLUE}📋 Running Integration Tests Only${NC}"
        chmod +x tests/integration-test.sh
        ./tests/integration-test.sh
        ;;
    "all")
        echo -e "${BLUE}📋 Running All Tests${NC}"
        
        # Step 1: Unit Tests
        echo -e "\n${YELLOW}Step 1: Unit Tests${NC}"
        if terraform test tests/unit.tftest.hcl > /tmp/unit-results.log 2>&1; then
            echo -e "${GREEN}✅ Unit tests: PASSED${NC}"
            UNIT_SUCCESS=true
        else
            echo -e "${RED}❌ Unit tests: FAILED${NC}"
            echo "Unit test output:"
            cat /tmp/unit-results.log
            UNIT_SUCCESS=false
        fi
        
        # Step 2: Integration Tests
        echo -e "\n${YELLOW}Step 2: Integration Tests${NC}"
        chmod +x tests/integration-test.sh
        if ./tests/integration-test.sh; then
            INTEGRATION_SUCCESS=true
        else
            INTEGRATION_SUCCESS=false
        fi
        
        # Summary
        echo -e "\n${BLUE}========================================"
        echo -e "📊 $CONFIG_NAME Test Summary"
        echo -e "========================================${NC}"
        
        if [ "$UNIT_SUCCESS" = true ]; then
            echo -e "${GREEN}✅ Unit Tests: PASSED${NC}"
        else
            echo -e "${RED}❌ Unit Tests: FAILED${NC}"
        fi
        
        if [ "$INTEGRATION_SUCCESS" = true ]; then
            echo -e "${GREEN}✅ Integration Tests: PASSED${NC}"
        else
            echo -e "${RED}❌ Integration Tests: FAILED${NC}"
        fi
        
        if [ "$UNIT_SUCCESS" = true ] && [ "$INTEGRATION_SUCCESS" = true ]; then
            echo -e "\n${GREEN}🎉 All tests passed successfully!${NC}"
            exit 0
        else
            echo -e "\n${RED}💥 Some tests failed. Please review the output above.${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}❌ Invalid test mode: $TEST_MODE${NC}"
        echo "Usage: $0 [unit|integration|all]"
        exit 1
        ;;
esac
