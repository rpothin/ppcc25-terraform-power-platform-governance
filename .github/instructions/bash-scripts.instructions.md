---
description: "Bash scripting standards"
applyTo: "scripts/**"
---

# Bash Script Guidelines

## Script Structure and Safety

### Mandatory Safety Standards

All scripts **MUST** include these safety measures:

```bash
#!/bin/bash
# REQUIRED: Full error handling and safety flags
set -euo pipefail  # Exit on error, undefined variables, pipe failures

# REQUIRED: Script metadata header
# ==============================================================================
# Script Name: [Descriptive Name]
# Purpose: [Clear purpose statement]
# Usage: [Usage example with parameters]
# Dependencies: [Required tools, files, or environment variables]
# Author: [Maintainer information]
# ==============================================================================
```

#### Safety Flag Requirements

- `set -e` — Exit immediately on any command failure
- `set -u` — Treat undefined variables as errors
- `set -o pipefail` — Ensure pipeline failures are detected

#### Exception Handling

When you need to handle expected failures, use explicit error handling:

```bash
# GOOD: Explicit error handling for expected failures
if ! command_that_might_fail; then
    print_warning "Expected condition occurred, continuing..."
    # Handle the expected failure appropriately
fi

# GOOD: Temporary variable override when needed
result="${OPTIONAL_VAR:-default_value}"
```

### File Size and Modularization Requirements

#### Mandatory Size Limits

Following the baseline principle of **Modularity Over Long and Complex Files**:

- **Individual script files**: **MAXIMUM 200 lines**
- **Utility modules**: **MAXIMUM 150 lines**
- **Setup/cleanup scripts**: **MAXIMUM 250 lines** (due to orchestration complexity)

#### Exception Process

Scripts exceeding limits require:

- **Documented justification** in header comment with architectural reasoning
- **Modularization plan** with timeline for splitting
- **Architecture review approval** before merge

#### Modularization Patterns

```bash
# GOOD: Extract functions to utility modules
source "$SCRIPT_DIR/../utils/azure-auth.sh"
source "$SCRIPT_DIR/../utils/config-validator.sh"

# Main script focuses on orchestration
validate_prerequisites
setup_azure_resources
configure_terraform_backend
```

#### Required Directory Structure

Scripts should follow the established directory structure:

- `scripts/setup/` - Setup and initialization scripts
- `scripts/cleanup/` - Cleanup and teardown scripts
- `scripts/utils/` - Reusable utility functions and modules

## Function and Variable Standards

### Naming and Scope Management

Following the baseline principle of **Keep It Simple**:

- Use descriptive function names with snake_case convention
- Declare variables with appropriate scope (local vs global)
- Quote variables to prevent word splitting: `"$variable"`
- Use arrays for lists and `readonly` for constants

#### Function Documentation Standards

```bash
# Brief description of function purpose
# Parameters:
#   $1 - parameter description
#   $2 - parameter description
# Returns:
#   0 - success
#   1 - failure with specific meaning
function_name() {
    local param1="$1"
    local param2="$2"
    # Function implementation
}
```

#### Variable Management

```bash
# GOOD: Proper variable scoping and documentation
readonly SCRIPT_VERSION="1.0.0"
readonly CONFIG_FILE="config.env"

setup_azure_resources() {
    local resource_group="$1"
    local location="$2"
    # Local variables prevent global scope pollution
    local storage_account="${resource_group}storage"
    # Implementation details
}
```

### Cleanup and Signal Handling

#### Cleanup Requirements

Scripts must handle cleanup properly:

- **Temporary files**: Always remove created temporary files
- **Sensitive variables**: Unset variables containing secrets or tokens
- **Resource state**: Restore original configuration when appropriate
- **Network access**: Remove temporary firewall rules or access permissions

#### Signal Handling Patterns

```bash
# Pattern for scripts that create temporary resources
setup_temporary_resources() {
    TEMP_DIR=$(mktemp -d)
    TEMP_STORAGE_RULE="temp-rule-$$"
    
    # Ensure cleanup happens on any exit
    trap 'cleanup_temporary_resources' EXIT SIGINT SIGTERM
    
    # Main operation
    perform_operations
    
    # Manual cleanup on success
    cleanup_temporary_resources
    trap - EXIT  # Remove trap after successful cleanup
}
```

## Error Handling and User Experience

### Comprehensive Error Handling

Following the baseline principle of **Keep It Simple**:

- Implement meaningful error messages with actionable guidance
- Use color-coded output functions (print_success, print_error, print_warning)
- Provide progress indicators and status updates for long operations
- Include validation of prerequisites and dependencies

#### Enhanced Error Message Standards

```bash
# GOOD: Comprehensive error reporting with context
validate_file_exists() {
    local file_path="$1"
    local file_description="$2"
    
    if [[ ! -f "$file_path" ]]; then
        print_error "$file_description not found: $file_path"
        print_status "Expected location: $file_path"
        print_status "Current directory: $(pwd)"
        print_status "Available files: $(ls -la "$(dirname "$file_path")" 2>/dev/null || echo "Directory not accessible")"
        print_warning "To fix: Create the required file or check the path"
        return 1
    fi
    
    print_success "$file_description found: $file_path"
    return 0
}
```

#### Progress Indicators and Status Updates

```bash
# Enhanced progress reporting for long operations
perform_long_operation() {
    local operation_name="$1"
    local total_steps="$2"
    
    print_step "Starting $operation_name..."
    
    for ((i=1; i<=total_steps; i++)); do
        print_status "Processing step $i of $total_steps..."
        
        # Actual operation
        if ! perform_step "$i"; then
            print_error "Failed at step $i of $total_steps"
            return 1
        fi
        
        print_progress "$i" "$total_steps"
    done
    
    print_success "$operation_name completed successfully"
}
```

## Configuration Management

### Standardized Configuration Patterns

Following the baseline principle of **Reusability Over Code Duplication**:

- Source utility functions from common libraries
- Load configuration from standardized config files (config.env)
- Validate required configuration values before proceeding
- Support both interactive and automated execution modes

#### Configuration Loading Standards

```bash
# REQUIRED: Standardized configuration loading
load_configuration() {
    local config_file="${1:-config.env}"
    
    # Validate configuration file exists
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        print_status "Create from template: cp config.env.example $config_file"
        return 1
    fi
    
    # Source configuration with error handling
    if ! source "$config_file"; then
        print_error "Failed to load configuration from: $config_file"
        return 1
    fi
    
    # Validate required configuration
    validate_required_config
    
    print_success "Configuration loaded from: $config_file"
}

# REQUIRED: Configuration validation
validate_required_config() {
    local required_vars=(
        "AZURE_SUBSCRIPTION_ID"
        "AZURE_TENANT_ID"
        "GITHUB_REPOSITORY"
        "TERRAFORM_STORAGE_ACCOUNT"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required configuration variables:"
        printf "  - %s\n" "${missing_vars[@]}"
        print_status "Please set these variables in your configuration file"
        return 1
    fi
    
    print_success "All required configuration variables are set"
}
```

#### Interactive vs Automated Mode Support

```bash
# Support both interactive and automated execution
prompt_user_confirmation() {
    local message="$1"
    local auto_approve="${AUTO_APPROVE:-false}"
    
    if [[ "$auto_approve" == "true" ]]; then
        print_status "Auto-approve enabled: $message"
        return 0
    fi
    
    print_warning "$message"
    read -p "Do you want to continue? (y/N): " -r response
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            print_status "Operation cancelled by user"
            return 1
            ;;
    esac
}
```

## Azure and Platform Integration

### Cloud CLI Standards (Required)

Following the baseline principle of **Security by Design**:

- **MUST** use Azure CLI (az) for all Azure resource interactions
- **MUST** use Power Platform CLI (pac) for all Power Platform operations
- **MUST** use GitHub CLI (gh) for all GitHub API interactions
- **EXCEPTION ONLY**: If CLI doesn't support required functionality, document justification

#### Enhanced CLI Authentication Requirements

```bash
# REQUIRED: Comprehensive authentication validation
validate_cli_authentication() {
    local cli_tool="$1"
    local check_command="$2"
    local auth_command="$3"
    
    print_step "Validating $cli_tool authentication..."
    
    # Check CLI installation
    if ! command -v "$cli_tool" &> /dev/null; then
        print_error "$cli_tool is not installed"
        print_status "Install instructions: https://docs.microsoft.com/cli"
        return 1
    fi
    
    # Check authentication status with timeout and retry
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if timeout 30s $check_command &> /dev/null; then
            print_success "$cli_tool authentication verified"
            
            # Validate token expiration if applicable
            if [[ "$cli_tool" == "az" ]]; then
                validate_azure_token_expiration
            fi
            
            return 0
        fi
        
        print_warning "$cli_tool authentication check failed (attempt $attempt/$max_attempts)"
        
        if [[ $attempt -eq $max_attempts ]]; then
            print_error "$cli_tool is not authenticated"
            print_status "To fix: Run '$auth_command' to authenticate"
            return 1
        fi
        
        ((attempt++))
        sleep 2
    done
}

# Enhanced token expiration validation
validate_azure_token_expiration() {
    local token_info
    if token_info=$(az account get-access-token --query "expiresOn" -o tsv 2>/dev/null); then
        local expires_epoch
        expires_epoch=$(date -d "$token_info" +%s 2>/dev/null)
        local current_epoch
        current_epoch=$(date +%s)
        local time_remaining=$((expires_epoch - current_epoch))
        
        if [[ $time_remaining -lt 600 ]]; then  # Less than 10 minutes
            print_warning "Azure token expires soon (${time_remaining}s remaining)"
            print_status "Consider running 'az login' to refresh token"
        fi
    fi
}
```

#### Enhanced Retry Logic and Error Handling

```bash
# REQUIRED: Robust retry logic for network operations
execute_with_retry() {
    local command="$1"
    local max_attempts="${2:-3}"
    local wait_seconds="${3:-5}"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        print_status "Executing: $command (attempt $attempt/$max_attempts)"
        
        # Execute command with timeout
        if timeout 300s bash -c "$command"; then
            print_success "Command succeeded on attempt $attempt"
            return 0
        fi
        
        local exit_code=$?
        
        if [[ $attempt -eq $max_attempts ]]; then
            print_error "Command failed after $max_attempts attempts: $command"
            print_error "Exit code: $exit_code"
            return $exit_code
        fi
        
        print_warning "Command failed (exit code: $exit_code), retrying in $wait_seconds seconds..."
        sleep "$wait_seconds"
        ((attempt++))
        
        # Exponential backoff for network issues
        wait_seconds=$((wait_seconds * 2))
    done
}

# Azure resource conflict handling
handle_azure_naming_conflicts() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_group="$3"
    
    print_step "Checking for naming conflicts: $resource_name"
    
    if azure_resource_exists "$resource_type" "$resource_name" "$resource_group"; then
        print_warning "Resource already exists: $resource_name"
        
        if ! prompt_user_confirmation "Do you want to use the existing resource?"; then
            # Generate alternative name
            local timestamp
            timestamp=$(date +%s)
            local alternative_name="${resource_name}-${timestamp}"
            
            print_status "Using alternative name: $alternative_name"
            echo "$alternative_name"
            return 0
        fi
    fi
    
    echo "$resource_name"
}
```

### CLI Usage Requirements

- Verify CLI installation and authentication before operations
- Use proper authentication checks (az account show, pac auth list, gh auth status)
- Implement retry logic for network operations
- Handle Azure resource naming conflicts gracefully
- Use JSON output format for programmatic processing (--output json)

### Alternative Approach Justification

When CLI tools cannot fulfill requirements, include detailed comment justification:

```bash
# JUSTIFICATION: Using REST API instead of Azure CLI because:
# - Azure CLI does not support custom policy assignments for this resource type
# - Required for compliance with organizational governance requirements
# - CLI enhancement request submitted: https://github.com/Azure/azure-cli/issues/XXXXX
curl -X POST "https://management.azure.com/..." \
     -H "Authorization: Bearer $access_token" \
     -H "Content-Type: application/json"
```

### Authentication Best Practices

- Use managed identities or service principals (avoid personal accounts in automation)
- Implement proper token refresh mechanisms
- Handle authentication failures gracefully with clear error messages
- Document required permissions and scopes

## Script Templates and Standardization

### Required Script Templates

Following the baseline principle of **Reusability Over Code Duplication**:

All new scripts **MUST** use approved templates from `scripts/templates/`:

```bash
# Generate new script from template
./scripts/utils/create-script.sh --template setup --name my-setup-script
./scripts/utils/create-script.sh --template utility --name my-utility-module
./scripts/utils/create-script.sh --template cleanup --name my-cleanup-script
```

#### Template Categories

- `setup-script.template.sh` — Infrastructure setup and configuration scripts
- `cleanup-script.template.sh` — Resource cleanup and teardown scripts
- `utility-module.template.sh` — Reusable utility functions and modules
- `validation-script.template.sh` — Validation and testing scripts

#### Template Compliance Validation

```bash
# REQUIRED: Validate script compliance before commit
./scripts/utils/validate-script-compliance.sh path/to/script.sh
```

**Validates:**

- Proper shebang and safety flags
- Required header format and metadata
- File size limits and modular design
- Signal handling and cleanup implementation
- CLI integration and authentication patterns

### Script Header Standardization

```bash
#!/bin/bash
# ==============================================================================
# Script Name: [Descriptive Name]
# ==============================================================================
# Purpose: [Clear, single-sentence purpose statement]
# 
# Usage:
#   ./script-name.sh [OPTIONS]
#   
# Examples:
#   ./script-name.sh --resource-group mygroup --location eastus
#   ./script-name.sh --config custom.env --auto-approve
#
# Dependencies:
#   - Azure CLI (az) - authenticated and configured
#   - GitHub CLI (gh) - authenticated with repo permissions
#   - Required environment variables: AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID
#   - Configuration file: config.env (or specified with --config)
#
# Author: [Maintainer Name/Team]
# Last Modified: [Date]
# ==============================================================================

set -euo pipefail  # Exit on error, undefined variables, pipe failures
```

## Automated Compliance and Quality Control

### Pre-commit Validation Requirements

All scripts **MUST** pass automated validation before commit:

```bash
# REQUIRED: Run before committing any script changes
./scripts/utils/validate-all-scripts.sh
```

**Comprehensive validation includes:**

- Safety flags verification (set -euo pipefail)
- File size and complexity limits
- Header format and documentation completeness
- Signal handling and cleanup implementation
- CLI integration patterns and authentication
- Code quality and style consistency

### Development Environment Integration

- **Shell linting**: shellcheck integration for syntax and best practice validation
- **Real-time validation**: Immediate feedback on compliance violations
- **Template scaffolding**: Easy script creation with proper structure
- **Automated testing**: Unit tests for utility functions and integration tests for workflows

### Quality Gates and Enforcement

- **PR Requirements**: All scripts must pass compliance validation
- **Continuous monitoring**: Regular audits of script quality and consistency
- **Automated remediation**: Scripts to fix common compliance issues automatically

#### Compliance Scoring System

```bash
# Automated compliance scoring for continuous improvement
calculate_script_compliance_score() {
    local script_path="$1"
    local score=0
    local max_score=100
    
    # Safety flags (20 points)
    if grep -q "set -euo pipefail" "$script_path"; then
        score=$((score + 20))
    fi
    
    # Proper header (15 points)
    if validate_script_header "$script_path"; then
        score=$((score + 15))
    fi
    
    # File size compliance (15 points)
    if validate_file_size "$script_path"; then
        score=$((score + 15))
    fi
    
    # Signal handling (20 points)
    if validate_signal_handling "$script_path"; then
        score=$((score + 20))
    fi
    
    # CLI integration (15 points)
    if validate_cli_usage "$script_path"; then
        score=$((score + 15))
    fi
    
    # Documentation quality (15 points)
    if validate_documentation_quality "$script_path"; then
        score=$((score + 15))
    fi
    
    echo "$score/$max_score"
}
```

## Integration with Repository Standards

### Changelog Integration

Following the baseline principle of **Changelog Maintenance**:

- Always check CHANGELOG.md when making changes to scripts
- Update the Unreleased section for notable additions, changes, or fixes
- Follow established format with clear categorization

#### Examples of changelog-worthy changes

- New script creation or major script modifications
- Changes to utility modules or shared functions
- Security improvements or authentication updates
- Performance optimizations or reliability improvements

#### Examples that may not need changelog updates

- Minor comment updates or formatting fixes
- Internal refactoring without functional changes
- Template updates that don't affect existing scripts

### Development Workflow Integration

- **Use Templates**: Start with approved template for consistency
- **Validate Early**: Run compliance checks during development
- **Document Thoroughly**: Include all required documentation sections
- **Test Completely**: Validate functionality and compliance before PR
- **Monitor Continuously**: Track compliance metrics post-deployment

#### Quality Assurance Process

```bash
# Complete quality assurance workflow
qa_script_submission() {
    local script_path="$1"
    
    print_step "Running quality assurance for: $script_path"
    
    # 1. Syntax validation
    if ! shellcheck "$script_path"; then
        print_error "Shellcheck validation failed"
        return 1
    fi
    
    # 2. Compliance validation
    if ! validate_script_compliance "$script_path"; then
        print_error "Compliance validation failed"
        return 1
    fi
    
    # 3. Integration testing
    if ! run_integration_tests "$script_path"; then
        print_error "Integration tests failed"
        return 1
    fi
    
    # 4. Generate compliance report
    local score
    score=$(calculate_script_compliance_score "$script_path")
    print_success "Quality assurance passed (Score: $score)"
    
    return 0
}
```

## Performance and Reliability Standards

### Performance Optimization Guidelines

- Minimize external command calls within loops
- Use built-in bash features when possible
- Implement proper caching for expensive operations
- Profile long-running scripts for bottlenecks

### Reliability Patterns

```bash
# Robust file operations with verification
safe_file_operation() {
    local operation="$1"
    local source="$2"
    local destination="$3"
    
    case "$operation" in
        "copy")
            if ! cp "$source" "$destination"; then
                print_error "Failed to copy $source to $destination"
                return 1
            fi
            
            # Verify copy integrity
            if ! cmp -s "$source" "$destination"; then
                print_error "Copy verification failed: files differ"
                rm -f "$destination"  # Clean up failed copy
                return 1
            fi
            ;;
        "move")
            if ! mv "$source" "$destination"; then
                print_error "Failed to move $source to $destination"
                return 1
            fi
            ;;
        *)
            print_error "Unknown operation: $operation"
            return 1
            ;;
    esac
    
    print_success "$operation completed: $source -> $destination"
}
```

This enhanced bash scripting guidelines document provides comprehensive standards that prevent the issues identified in the remediation plan while maintaining the educational focus and clarity required for the PPCC25 demonstration repository.

This enhanced version integrates all the key improvements from the analysis while maintaining compatibility with the existing baseline principles. The additions focus on proactive compliance enforcement, clear safety standards, template-based development, and automated validation to prevent the issues identified in the scripts remediation plan.

