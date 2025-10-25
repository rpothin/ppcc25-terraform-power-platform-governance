---
description: "Bash scripting standards for PPCC25 Power Platform governance demonstration - emphasizing safety, clarity, and maintainability"
applyTo: "scripts/**"
---

# Bash Script Guidelines

## 🛡️ Script Structure and Safety

### Mandatory Safety Standards

**AI Agent Directive: ALWAYS include these safety measures in EVERY bash script:**

```bash
#!/bin/bash
# CRITICAL: These three lines are NON-NEGOTIABLE
set -euo pipefail  # Exit on error, undefined variables, pipe failures

# REQUIRED: Script metadata header (customize values)
# ==============================================================================
# Script Name: [Descriptive Name]
# Purpose: [Clear purpose statement]
# Usage: [Usage example with parameters]
# Dependencies: [Required tools, files, or environment variables]
# Author: [Maintainer information]
# ==============================================================================
```

### Safety Flag Enforcement

**AI Agent: NEVER generate a script without these flags:**

| Flag              | Purpose                      | Required | Exception Allowed |
| ----------------- | ---------------------------- | -------- | ----------------- |
| `set -e`          | Exit on command failure      | ✅ YES    | ❌ NO              |
| `set -u`          | Error on undefined variables | ✅ YES    | ❌ NO              |
| `set -o pipefail` | Detect pipeline failures     | ✅ YES    | ❌ NO              |

### Exception Handling Patterns

**AI Agent: Use these patterns for controlled error handling:**

```bash
# ✅ CORRECT: Explicit handling of expected failures
if ! command_that_might_fail; then
    print_warning "Expected condition occurred, continuing..."
    # Handle the expected failure appropriately
fi

# ✅ CORRECT: Safe variable defaulting
result="${OPTIONAL_VAR:-default_value}"

# ❌ WRONG: Never disable error handling globally
set +e  # NEVER DO THIS
```

## 📏 File Size and Modularization Requirements

### Mandatory Size Limits

**AI Agent: ENFORCE these limits strictly:**

| File Type             | Maximum Lines | Action When Exceeded |
| --------------------- | ------------- | -------------------- |
| Individual scripts    | 200 lines     | Split into modules   |
| Utility modules       | 150 lines     | Extract functions    |
| Setup/cleanup scripts | 250 lines     | Create sub-scripts   |

### Modularization Decision Tree

**AI Agent: When generating scripts, follow this decision process:**

```yaml
Script Size Check:
├─ Under 150 lines?
│  └─ ✅ Single file acceptable
├─ 150-200 lines?
│  └─ ⚠️ Consider splitting if logical boundaries exist
└─ Over 200 lines?
   └─ ❌ MUST split into modules:
      ├─ Extract common functions → scripts/utils/
      ├─ Separate setup logic → scripts/setup/
      └─ Isolate cleanup logic → scripts/cleanup/
```

### Required Directory Structure

**AI Agent: Place files according to this structure:**

```yaml
scripts/
├── setup/          # Setup and initialization scripts
├── cleanup/        # Cleanup and teardown scripts
├── utils/          # Reusable utility functions
│   ├── common.sh   # Common utilities (ALWAYS source this)
│   ├── azure.sh    # Azure-specific functions
│   └── validation.sh # Validation functions
└── templates/      # Script templates
```

## 🏷️ Naming and Documentation Standards

### Naming Conventions

**AI Agent: Apply these naming rules consistently:**

| Element          | Convention               | Example                   |
| ---------------- | ------------------------ | ------------------------- |
| Script files     | kebab-case.sh            | `setup-environment.sh`    |
| Functions        | snake_case               | `validate_azure_auth()`   |
| Local variables  | snake_case               | `local resource_group`    |
| Global variables | SCREAMING_SNAKE          | `AZURE_SUBSCRIPTION_ID`   |
| Constants        | readonly SCREAMING_SNAKE | `readonly SCRIPT_VERSION` |

### Function Documentation Template

**AI Agent: ALWAYS document functions using this format:**

```bash
# Brief description of function purpose
# Parameters:
#   $1 - parameter description (required/optional)
#   $2 - parameter description (required/optional)
# Returns:
#   0 - success condition
#   1 - specific failure condition
# Example:
#   function_name "param1" "param2"
function_name() {
    local param1="${1:?Error: parameter 1 required}"
    local param2="${2:-default_value}"
    
    # Implementation
}
```

## 🔄 Cleanup and Signal Handling

### Mandatory Cleanup Pattern

**AI Agent: ALWAYS implement cleanup for scripts that create resources:**

```bash
# REQUIRED: Cleanup function definition
cleanup() {
    local exit_code=$?
    
    # Remove temporary files
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
    
    # Unset sensitive variables
    unset AZURE_CLIENT_SECRET
    unset GH_TOKEN
    unset GITHUB_TOKEN
    
    # Restore original state if needed
    [[ -n "${ORIGINAL_DIR:-}" ]] && cd "$ORIGINAL_DIR"
    
    exit $exit_code
}

# REQUIRED: Trap setup (immediately after shebang and set flags)
trap cleanup EXIT SIGINT SIGTERM
```

## 🎨 Output and User Experience

### Color-Coded Output Functions

**AI Agent: Use these standard output functions (assume they're defined in utils/common.sh):**

```bash
# Source common utilities for consistent output
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"

# Available functions:
print_success "Operation completed successfully"
print_error "Critical error occurred"
print_warning "Non-critical issue detected"
print_info "Informational message"
print_step "Step 1: Starting operation..."
print_status "Current status: Processing..."
```

### Error Message Quality Standards

**AI Agent: Generate error messages with this level of detail:**

```bash
# ✅ GOOD: Comprehensive error with context and solution
if [[ ! -f "$config_file" ]]; then
    print_error "Configuration file not found: $config_file"
    print_info "Expected location: $(pwd)/$config_file"
    print_info "To fix: cp config.env.example $config_file"
    print_info "Then edit $config_file with your values"
    return 1
fi

# ❌ BAD: Vague error without guidance
if [[ ! -f "$config_file" ]]; then
    echo "File not found"
    exit 1
fi
```

## ⚙️ Configuration Management

### Configuration Loading Pattern

**AI Agent: Use this standard pattern for configuration:**

```bash
# REQUIRED: Configuration validation function
validate_required_config() {
    local required_vars=(
        "AZURE_SUBSCRIPTION_ID"
        "AZURE_TENANT_ID"
        "RESOURCE_GROUP_NAME"
    )
    
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required configuration:"
        printf "  - %s\n" "${missing_vars[@]}"
        return 1
    fi
    
    return 0
}

# REQUIRED: Main configuration loading
load_configuration() {
    local config_file="${1:-config.env}"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        print_info "Create from template: cp config.env.example $config_file"
        return 1
    fi
    
    source "$config_file"
    validate_required_config
}
```

## ☁️ Azure and Platform Integration

### CLI Tool Requirements

**AI Agent: Priority order for Azure/Platform operations:**

1. **FIRST CHOICE**: Azure CLI (`az`)
2. **SECOND CHOICE**: Power Platform CLI (`pac`)
3. **THIRD CHOICE**: GitHub CLI (`gh`)
4. **LAST RESORT**: REST API (with justification comment)

### CLI Authentication Validation

**AI Agent: ALWAYS validate CLI authentication before use:**

```bash
# REQUIRED: Authentication check pattern
validate_azure_auth() {
    print_step "Validating Azure CLI authentication..."
    
    # Check CLI installation
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not installed"
        print_info "Install: https://aka.ms/installazurecli"
        return 1
    fi
    
    # Check authentication
    if ! az account show &> /dev/null; then
        print_error "Not authenticated to Azure"
        print_info "Run: az login"
        return 1
    fi
    
    print_success "Azure authentication validated"
    return 0
}
```

### Retry Logic for Network Operations

**AI Agent: Implement retry logic for all network operations:**

```bash
# REQUIRED: Retry pattern for network operations
execute_with_retry() {
    local command="$1"
    local max_attempts="${2:-3}"
    local wait_seconds="${3:-5}"
    
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        if eval "$command"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            print_warning "Attempt $attempt failed, retrying in ${wait_seconds}s..."
            sleep "$wait_seconds"
            wait_seconds=$((wait_seconds * 2))  # Exponential backoff
        fi
    done
    
    print_error "Command failed after $max_attempts attempts"
    return 1
}

# Usage example
execute_with_retry "az group create --name \$RG --location \$LOCATION"
```

## 📋 Script Template Usage

### Template Selection Guide

**AI Agent: Select templates based on script purpose:**

| Purpose              | Template to Use                 | Location             |
| -------------------- | ------------------------------- | -------------------- |
| Infrastructure setup | `setup-script.template.sh`      | `scripts/templates/` |
| Resource cleanup     | `cleanup-script.template.sh`    | `scripts/templates/` |
| Utility functions    | `utility-module.template.sh`    | `scripts/templates/` |
| Validation checks    | `validation-script.template.sh` | `scripts/templates/` |

## ✅ Quality Checklist

### Pre-Generation Checklist

**AI Agent: Verify these before generating any script:**

- [ ] **Safety flags**: `set -euo pipefail` present
- [ ] **Header block**: Complete with all metadata
- [ ] **File size**: Under 200 lines (or justified)
- [ ] **Cleanup trap**: Implemented if resources created
- [ ] **Error handling**: Meaningful messages with fixes
- [ ] **Authentication**: CLI auth validated before use
- [ ] **Configuration**: Required vars validated
- [ ] **Documentation**: Functions documented
- [ ] **Naming**: Follows conventions consistently
- [ ] **Output**: Uses standard print functions

## 🚫 Common Anti-Patterns to Avoid

### AI Agent: NEVER generate these patterns:

```bash
# ❌ NEVER: Hardcoded credentials
AZURE_CLIENT_SECRET="abc123"  # NEVER DO THIS

# ❌ NEVER: Disabled error handling
set +e  # NEVER DO THIS

# ❌ NEVER: Unquoted variables
if [ $var = "value" ]; then  # WRONG

# ❌ NEVER: Missing error checks
az group create --name rg --location eastus  # WRONG - no error check

# ❌ NEVER: Global variables without readonly
SCRIPT_VERSION="1.0"  # WRONG - should be readonly

# ❌ NEVER: Commands in backticks
result=`command`  # WRONG - use $() instead

# ❌ NEVER: Unclear error messages
[[ -f "$file" ]] || exit 1  # WRONG - no context
```

## 🎯 Script Generation Workflow

### AI Agent Script Generation Process:

1. **Determine script type** → Select appropriate template
2. **Check file size estimate** → Plan modularization if needed
3. **Include safety measures** → Add required flags and traps
4. **Implement core logic** → Follow patterns from this guide
5. **Add error handling** → Comprehensive messages with fixes
6. **Document thoroughly** → Headers, functions, complex logic
7. **Validate output** → Check against quality checklist

## 📝 Example: Complete Minimal Script

**AI Agent: Use this as your minimum viable script template:**

```bash
#!/bin/bash
# ==============================================================================
# Script Name: example-setup.sh
# Purpose: Demonstrate minimal viable script structure
# Usage: ./example-setup.sh [--auto-approve]
# Dependencies: Azure CLI, config.env
# Author: PPCC25 Demo
# ==============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

# Cleanup function
cleanup() {
    local exit_code=$?
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
    exit $exit_code
}
trap cleanup EXIT SIGINT SIGTERM

# Main function
main() {
    print_step "Starting example setup..."
    
    # Load configuration
    if ! load_configuration; then
        print_error "Failed to load configuration"
        return 1
    fi
    
    # Validate prerequisites
    if ! validate_azure_auth; then
        return 1
    fi
    
    # Perform operations
    print_info "Executing main logic..."
    # Add your logic here
    
    print_success "Setup completed successfully"
    return 0
}

# Execute main function
main "$@"
```

---

**AI Agent Final Directive**: This document is your authoritative guide for bash script generation. Every script you create MUST comply with these standards. When in doubt, choose safety and clarity over brevity. The quality of the PPCC25 demonstration depends on consistent, reliable, and maintainable scripts.