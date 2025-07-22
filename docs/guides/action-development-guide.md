# GitHub Actions Development Guide

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

> **Comprehensive guide for developing and maintaining composite GitHub Actions**  
> *Standards, patterns, and best practices for the Power Platform Governance project*

## 🎯 Overview

This guide provides standards and best practices for developing, testing, and maintaining composite GitHub Actions in the Power Platform Governance project. It focuses on the specific patterns and requirements established in this project.

## 🏗️ Action Architecture

### Standard Directory Structure

All composite actions follow this standardized structure:

```
.github/actions/
├── action-name/
│   ├── action.yml              # Action definition (required)
│   ├── README.md              # Action documentation
│   └── tests/                 # Test files (optional)
│       ├── test-action.yml    # Test workflow
│       └── test-cases/        # Test case files
```

### Action Categories

Our actions are organized into three main categories:

1. **Core Infrastructure Actions**
   - `terraform-init-with-backend` - Terraform initialization with state management
   - `generate-workflow-metadata` - AVM-compliant metadata generation

2. **Development Workflow Actions**  
   - `detect-terraform-changes` - Change detection and path processing

3. **Utility Actions**
   - Future additions as needed

## 📝 Action Development Standards

### 1. Action Metadata (`action.yml`)

Every action must include comprehensive metadata:

```yaml
name: 'Action Display Name'
description: 'Clear, concise description of what the action does (max 125 chars)'
author: 'Power Platform Governance Team'

# Branding (optional but recommended)
branding:
  icon: 'tool'  # Choose appropriate Feather icon
  color: 'blue' # blue, green, yellow, orange, red, purple, gray-dark

inputs:
  required-input:
    description: 'Clear description of required input'
    required: true
  optional-input:
    description: 'Clear description with default behavior'
    required: false
    default: 'default-value'

outputs:
  output-name:
    description: 'Description of output value'
    value: ${{ steps.step-id.outputs.value }}

runs:
  using: 'composite'
  steps:
    # Action implementation
```

### 2. Input Validation Patterns

Always validate inputs at the beginning of your action:

```yaml
- name: Validate Inputs
  shell: bash
  run: |
    # Required input validation
    if [ -z "${{ inputs.required-input }}" ]; then
      echo "::error title=Missing Input::required-input is mandatory"
      exit 1
    fi
    
    # Format validation
    if [[ ! "${{ inputs.version }}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "::error title=Invalid Format::version must be in semver format (x.y.z)"
      exit 1
    fi
    
    # Path validation
    if [ -n "${{ inputs.target-path }}" ] && [ ! -d "${{ inputs.target-path }}" ]; then
      echo "::error title=Path Not Found::target-path '${{ inputs.target-path }}' does not exist"
      exit 1
    fi
```

### 3. Output Handling Standards

Use consistent patterns for setting outputs:

```yaml
# Single-line outputs
- name: Set Simple Output
  shell: bash
  run: |
    result="computed-value"
    echo "simple-output=$result" >> $GITHUB_OUTPUT

# Multi-line outputs (heredoc pattern)
- name: Set Multi-line Output
  shell: bash
  run: |
    multi_line_content="line 1
    line 2
    line 3"
    
    {
      echo "multi-output<<OUTPUT_EOF"
      echo "$multi_line_content"
      echo "OUTPUT_EOF"
    } >> $GITHUB_OUTPUT

# JSON outputs
- name: Set JSON Output
  shell: bash
  run: |
    json_data=$(jq -n \
      --arg key1 "value1" \
      --arg key2 "value2" \
      '{"key1": $key1, "key2": $key2}')
    
    {
      echo "json-output<<JSON_EOF"
      echo "$json_data"
      echo "JSON_EOF"
    } >> $GITHUB_OUTPUT
```

### 4. Error Handling Patterns

Implement robust error handling with clear messaging:

```yaml
- name: Operation with Error Handling
  shell: bash
  run: |
    # Set error handling
    set -euo pipefail
    
    # Function for consistent error reporting
    report_error() {
      echo "::error title=$1::$2"
      echo "::error::Context: $3"
      exit 1
    }
    
    # Operation with retry logic
    max_retries=3
    retry_count=0
    success=false
    
    while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
      retry_count=$((retry_count + 1))
      echo "::notice title=Attempt::Trying operation (attempt $retry_count of $max_retries)"
      
      if perform_operation; then
        success=true
        echo "::notice title=Success::Operation completed on attempt $retry_count"
      else
        echo "::warning title=Retry::Operation failed on attempt $retry_count"
        if [ $retry_count -lt $max_retries ]; then
          sleep_time=$((retry_count * 5))
          echo "::notice title=Wait::Waiting ${sleep_time}s before retry"
          sleep $sleep_time
        fi
      fi
    done
    
    if [ "$success" = false ]; then
      report_error "Operation Failed" "Failed after $max_retries attempts" "Check logs above for details"
    fi
```

### 5. Logging and Notification Standards

Use GitHub's workflow commands consistently:

```yaml
- name: Structured Logging Example
  shell: bash
  run: |
    # Different log levels
    echo "::notice title=Operation Start::🚀 Starting terraform initialization"
    echo "::warning title=Deprecation::This input parameter will be removed in v2.0"
    echo "::error title=Critical Issue::Configuration file not found"
    
    # Group related logs
    echo "::group::Terraform Version Information"
    terraform --version
    echo "::endgroup::"
    
    # Debug information (only shown in debug mode)
    echo "::debug::Processing configuration: $config_name"
    
    # Set environment variables for subsequent steps
    echo "TERRAFORM_INITIALIZED=true" >> $GITHUB_ENV
    
    # Mask sensitive values
    echo "::add-mask::$sensitive_value"
```

## 🧪 Testing Actions

### 1. Test Workflow Pattern

Create a test workflow for each action:

```yaml
# .github/actions/action-name/tests/test-action.yml
name: Test Action Name

on:
  workflow_dispatch:
    inputs:
      test-case:
        description: 'Test case to run'
        required: false
        default: 'all'
        type: choice
        options:
          - 'all'
          - 'basic'
          - 'edge-cases'
          - 'error-conditions'

jobs:
  test-basic:
    if: ${{ github.event.inputs.test-case == 'all' || github.event.inputs.test-case == 'basic' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Test Basic Functionality
        id: test-basic
        uses: ./.github/actions/action-name
        with:
          required-input: 'test-value'
          optional-input: 'custom-value'
      
      - name: Validate Basic Output
        run: |
          if [ -z "${{ steps.test-basic.outputs.output-name }}" ]; then
            echo "::error::Basic test failed - no output generated"
            exit 1
          fi
          echo "::notice::Basic test passed ✅"

  test-edge-cases:
    if: ${{ github.event.inputs.test-case == 'all' || github.event.inputs.test-case == 'edge-cases' }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-scenario:
          - { input: '', expected: 'default-behavior' }
          - { input: 'special-chars!@#', expected: 'sanitized-output' }
    steps:
      - uses: actions/checkout@v4
      
      - name: Test Edge Case - ${{ matrix.test-scenario.input }}
        id: test-edge
        uses: ./.github/actions/action-name
        with:
          optional-input: ${{ matrix.test-scenario.input }}
        continue-on-error: true
      
      - name: Validate Edge Case Result
        run: |
          # Validate expected behavior
          echo "Testing scenario: ${{ matrix.test-scenario.input }}"

  test-error-conditions:
    if: ${{ github.event.inputs.test-case == 'all' || github.event.inputs.test-case == 'error-conditions' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Test Missing Required Input
        id: test-error
        uses: ./.github/actions/action-name
        with:
          # Intentionally omit required input
          optional-input: 'test'
        continue-on-error: true
      
      - name: Validate Error Handling
        run: |
          if [ "${{ steps.test-error.outcome }}" != "failure" ]; then
            echo "::error::Error test failed - action should have failed"
            exit 1
          fi
          echo "::notice::Error handling test passed ✅"
```

### 2. Local Testing Scripts

Create helper scripts for local development:

```bash
#!/bin/bash
# .github/actions/action-name/tests/local-test.sh

set -euo pipefail

echo "🧪 Local Action Testing Script"

# Set up test environment
export GITHUB_OUTPUT="/tmp/github-output"
export GITHUB_ENV="/tmp/github-env"

# Create temporary files
touch "$GITHUB_OUTPUT" "$GITHUB_ENV"

# Test basic functionality
echo "Testing basic functionality..."
cd "$(dirname "$0")/.."

# Simulate action execution
bash -c '
  # Source action steps here
  # This is a simplified version for local testing
'

# Validate outputs
echo "Validating outputs..."
if [ -s "$GITHUB_OUTPUT" ]; then
  echo "✅ Action produced outputs:"
  cat "$GITHUB_OUTPUT"
else
  echo "❌ No outputs generated"
fi

# Clean up
rm -f "$GITHUB_OUTPUT" "$GITHUB_ENV"

echo "🎉 Local test completed"
```

## 📚 Action Documentation Standards

### README.md Template

Each action must include comprehensive documentation:

```markdown
# Action Name

Brief description of what the action does and its primary use case.

## Usage

```yaml
- name: Use Action Name
  uses: ./.github/actions/action-name
  with:
    required-input: 'value'
    optional-input: 'custom-value'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `required-input` | Description of required input | ✅ | N/A |
| `optional-input` | Description of optional input | ❌ | `default-value` |

## Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `output-name` | Description of output | `example-value` |

## Examples

### Basic Usage
```yaml
- uses: ./.github/actions/action-name
  with:
    required-input: 'basic-value'
```

### Advanced Usage
```yaml
- uses: ./.github/actions/action-name
  with:
    required-input: 'advanced-value'
    optional-input: 'custom-option'
```

## Error Handling

The action handles these error conditions:

- **Missing required inputs**: Fails with clear error message
- **Invalid input format**: Validates and provides guidance
- **Resource not found**: Checks existence before processing

## Development

### Testing
Run the test workflow:
```bash
gh workflow run test-action.yml -f test-case=all
```

### Local Testing
```bash
.github/actions/action-name/tests/local-test.sh
```

## Changelog

### v1.0.0
- Initial implementation
- Basic functionality
- Error handling
```

## 🔧 Maintenance Procedures

### 1. Version Management

Actions should follow semantic versioning:

```yaml
# In action.yml - include version in metadata comments
# Version: 1.2.0
# Last Updated: 2025-01-15
# Breaking Changes: None
# Dependencies: actions/checkout@v4, hashicorp/setup-terraform@v3.1.2

name: 'Action Name'
# ... rest of action
```

### 2. Dependency Management

Track and update action dependencies regularly:

```yaml
# Create .github/actions/dependency-inventory.yml
dependencies:
  external-actions:
    - name: actions/checkout
      current-version: v4
      latest-version: v4
      last-checked: 2025-01-15
      notes: "Stable, no breaking changes"
    
    - name: hashicorp/setup-terraform
      current-version: v3.1.2
      latest-version: v3.1.2
      last-checked: 2025-01-15
      notes: "Latest stable version"

  internal-actions:
    - name: terraform-init-with-backend
      version: v1.0.0
      depends-on: []
      used-by: 
        - terraform-plan-apply.yml
        - terraform-destroy.yml
        - terraform-import.yml
```

### 3. Performance Monitoring

Monitor action performance and optimize as needed:

```yaml
# Add performance logging to actions
- name: Performance Monitoring
  shell: bash
  run: |
    start_time=$(date +%s)
    
    # Your action logic here
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo "::notice title=Performance::Action completed in ${duration}s"
    
    # Alert if action takes too long
    if [ $duration -gt 300 ]; then
      echo "::warning title=Performance::Action took longer than 5 minutes"
    fi
```

### 4. Breaking Change Management

When making breaking changes:

1. **Document the change** in action comments and README
2. **Provide migration guide** with examples
3. **Update version** following semantic versioning
4. **Test backwards compatibility** where possible
5. **Communicate changes** to team

```yaml
# Example breaking change documentation
# BREAKING CHANGE v2.0.0:
# - Input 'old-input' renamed to 'new-input'
# - Output 'old-output' removed, use 'new-output' instead
# - Default behavior changed for edge case handling
#
# Migration Guide:
# Old: uses: ./.github/actions/action-name
#      with:
#        old-input: 'value'
# New: uses: ./.github/actions/action-name
#      with:
#        new-input: 'value'
```

## 🚀 Best Practices

### 1. Security Considerations

- **Never log sensitive values** - use `::add-mask::` for secrets
- **Validate all inputs** to prevent injection attacks  
- **Use pinned action versions** in dependencies
- **Minimize permissions** required by actions
- **Sanitize file paths** and user inputs

### 2. Performance Optimization

- **Cache dependencies** when possible
- **Fail fast** on invalid inputs
- **Use conditional steps** to skip unnecessary work
- **Optimize shell commands** and avoid unnecessary loops
- **Monitor execution time** and optimize slow operations

### 3. Maintainability

- **Follow consistent naming** conventions
- **Use descriptive step names** and comments
- **Modularize complex logic** into separate steps
- **Document all inputs/outputs** thoroughly
- **Include examples** for common use cases

### 4. Reliability

- **Implement retry logic** for network operations
- **Handle edge cases** gracefully
- **Provide clear error messages** with actionable guidance
- **Test thoroughly** including failure scenarios
- **Use safe defaults** for optional inputs

## 📋 Checklist for New Actions

When creating a new action, ensure:

### Pre-Development
- [ ] Action purpose is clearly defined
- [ ] Similar functionality doesn't already exist
- [ ] Requirements and inputs are documented
- [ ] Output specifications are defined

### Development
- [ ] Directory structure follows standards
- [ ] `action.yml` includes all required metadata
- [ ] Input validation is implemented
- [ ] Error handling is robust
- [ ] Logging follows project patterns
- [ ] Performance is optimized

### Testing
- [ ] Test workflow is created
- [ ] Basic functionality tests pass
- [ ] Edge case scenarios are covered
- [ ] Error conditions are tested
- [ ] Local testing script exists

### Documentation
- [ ] README.md is comprehensive
- [ ] Usage examples are provided
- [ ] Inputs/outputs are documented
- [ ] Error handling is explained
- [ ] Changelog is maintained

### Integration
- [ ] Action is used in actual workflows
- [ ] Integration tests pass
- [ ] Performance is acceptable
- [ ] Team review is completed
- [ ] Documentation is updated

## 🔗 Related Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Composite Actions Guide](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Workflow Improvement Plan](workflow-improvement-plan.md)
- [Project README](../../README.md)

---

**Remember**: Actions are the foundation of our automation. Invest time in making them robust, well-tested, and maintainable. Future you (and your team) will thank you! 🚀
