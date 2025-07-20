# AVM Compliance Remediation Plan - 01-dlp-policies Configuration

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

## Overview

This document provides a comprehensive remediation plan to address AVM compliance issues identified in the `01-dlp-policies` Terraform configuration. The plan is organized by priority and includes specific implementation steps, code examples, and validation criteria.

**Configuration Analyzed**: `/configurations/01-dlp-policies/`  
**Analysis Date**: July 19, 2025  
**Current Compliance**: 16% (1/6 major requirements met)  
**Target Compliance**: 85% (accounting for Power Platform provider exception)

## 🚨 High Priority Remediations (Critical)

### ✅ Task 1: Document Power Platform Provider Exception ✅ **COMPLETED**

**Issue**: TFFR3 violation - using non-approved provider  
**Impact**: Critical compliance blocker  
**Effort**: Low (2-4 hours)  
**Status**: ✅ **COMPLETED** - July 20, 2025

#### Implementation Steps:

- [x] **Step 1.1**: Create exception documentation
  ```markdown
  # ✅ COMPLETED: docs/explanations/power-platform-provider-exception.md
  ```

- [x] **Step 1.2**: Document justification
  ```markdown
  ## Provider Exception Justification
  
  **Exception**: microsoft/power-platform provider usage
  **Reason**: Power Platform resources not available in approved providers
  **Impact**: Cannot achieve full AVM compliance until provider support added
  **Mitigation**: Follow AVM patterns where applicable, maintain compatibility
  ```

- [x] **Step 1.3**: Update main documentation
  - [x] Add exception notice to AVM reference guide
  - [x] Update compliance verification section
  - [x] Document hybrid approach strategy

**Validation Criteria**:
- [x] Exception documented with clear justification
- [x] Stakeholders acknowledge limitation
- [x] Alternative compliance strategy defined

**✅ Task 1 Complete**: Exception properly documented with comprehensive justification, stakeholder messaging, and compliance strategy. Maximum achievable compliance identified as 85%.

---

### Task 2: Implement Anti-Corruption Layer in Outputs ✅ **COMPLETED**

**Priority**: High  
**Type**: TFFR2 Compliance  
**Files**: `configurations/01-dlp-policies/outputs.tf`  
**Status**: ✅ **COMPLETED** - Enhanced structure provides complete migration data

**Problem**: Original outputs exposed complete resource objects with 17,000+ lines, violating TFFR2 requirements.

**Solution**: Enhanced anti-corruption layer with comprehensive migration data:

#### Implementation Details:
1. **Primary Output (`dlp_policies`)** - Complete migration data:
   - Core metadata (id, display_name, environment_type, environments)
   - All connector classifications (business, non_business, blocked)  
   - Custom connector patterns (critical for migration)
   - Connector summary counts for validation
   - Audit information (created_by, modified_by, timestamps)

2. **Detailed Rules Output (`dlp_policies_detailed_rules`)** - Granular rules (sensitive):
   - Complete action rules (action_id, behavior)
   - Complete endpoint rules (endpoint, behavior, order)
   - Full rule preservation for exact policy recreation

#### Key Features:
- **Migration Ready**: All data needed for IaC migration without regressions
- **AVM Compliant**: Discrete attributes instead of complete resource objects
- **Security First**: Granular rules marked as sensitive
- **Validation Support**: Summary counts for migration verification

**Validation Commands**:
```bash
cd configurations/01-dlp-policies
terraform fmt -check
terraform validate
terraform plan -out=plan.tfplan
```

**Expected Results**:
- ✅ Terraform configuration validates successfully
- ✅ Both outputs provide structured, migration-ready data
- ✅ Complete connector configurations preserved
- ✅ Custom connector patterns included
- ✅ Action and endpoint rules available for exact recreation
- ✅ No loss of critical migration data

---

### ✅ Task 3: Add Terraform Docs Configuration

**Issue**: TFNFR2 violation - missing auto-generated documentation  
**Impact**: Documentation consistency and maintenance  
**Effort**: Medium (3-5 hours)

#### Implementation Steps:

- [ ] **Step 3.1**: Install terraform-docs
  ```bash
  # Install terraform-docs (if not in devcontainer)
  go install github.com/terraform-docs/terraform-docs@latest
  ```

- [ ] **Step 3.2**: Create configuration file
  ```yaml
  # Create: configurations/01-dlp-policies/.terraform-docs.yml
  formatter: "markdown table"
  
  header-from: main.tf
  
  sections:
    hide: []
    show: [header, requirements, providers, data-sources, inputs, outputs]
  
  content: |-
    {{ .Header }}
    
    ## Usage
    
    This configuration exports Data Loss Prevention policies for analysis and migration planning.
    
    ```hcl
    # Example usage in workflow
    terraform init
    terraform plan
    terraform apply
    ```
    
    {{ .Requirements }}
    {{ .Providers }}
    {{ .DataSources }}
    {{ .Inputs }}
    {{ .Outputs }}
  
  output:
    file: "README.md"
    mode: inject
    template: |-
      <!-- BEGIN_TF_DOCS -->
      {{ .Content }}
      <!-- END_TF_DOCS -->
  
  settings:
    anchor: true
    color: true
    default: true
    description: true
    escape: true
    hide-empty: false
    html: true
    indent: 2
    lockfile: true
    read-comments: true
    required: true
    sensitive: true
    type: true
  ```

- [ ] **Step 3.3**: Generate initial documentation
  ```bash
  cd configurations/01-dlp-policies
  terraform-docs .
  ```

- [ ] **Step 3.4**: Add to CI/CD pipeline
  ```yaml
  # Add to .github/workflows/terraform-docs.yml
  name: Generate Terraform Docs
  on:
    push:
      paths: ['configurations/**/*.tf']
  jobs:
    docs:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: terraform-docs/gh-actions@main
          with:
            working-dir: configurations/01-dlp-policies
            config-file: .terraform-docs.yml
  ```

**Validation Criteria**:
- [ ] `.terraform-docs.yml` configuration exists
- [ ] Documentation auto-generates correctly
- [ ] README includes generated sections
- [ ] CI/CD pipeline updates documentation

---

## ⚠️ Medium Priority Remediations (Important)

### ✅ Task 4: Restructure as Proper Module

**Issue**: Missing module structure for reusability  
**Impact**: Code organization and reusability  
**Effort**: High (8-12 hours)

#### Implementation Steps:

- [ ] **Step 4.1**: Create module directory structure
  ```bash
  mkdir -p modules/power-platform-dlp-export/{tests,examples}
  ```

- [ ] **Step 4.2**: Create module files
  ```hcl
  # Create: modules/power-platform-dlp-export/versions.tf
  terraform {
    required_version = ">= 1.5.0"
    required_providers {
      powerplatform = {
        source  = "microsoft/power-platform"
        version = "~> 3.8"
      }
    }
  }
  ```

  ```hcl
  # Create: modules/power-platform-dlp-export/variables.tf
  variable "tenant_id" {
    description = <<-EOT
      The Azure AD tenant ID for the Power Platform tenant.
      This is used for authentication and scoping the DLP policy export.
    EOT
    type        = string
    validation {
      condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
      error_message = "Tenant ID must be a valid GUID format."
    }
  }

  variable "output_sensitive_data" {
    description = <<-EOT
      Whether to include sensitive connector configuration data in outputs.
      Set to false for most use cases to avoid exposing sensitive information.
    EOT
    type        = bool
    default     = false
  }
  ```

  ```hcl
  # Create: modules/power-platform-dlp-export/main.tf
  # Power Platform Data Loss Prevention Policies Export Module
  # This module provides a standardized way to export DLP policies
  
  data "powerplatform_data_loss_prevention_policies" "current" {}
  ```

  ```hcl
  # Create: modules/power-platform-dlp-export/outputs.tf
  output "policy_summary" {
    description = "Summary of DLP policies with discrete attributes"
    value = {
      policy_count = length(data.powerplatform_data_loss_prevention_policies.current.policies)
      policy_ids   = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.id]
      policy_names = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.display_name]
      environment_types = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.environment_type]
      created_by = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.created_by]
      last_modified_time = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : policy.last_modified_time]
    }
    sensitive = false
  }

  output "policy_connector_summary" {
    description = "Summary of connector classifications per policy"
    value = var.output_sensitive_data ? {
      policies = [for policy in data.powerplatform_data_loss_prevention_policies.current.policies : {
        policy_id = policy.id
        policy_name = policy.display_name
        business_connectors_count = length(policy.business_connectors)
        non_business_connectors_count = length(policy.non_business_connectors)
        blocked_connectors_count = length(policy.blocked_connectors)
      }]
    } : null
    sensitive = true
  }
  ```

- [ ] **Step 4.3**: Update configuration to use module
  ```hcl
  # Update: configurations/01-dlp-policies/main.tf (create if doesn't exist)
  terraform {
    required_version = ">= 1.5.0"
    backend "azurerm" {
      use_oidc = true
    }
  }

  provider "powerplatform" {
    use_oidc = true
  }

  module "dlp_export" {
    source = "../../modules/power-platform-dlp-export"
    
    tenant_id             = var.tenant_id
    output_sensitive_data = var.include_sensitive_data
  }
  ```

  ```hcl
  # Update: configurations/01-dlp-policies/variables.tf (create)
  variable "tenant_id" {
    description = "Azure AD tenant ID"
    type        = string
  }

  variable "include_sensitive_data" {
    description = "Include sensitive connector data in outputs"
    type        = bool
    default     = false
  }
  ```

  ```hcl
  # Update: configurations/01-dlp-policies/outputs.tf
  output "dlp_policies" {
    description = "DLP policies export data"
    value       = module.dlp_export.policy_summary
    sensitive   = false
  }

  output "dlp_policies_sensitive" {
    description = "Sensitive DLP policy connector data"
    value       = module.dlp_export.policy_connector_summary
    sensitive   = true
  }
  ```

- [ ] **Step 4.4**: Add module documentation
  ```bash
  cd modules/power-platform-dlp-export
  terraform-docs .
  ```

**Validation Criteria**:
- [ ] Module structure follows best practices
- [ ] Configuration uses module reference
- [ ] Variables properly defined and validated
- [ ] Outputs use discrete attributes
- [ ] Module documentation generated

---

### ✅ Task 5: Implement GitHub Repository Standards

**Issue**: TFNFR3 violation - missing branch protection and CODEOWNERS  
**Impact**: Code quality and governance  
**Effort**: Medium (4-6 hours)

#### Implementation Steps:

- [ ] **Step 5.1**: Create CODEOWNERS file
  ```bash
  # Create: .github/CODEOWNERS
  # Global owners
  * @rpothin

  # Power Platform configurations
  /configurations/ @rpothin
  /modules/ @rpothin

  # Documentation
  /docs/ @rpothin

  # GitHub workflows
  /.github/ @rpothin

  # Scripts
  /scripts/ @rpothin
  ```

- [ ] **Step 5.2**: Configure branch protection (via GitHub Settings)
  - [ ] Navigate to Repository Settings → Branches
  - [ ] Add rule for `main` branch
  - [ ] Configure protection settings:
    ```
    ✅ Require a pull request before merging
    ✅ Require approvals (minimum: 1)
    ✅ Dismiss stale PR approvals when new commits are pushed
    ✅ Require review from CODEOWNERS
    ✅ Require status checks to pass before merging
    ✅ Require branches to be up to date before merging
    ✅ Require linear history
    ✅ Require conversation resolution before merging
    ✅ Include administrators
    ✅ Restrict pushes that create files
    ✅ Restrict force pushes
    ✅ Allow deletions
    ```

- [ ] **Step 5.3**: Add branch protection validation
  ```yaml
  # Create: .github/workflows/branch-protection-check.yml
  name: Branch Protection Check
  on:
    schedule:
      - cron: '0 0 * * 0'  # Weekly check
  jobs:
    check-branch-protection:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - name: Check Branch Protection
          run: |
            # Script to validate branch protection settings
            # This ensures compliance is maintained
  ```

**Validation Criteria**:
- [ ] CODEOWNERS file exists and is comprehensive
- [ ] Branch protection rules properly configured
- [ ] All administrators included in protection
- [ ] Force pushes and deletions restricted appropriately

---

### ✅ Task 6: Add Comprehensive Testing

**Issue**: Missing automated testing and validation  
**Impact**: Quality assurance and reliability  
**Effort**: High (10-15 hours)

#### Implementation Steps:

- [ ] **Step 6.1**: Create test structure
  ```bash
  mkdir -p modules/power-platform-dlp-export/tests/{unit,integration}
  mkdir -p configurations/01-dlp-policies/tests
  ```

- [ ] **Step 6.2**: Add Terraform native tests
  ```hcl
  # Create: modules/power-platform-dlp-export/tests/unit/basic.tftest.hcl
  variables {
    tenant_id = "12345678-1234-1234-1234-123456789012"
    output_sensitive_data = false
  }

  run "validate_outputs" {
    command = plan

    assert {
      condition     = can(output.policy_summary.policy_count)
      error_message = "Policy summary must include policy count"
    }

    assert {
      condition     = can(output.policy_summary.policy_ids)
      error_message = "Policy summary must include policy IDs"
    }

    assert {
      condition     = can(output.policy_summary.policy_names)
      error_message = "Policy summary must include policy names"
    }
  }

  run "validate_sensitive_output" {
    command = plan
    
    variables {
      output_sensitive_data = true
    }

    assert {
      condition     = output.policy_connector_summary != null
      error_message = "Sensitive output should be available when enabled"
    }
  }
  ```

- [ ] **Step 6.3**: Add integration tests
  ```bash
  # Create: tests/integration/test-dlp-export.sh
  #!/bin/bash
  set -e

  echo "🧪 Running DLP Export Integration Tests"

  # Test 1: Module initialization
  echo "Test 1: Module initialization"
  cd modules/power-platform-dlp-export
  terraform init
  terraform validate

  # Test 2: Configuration with module
  echo "Test 2: Configuration validation"
  cd ../../configurations/01-dlp-policies
  terraform init
  terraform validate

  # Test 3: Plan execution (requires authentication)
  if [ "$RUN_AUTHENTICATED_TESTS" = "true" ]; then
    echo "Test 3: Plan execution"
    terraform plan -out=test.tfplan
    rm -f test.tfplan
  fi

  echo "✅ All integration tests passed"
  ```

- [ ] **Step 6.4**: Add GitHub Actions workflow
  ```yaml
  # Create: .github/workflows/test-power-platform.yml
  name: Test Power Platform Configurations

  on:
    pull_request:
      paths:
        - 'modules/power-platform-**/**'
        - 'configurations/**'
    push:
      branches: [main]

  jobs:
    terraform-tests:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        
        - name: Setup Terraform
          uses: hashicorp/setup-terraform@v3
          with:
            terraform_version: '~1.5'

        - name: Run Unit Tests
          run: |
            cd modules/power-platform-dlp-export
            terraform init
            terraform test

        - name: Run Integration Tests
          run: ./tests/integration/test-dlp-export.sh
          
        - name: Authenticated Tests
          if: github.event_name == 'push' && github.ref == 'refs/heads/main'
          env:
            ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
            ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
            ARM_USE_OIDC: true
            RUN_AUTHENTICATED_TESTS: true
          run: ./tests/integration/test-dlp-export.sh
  ```

**Validation Criteria**:
- [ ] Unit tests validate module logic
- [ ] Integration tests verify end-to-end functionality
- [ ] GitHub Actions runs tests on PR/push
- [ ] Test coverage includes error conditions
- [ ] Tests pass consistently

---

## 📝 Low Priority Remediations (Enhancement)

### ✅ Task 7: Enhanced Documentation and Examples

**Issue**: Limited usage examples and documentation depth  
**Impact**: Usability and adoption  
**Effort**: Medium (6-8 hours)

#### Implementation Steps:

- [ ] **Step 7.1**: Add comprehensive examples
  ```hcl
  # Create: modules/power-platform-dlp-export/examples/basic/main.tf
  module "dlp_export" {
    source = "../../"
    
    tenant_id             = "12345678-1234-1234-1234-123456789012"
    output_sensitive_data = false
  }

  output "policy_count" {
    value = module.dlp_export.policy_summary.policy_count
  }
  ```

  ```hcl
  # Create: modules/power-platform-dlp-export/examples/with-sensitive-data/main.tf
  module "dlp_export" {
    source = "../../"
    
    tenant_id             = "12345678-1234-1234-1234-123456789012"
    output_sensitive_data = true
  }

  output "detailed_policy_info" {
    value = module.dlp_export.policy_connector_summary
    sensitive = true
  }
  ```

- [ ] **Step 7.2**: Create usage guide
  ```markdown
  # Create: docs/guides/power-platform-dlp-export.md
  # Using the Power Platform DLP Export Module
  
  This guide shows you how to use the Power Platform DLP Export module...
  ```

- [ ] **Step 7.3**: Add troubleshooting documentation
  ```markdown
  # Create: docs/troubleshooting/power-platform-issues.md
  # Troubleshooting Power Platform Configurations
  
  Common issues and solutions...
  ```

**Validation Criteria**:
- [ ] Examples cover common use cases
- [ ] Documentation is comprehensive
- [ ] Troubleshooting guide addresses known issues
- [ ] All examples tested and working

---

### ✅ Task 8: Implement Telemetry and Usage Tracking

**Issue**: Missing telemetry requirements for AVM compliance  
**Impact**: Usage insights and compliance monitoring  
**Effort**: High (12-16 hours)

#### Implementation Steps:

- [ ] **Step 8.1**: Design telemetry strategy
  ```markdown
  # Document telemetry approach
  - What data to collect
  - How to respect privacy
  - Where to store telemetry
  - How to analyze usage
  ```

- [ ] **Step 8.2**: Implement basic telemetry
  ```hcl
  # Add to module: telemetry collection
  resource "null_resource" "telemetry" {
    count = var.enable_telemetry ? 1 : 0
    
    provisioner "local-exec" {
      command = <<-EOT
        curl -X POST "https://telemetry.example.com/usage" \
          -H "Content-Type: application/json" \
          -d '{"module": "power-platform-dlp-export", "version": "1.0.0"}'
      EOT
    }
  }
  ```

- [ ] **Step 8.3**: Add privacy controls
  ```hcl
  variable "enable_telemetry" {
    description = "Enable anonymous usage telemetry collection"
    type        = bool
    default     = true
  }
  ```

**Validation Criteria**:
- [ ] Telemetry respects user privacy
- [ ] Users can opt-out easily
- [ ] Data collection is transparent
- [ ] Analytics provide useful insights

---

## 📊 Progress Tracking

### Overall Completion Status

- [x] **High Priority Tasks**: 2/3 completed ✅✅
  - [x] Task 1: Document Power Platform Provider Exception ✅
  - [x] Task 2: Implement Output Anti-Corruption Layer ✅
  - [ ] Task 3: Add Terraform Docs Configuration
- [ ] **Medium Priority Tasks**: 0/3 completed  
- [ ] **Low Priority Tasks**: 0/2 completed

**Total Progress**: 2/8 tasks completed (25%) ⬆️

### Milestone Targets

- [ ] **Week 1**: Complete High Priority tasks (1-3)
- [ ] **Week 2**: Complete Medium Priority tasks (4-6)
- [ ] **Week 3**: Complete Low Priority tasks (7-8)
- [ ] **Week 4**: Final validation and documentation

### Success Metrics

- [ ] **Compliance Score**: Target 85% (from current 16%)
- [ ] **Test Coverage**: Target 90%+
- [ ] **Documentation**: Auto-generated and comprehensive
- [ ] **Repository Standards**: Full branch protection and governance

## 🔍 Validation and Sign-off

### Final Validation Checklist

- [ ] **Functional Requirements**:
  - [ ] TFFR1: Module structure implemented with proper versioning
  - [ ] TFFR2: Anti-corruption layer in all outputs
  - [ ] TFFR3: Provider exception documented and justified

- [ ] **Non-Functional Requirements**:
  - [ ] TFNFR1: HEREDOC descriptions implemented
  - [ ] TFNFR2: Terraform Docs configured and working
  - [ ] TFNFR3: Branch protection and CODEOWNERS configured
  - [ ] TFNFR10: Code style compliance verified

- [ ] **Testing and Quality**:
  - [ ] Unit tests passing
  - [ ] Integration tests passing
  - [ ] CI/CD pipeline functional
  - [ ] Documentation up-to-date

- [ ] **Repository Standards**:
  - [ ] All required files present
  - [ ] Proper directory structure
  - [ ] Version tagging implemented
  - [ ] Security scanning enabled

### Sign-off

- [ ] **Technical Lead Review**: _________________ Date: _________
- [ ] **Security Review**: _________________ Date: _________
- [ ] **Documentation Review**: _________________ Date: _________
- [ ] **Final Approval**: _________________ Date: _________

---

## 📚 Resources and References

### Implementation Resources
- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [terraform-docs Configuration](https://terraform-docs.io/user-guide/configuration/)
- [GitHub Branch Protection API](https://docs.github.com/en/rest/branches/branch-protection)

### AVM Resources
- [Azure Verified Modules Documentation](https://azure.github.io/Azure-Verified-Modules/)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [AVM Template Repository](https://github.com/Azure/terraform-azurerm-avm-template)

### Power Platform Resources
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [Power Platform DLP Policies Documentation](https://learn.microsoft.com/power-platform/admin/prevent-data-loss)

---

*This remediation plan provides a comprehensive roadmap for achieving maximum AVM compliance while acknowledging the unique constraints of Power Platform provider usage. Each task includes detailed implementation steps, validation criteria, and success metrics to ensure systematic progress toward compliance goals.*
