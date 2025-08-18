---
mode: agent
model: Claude Sonnet 4
description: "Creates new Terraform configurations aligned with Azure Verified Modules (AVM) principles and repository standards using a template-based approach."
---

# 🚀 Terraform Configuration Initialization (Template-Based)

You are tasked with creating a new Terraform configuration aligned with Azure Verified Modules (AVM) principles and repository standards. This process **MUST** use the provided template directory for maximum consistency and maintainability.

## 📋 Task Overview & Information Collection

**Primary Goal:** Create a new Terraform configuration using the standardized template, then apply classification-specific customization with AVM compliance.

### Required Information from User

Before proceeding, **MUST** collect the following information:

1. **AVM Module Classification** (Required):
   - `res-*` - **Resource Module**: Deploy primary Power Platform resources (DLP policies, environments)
   - `ptn-*` - **Pattern Module**: Deploy multiple resources using composable patterns (governance suites)
   - `utl-*` - **Utility Module**: Implement reusable data sources without deploying resources (connector exports)

2. **Configuration Name** (Required):
   - Must follow naming convention: `{classification}-{descriptive-name}`
   - Examples: `res-dlp-policy`, `ptn-environment`, `utl-export-dlp-policies`

3. **Primary Purpose** (Required):
   - Brief description of what the configuration will accomplish

4. **Environment Support** (Optional):
   - Whether multi-environment support is needed (creates tfvars/ subdirectory)
   - Default: Single environment unless specified

---

## 🏗️ Template-Based Workflow (3 Phases)

### Phase 1: Template Foundation (Copy & Customize)

**⚠️ CRITICAL: Never manually create template files. Always use the copy operation.**

#### Step 1: Verify Template Exists
```bash
# Use list_dir to confirm template directory exists
.github/terraform-configuration-template/
├── _header.md
├── _footer.md
└── .terraform-docs.yml
```
**STOP** if template directory is missing or incomplete.

#### Step 2: Copy Template Directory
```bash
# Execute in terminal - NEVER use create_file tools
cp -r .github/terraform-configuration-template configurations/{configuration-name}
```
Use `list_dir` to confirm all template files were copied successfully.

#### Step 3: Process Template Placeholders
1. **Read copied template files** from new configuration directory (NOT from template source)
2. **Inventory ALL placeholders** - scan `_header.md` and `_footer.md` for `{{PLACEHOLDER}}` variables
3. **Determine conditional content requirements** based on:
   - Configuration classification (res-*, ptn-*, utl-*)
   - Configuration complexity (simple, standard, comprehensive)
   - User-specified enhancement requirements
4. **Replace placeholders systematically** using user input and classification logic
5. **Process conditional sections** - include/exclude enhanced sections based on requirements:
   
   **Always Include** (All Configurations):
   - Basic metadata: CONFIGURATION_TITLE, PRIMARY_PURPOSE, CONFIGURATION_NAME
   - Core use cases: USE_CASE_1 through USE_CASE_4 with descriptions
   - AVM compliance: TFFR2_IMPLEMENTATION, CLASSIFICATION_PURPOSE
   - Basic troubleshooting: TROUBLESHOOTING_SPECIFIC, PERMISSION_CONTEXT
   
   **Include for Complex Configurations** (res-* and ptn-* with multiple features):
   - KEY_FEATURES section with detailed capability descriptions
   - ADDITIONAL_USE_CASES (USE_CASE_5, USE_CASE_6) for comprehensive scenarios
   - CONFIGURATION_CATEGORIES for configurations with multiple setting types
   - ENVIRONMENT_EXAMPLES for configurations supporting multiple environments
   - SP_PERMISSIONS for configurations requiring specific service principal permissions
   
   **Include for Pattern Configurations** (ptn-* only):
   - ADVANCED_USAGE with orchestration patterns and template selection
   - Enhanced troubleshooting with dependency management guidance
   
   **Include Based on User Requirements:**
   - ENHANCED_TROUBLESHOOTING for configurations with known complex scenarios

6. **Generate classification-specific content**:
   - **utl-***: Focus on data export patterns, output descriptions, integration examples
   - **res-***: Emphasize resource deployment, lifecycle management, security patterns
   - **ptn-***: Highlight orchestration patterns, dependency management, multi-resource coordination

7. **Validate replacement** - ensure no placeholders remain and `.terraform-docs.yml` references are correct
8. **Remove unused conditional sections** - clean up any `{{#SECTION}}...{{/SECTION}}` blocks not populated

*Why template-based: Ensures consistent documentation, metadata, and structure across all configurations while preventing manual errors.*

### Phase 2: Classification-Specific File Generation

#### Core Files (All Classifications)
Create the following files based on module classification:

**`versions.tf`** - Provider and version constraints
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"  # Centralized standard for all modules
    }
  }
  backend "azurerm" {
    use_oidc = true  # Keyless authentication
  }
}

provider "powerplatform" {
  use_oidc = true
}
```

**`main.tf`** - Primary resource definitions with comprehensive comments
```hcl
# {Configuration Title} Configuration
#
# This configuration {primary purpose} following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: {explanation of AVM compliance}
# - Anti-Corruption Layer: {explanation of output strategy}
# - Security-First: OIDC authentication, no hardcoded secrets
# - {Classification}-Specific: {classification-specific benefits}
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform`
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: {organization strategy and reasoning}

# Resource implementation with classification-specific requirements
# (Content varies by res-*, ptn-*, utl-* classification)

# Lifecycle management for res-* modules (Resource Modules Only)
# All resource modules must include lifecycle protection:
#
# resource "powerplatform_resource" "example" {
#   # ... resource arguments ...
#   lifecycle {
#     ignore_changes  = [display_name, tags]    # Allow manual admin center changes
#   }
# }
```

#### Classification-Specific Files

**Variables (`variables.tf`)** - Required for `res-*`, `ptn-*`, optional for `utl-*`
```hcl
# Input Variables for {Configuration Title}
#
# This file defines all input parameters following AVM variable standards
# with comprehensive validation and documentation.
#
# CRITICAL: All complex variables use explicit object types with property-level validation.
# The `any` type is forbidden in all production modules.

variable "example_config" {
  type = object({
    property_name = string
    # ... other properties, all with explicit types
  })
  description = <<DESCRIPTION
Comprehensive configuration object for {resource type}.

This variable consolidates core settings to reduce complexity while
ensuring all requirements are validated at plan time.

Properties:
- property_name: {detailed explanation of purpose and constraints}

Example:
{
  property_name = "example-value"
}

Validation Rules:
- {specific validation reasoning and Power Platform requirements}
DESCRIPTION

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.example_config.property_name))
    error_message = "Property name must contain only alphanumeric characters and hyphens for Power Platform compatibility."
  }
}
```

**Outputs (`outputs.tf`)** - Required for `utl-*`, optional for `res-*` and `ptn-*`
```hcl
# Output Values for {Configuration Title}
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

# Primary resource identifier for downstream configurations
output "resource_id" {
  description = <<DESCRIPTION
The unique identifier of the {resource type}.

This output provides the primary key for referencing this resource
in other Terraform configurations or external systems.
DESCRIPTION
  value       = powerplatform_resource.example.id
}

# Configuration summary for validation and reporting
output "configuration_summary" {
  description = "Summary of deployed configuration for validation and compliance reporting"
  value = {
    name            = powerplatform_resource.example.display_name
    resource_type   = "{resource type}"
    classification  = "{module classification}"
  }
}
```

**Environment Files (`tfvars/`)** - Created for `res-*` and `ptn-*` if multi-environment support requested
```hcl
# {Environment} Environment Configuration for {Configuration Title}
#
# Values optimized for {environment} workload characteristics and
# organizational security requirements.

example_config = {
  property_name = "{environment}-example-name"  # Follows org-env-purpose pattern
}

# Environment-specific feature flags
feature_flags = {
  enable_advanced_logging = true   # Full logging for {environment}
  enable_monitoring      = true   # Comprehensive monitoring
}
```

#### Testing (`tests/integration.tftest.hcl`)

**Minimum coverage requirements by classification:**
- **`utl-*`**: 15+ assertions, `plan` tests only
- **`res-*`**: 20+ assertions, both `plan` and `apply` tests
- **`ptn-*`**: 25+ assertions, both `plan` and `apply` tests

```hcl
# Integration Tests for {Configuration Title}
#
# Performance-optimized tests with consolidated assertions to minimize
# expensive plan/apply cycles while ensuring comprehensive validation.
#
# Minimum Coverage: {coverage requirement} assertions for {classification} modules

variables {
  expected_minimum_count = 0  # Allow empty tenants in test environments
  test_timeout_minutes   = 5  # Reasonable timeout for CI/CD
}

# Consolidated validation for utl-* modules
run "comprehensive_validation" {
  command = plan
  # ... 15+ assertions for structure, data integrity, and outputs ...
}

# Additional validation for res-* and ptn-* modules
run "deployment_validation" {
  command = apply
  # ... 10+ additional assertions for actual resource deployment ...
}
```

*Why different requirements: Utility modules export data without deploying resources, while resource and pattern modules deploy actual Power Platform resources requiring deployment validation.*

### Phase 3: Quality Assurance & Finalization

#### Mandatory Validation Steps
1. **Format Validation**
   ```bash
   cd configurations/{configuration-name}
   terraform fmt -check  # Must pass with no output
   terraform fmt         # Auto-correct if issues found
   terraform fmt -check  # Re-verify formatting
   ```

2. **Syntax Validation**
   ```bash
   terraform validate    # Must pass syntax check
   ```

3. **Structure Validation**
   - Verify AVM compliance patterns
   - Confirm all required files exist
   - Validate placeholder replacement completion

4. **Documentation Update**
   - Add entry to CHANGELOG.md for new configuration
   - Ensure README.md will be auto-generated by GitHub Actions

*Why these validations: Ensures CI/CD compatibility, AVM compliance, and consistent code quality from creation.*

---

## 📋 Reference Information

### Required Placeholder Inventory

**Configuration Metadata:**
- `{{CONFIGURATION_TITLE}}` - Human-readable title
- `{{CONFIGURATION_NAME}}` - Technical name (e.g., res-dlp-policy)
- `{{PRIMARY_PURPOSE}}` - Brief purpose description

**Use Cases & Integration:**
- `{{USE_CASE_1}}` through `{{USE_CASE_4}}` - Four primary use cases (required)
- `{{USE_CASE_1_DESCRIPTION}}` through `{{USE_CASE_4_DESCRIPTION}}` - Detailed descriptions (required)
- `{{USE_CASE_5}}`, `{{USE_CASE_6}}` - Additional use cases (conditional: ADDITIONAL_USE_CASES)
- `{{USE_CASE_5_DESCRIPTION}}`, `{{USE_CASE_6_DESCRIPTION}}` - Additional descriptions (conditional)
- `{{WORKFLOW_TYPE}}` - Type of workflow integration
- `{{TFVARS_EXAMPLE}}` - Example tfvars configuration

**Enhanced Content Sections (Conditional):**
- `{{KEY_FEATURES_CONTENT}}` - Comprehensive feature list with detailed descriptions (conditional: KEY_FEATURES)
- `{{CONFIGURATION_CATEGORIES_TITLE}}` - Title for configuration categories section (conditional: CONFIGURATION_CATEGORIES)
- `{{CONFIGURATION_CATEGORIES_CONTENT}}` - Detailed configuration categories content (conditional)
- `{{ENVIRONMENT_EXAMPLES_CONTENT}}` - Environment-specific configuration patterns (conditional: ENVIRONMENT_EXAMPLES)
- `{{ADVANCED_USAGE_CONTENT}}` - Advanced usage patterns and examples (conditional: ADVANCED_USAGE)

**AVM Compliance:**
- `{{TFFR2_IMPLEMENTATION}}` - Anti-corruption layer implementation
- `{{CLASSIFICATION_PURPOSE}}` - Purpose based on classification
- `{{CLASSIFICATION_DESCRIPTION}}` - Classification-specific description

**Authentication & Permissions:**
- `{{PERMISSION_CONTEXT}}` - Permission context for the resource type
- `{{SP_PERMISSIONS_CONTENT}}` - Service principal permission requirements with scripts (conditional: SP_PERMISSIONS)

**Documentation & Troubleshooting:**
- `{{TROUBLESHOOTING_SPECIFIC}}` - Configuration-specific troubleshooting
- `{{ENHANCED_TROUBLESHOOTING_TITLE}}` - Title for enhanced troubleshooting section (conditional: ENHANCED_TROUBLESHOOTING)
- `{{ENHANCED_TROUBLESHOOTING_CONTENT}}` - Additional troubleshooting content (conditional)
- `{{RESOURCE_DOCUMENTATION_TITLE}}` - Official docs title
- `{{RESOURCE_DOCUMENTATION_URL}}` - Official docs URL

**Conditional Section Flags:**
- `{{#KEY_FEATURES}}...{{/KEY_FEATURES}}` - Include Key Features section
- `{{#ADDITIONAL_USE_CASES}}...{{/ADDITIONAL_USE_CASES}}` - Include use cases 5-6
- `{{#CONFIGURATION_CATEGORIES}}...{{/CONFIGURATION_CATEGORIES}}` - Include configuration categories
- `{{#ENVIRONMENT_EXAMPLES}}...{{/ENVIRONMENT_EXAMPLES}}` - Include environment-specific examples
- `{{#ADVANCED_USAGE}}...{{/ADVANCED_USAGE}}` - Include advanced usage patterns
- `{{#SP_PERMISSIONS}}...{{/SP_PERMISSIONS}}` - Include service principal permission requirements
- `{{#ENHANCED_TROUBLESHOOTING}}...{{/ENHANCED_TROUBLESHOOTING}}` - Include enhanced troubleshooting section

### Classification-Specific Values and Enhanced Content Patterns

| Classification | Purpose | Description | Anti-Corruption Layer | Workflow Type |
|----------------|---------|-------------|----------------------|---------------|
| `utl-*` | Data Export and Analysis | Provides reusable data sources without deploying resources | Outputting discrete computed attributes instead of full resource objects | Data Export Workflows |
| `res-*` | Resource Deployment | Deploys primary Power Platform resources following WAF best practices | Outputting resource IDs and computed attributes as discrete outputs | Resource Deployment Workflows |
| `ptn-*` | Pattern Implementation | Deploys multiple resources using composable patterns | Outputting key resource identifiers and computed values from the pattern | Pattern Deployment Workflows |

### Enhanced Content Patterns by Classification

#### Key Features Content Patterns

**For `utl-*` (Utility Modules):**
```markdown
- **Live Data Access**: Direct integration with Power Platform APIs for real-time data retrieval
- **Multiple Output Formats**: JSON, CSV, and structured Terraform outputs for downstream processing
- **Zero Resource Deployment**: Pure data extraction without modifying tenant resources
- **Integration Patterns**: Designed for CI/CD pipelines and automated reporting workflows
```

**For `res-*` (Resource Modules):**
```markdown
- **Lifecycle Protection**: Manual admin center changes preserved through lifecycle ignore_changes patterns
- **Security-First Design**: OIDC authentication, no hardcoded secrets, principle of least privilege
- **Environment-Specific Configuration**: Template-driven configurations for Dev, Test, Prod environments
- **Compliance Automation**: Built-in support for governance policies and regulatory requirements
```

**For `ptn-*` (Pattern Modules):**
```markdown
- **Multi-Resource Orchestration**: Coordinated deployment with proper dependency management
- **Template-Driven Architecture**: Predefined patterns (basic, simple, enterprise) for different organizational needs
- **Hybrid Configuration Management**: Workspace-level defaults with environment-specific overrides
- **Pattern Composition**: Combines multiple AVM-compliant modules for end-to-end scenarios
```

#### Service Principal Permission Content Patterns

**For Environment Management (res-environment*, ptn-environment*):**
```markdown
Environment creation and management requires **Power Platform Service Admin** permissions. The service principal must have appropriate tenant-level permissions assigned via:

- **Automated Assignment**: Use the automated permission assignment script
- **Manual Assignment**: Assign through Power Platform Admin Center
- **Verification**: Confirm permissions before deployment

**Prerequisites Script:**
```bash
# Verify and assign required permissions
./scripts/utils/verify-sp-power-platform-permissions.sh --auto-approve
```

**For Environment Settings (res-environment-settings):**
```markdown
Environment settings management requires **System Administrator** or **Environment Admin** permissions in the target Power Platform environment. The service principal must have appropriate permissions assigned via:

- **Automated Assignment**: Use `res-environment-application-admin` configuration for Infrastructure as Code permission management
- **Manual Assignment**: Run the permission assignment script: `./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve`
- **Admin Center**: Manually assign permissions through Power Platform Admin Center

**Prerequisites Script:**
```bash
# Assign service principal as System Administrator on target environment
./scripts/utils/assign-sp-power-platform-envs.sh --environment "<environment-id>" --auto-approve
```

#### Advanced Usage Patterns

**For Pattern Configurations:**
```markdown
## Template Selection and Orchestration

### Available Templates

- **basic**: Standard three-tier lifecycle (Dev, Test, Prod) with balanced settings
- **simple**: Minimal two-tier lifecycle (Dev, Prod) with conservative settings  
- **enterprise**: Four-tier lifecycle (Dev, Staging, Test, Prod) with comprehensive security

### Orchestration Examples

```yaml
# Complete workflow orchestration
steps:
  - name: Deploy Environment Group
    uses: ./.github/actions/terraform-apply
    with:
      configuration: 'ptn-environment-group'
      tfvars-content: |
        workspace_template = "enterprise"
        name               = "CriticalApp"
        location           = "unitedstates"
```

### Final Directory Structure
```
configurations/{configuration-name}/
├── main.tf                    # Primary resource definitions
├── variables.tf               # Input parameters (if needed)
├── outputs.tf                 # Discrete outputs (if needed)
├── versions.tf                # Provider and version constraints
├── README.md                  # Auto-generated documentation
├── .terraform-docs.yml        # Documentation configuration
├── _header.md                 # Template header (processed)
├── _footer.md                 # Template footer (processed)
├── tests/
│   └── integration.tftest.hcl # Validation tests
└── tfvars/                    # Environment-specific values (if requested)
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

---

## ⚡ Enhanced Execution Checklist

**Before starting:**
- [ ] User has provided module classification, configuration name, and primary purpose
- [ ] Naming convention follows `{classification}-{descriptive-name}` pattern
- [ ] Template directory exists and contains required files (_header.md, _footer.md, .terraform-docs.yml)
- [ ] Determined enhancement level based on configuration complexity

**During execution:**
- [ ] Template copied using `cp -r` command (not manual creation)
- [ ] All placeholders inventoried from both header and footer templates
- [ ] Conditional content requirements determined based on classification and complexity
- [ ] Core placeholders replaced systematically (metadata, use cases, AVM compliance)
- [ ] Enhanced sections processed based on requirements:
  - [ ] KEY_FEATURES section for complex configurations
  - [ ] ADDITIONAL_USE_CASES for comprehensive scenarios
  - [ ] CONFIGURATION_CATEGORIES for multi-setting configurations
  - [ ] ENVIRONMENT_EXAMPLES for multi-environment support
  - [ ] SP_PERMISSIONS for configurations requiring specific permissions
  - [ ] ADVANCED_USAGE for pattern configurations
  - [ ] ENHANCED_TROUBLESHOOTING for complex scenarios
- [ ] Unused conditional sections removed from final templates
- [ ] Classification-specific files generated based on module type
- [ ] Quality requirements applied (strong typing, lifecycle management, test coverage)

**Before completion:**
- [ ] `terraform fmt -check` passes with no output
- [ ] `terraform validate` passes syntax validation
- [ ] All required files exist in configuration directory
- [ ] Template structure preserved (only placeholders modified)
- [ ] No remaining `{{PLACEHOLDER}}` or `{{#SECTION}}...{{/SECTION}}` markers in templates
- [ ] Enhanced content appropriate for configuration classification and complexity
- [ ] Documentation generates correctly with `terraform-docs`
- [ ] CHANGELOG.md updated with new configuration entry

---

## 🎯 Success Criteria

**Technical Compliance:**
- AVM-inspired structure with Power Platform adaptations
- Provider version consistency (`~> 3.8` for all modules)
- Strong variable typing (no `any` types, comprehensive validation)
- Appropriate lifecycle management for resource modules
- Minimum test coverage met for module classification

**Demonstration Quality:**
- Clear, educational examples suitable for PPCC25 session
- Comprehensive comments explaining "why" decisions were made
- Progressive complexity from basic to advanced patterns
- Troubleshooting guidance for common Power Platform issues

**This improved structure eliminates duplication, provides clear execution order, and maintains all technical requirements while being much easier for AI agents to follow systematically.**

**Ready to proceed? Please provide the module classification, configuration name, and primary purpose.**

You are tasked with creating a new Terraform configuration aligned with Azure Verified Modules (AVM) principles and repository standards. This process **MUST** use the provided template directory for maximum consistency and maintainability. **Never create or overwrite template files from scratch.**

## 📋 Task Definition

**Create a new Terraform configuration using the standardized template, then apply classification-specific customization.**

### Required Information Collection

Before proceeding, **MUST** collect the following information from the user:

1. **AVM Module Classification** (Required):
  - `res-*` - **Resource Module**: Deploy primary Power Platform resources
  - `ptn-*` - **Pattern Module**: Deploy multiple resources as a pattern
  - `utl-*` - **Utility Module**: Implement reusable data sources/functions

2. **Configuration Name** (Required):
  - Must follow naming convention: `{classification}-{descriptive-name}`
  - Examples: `res-dlp-policy`, `ptn-environment`, `utl-export-dlp-policies`

3. **Primary Purpose** (Required):
  - Brief description of what the configuration will accomplish

4. **Environment Support** (Optional):
  - Whether multi-environment support is needed (creates tfvars/ subdirectory)
  - Default: Single environment unless specified

---


## 🏗️ Initialization Workflow
## 🛡️ Phase 1: Critical Guardrails (MANDATORY)

### 1. Enforce Strong Variable Typing
- **Forbid use of `any` type in all production modules.**
- **Require explicit object types for all complex variables.**
- **MANDATORY:** Every object variable must include a `validation` block for each property.
- **MANDATORY:** All variables must use HEREDOC descriptions with property explanations and examples.
- **EXAMPLE:**
```hcl
variable "example_config" {
  type = object({
    property_name = string
    # ... other properties, all with explicit types
  })
  description = <<DESCRIPTION
Comprehensive configuration object for {resource type}.

Properties:
- property_name: {detailed explanation}

Example:
{
  property_name = "example-value"
}

Validation Rules:
- {specific validation reasoning}
DESCRIPTION
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.example_config.property_name))
    error_message = "Property name must contain only alphanumeric characters and hyphens."
  }
}
```

### 2. Centralize Provider Version Management
- **MANDATORY:** All modules must use the same provider version standard: `~> 3.8` for `microsoft/power-platform`.
- **MANDATORY:** Add a version check step to the instructions and prompt. All `required_providers` blocks must match the standard.
- **EXAMPLE:**
```hcl
terraform {
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
```

### 3. Mandate Lifecycle Management for Resource Modules (`res-*`)
- **MANDATORY:** All `res-*` modules must include a `lifecycle` block with `ignore_changes` for critical attributes.
- **MANDATORY:** Document lifecycle behavior in the module README.
- **EXAMPLE:**
```hcl
resource "powerplatform_resource" "example" {
  # ... resource arguments ...
  lifecycle {
    ignore_changes  = [display_name, tags]
  }
}
```

### 4. Define Minimum Test Coverage by Module Type
- **MANDATORY:** Minimum assertion counts:
  - 15+ for `utl-*`
  - 20+ for `res-*` (must include both `plan` and `apply` tests)
  - 25+ for `ptn-*`
- **MANDATORY:** Resource modules (`res-*`) must have both `plan` and `apply` test blocks.
- **EXAMPLE:**
```hcl
run "plan_validation" {
  command = plan
  # ... at least 10 assertions ...
}
run "apply_validation" {
  command = apply
  # ... at least 10 assertions ...
}
```

---

**MANDATORY: All generated Terraform files MUST include comprehensive comments following baseline.instructions.md standards.**

### Comment Patterns by File Type

**main.tf Header Pattern**:
```hcl
# {Configuration Title} Configuration
#
# This configuration {primary purpose} following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: {explanation of AVM compliance}
# - Anti-Corruption Layer: {explanation of output strategy}
# - Security-First: {security considerations}
# - {Classification}-Specific: {classification-specific benefits}
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform due to {reasoning}
# - Backend Strategy: Azure Storage with OIDC for {security reasoning}
# - Resource Organization: {organization strategy and why}

# Provider configuration with explicit versioning for reproducibility
terraform {
  # Version constraints ensure consistent behavior across environments
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"  # Pessimistic constraint for stability
    }
  }

  # Azure backend with OIDC for secure, keyless authentication
  backend "azurerm" {
    use_oidc = true
  }
}

# Provider configuration using OIDC for enhanced security
provider "powerplatform" {
  use_oidc = true
}
```

**variables.tf Pattern**:
```hcl
# Input Variables for {Configuration Title}
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Primary resource settings
# - Environment Settings: Environment-specific parameters
# - Security Settings: Authentication and access controls
# - Feature Flags: Optional functionality toggles
#
# CRITICAL: Forbid use of `any` type. All complex variables must use explicit object types with property-level validation.

variable "example_config" {
  type = object({
    property_name = string
    # ... other properties, all with explicit types
  })
  description = <<DESCRIPTION
Comprehensive configuration object for {resource type}.

Properties:
- property_name: {detailed explanation}

Example:
{
  property_name = "example-value"
}

Validation Rules:
- {specific validation reasoning}
DESCRIPTION
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.example_config.property_name))
    error_message = "Property name must contain only alphanumeric characters and hyphens."
  }
}
```

**main.tf Header Pattern**:
```hcl
# {Configuration Title} Configuration
#
# This configuration {primary purpose} following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: {explanation of AVM compliance}
# - Anti-Corruption Layer: {explanation of output strategy}
# - Security-First: {security considerations}
# - {Classification}-Specific: {classification-specific benefits}
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: All modules use `~> 3.8` for `microsoft/power-platform`
# - Lifecycle Management: Resource modules include `ignore_changes` (see below)
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform due to {reasoning}
# - Backend Strategy: Azure Storage with OIDC for {security reasoning}
# - Resource Organization: {organization strategy and why}

# Provider configuration with explicit versioning for reproducibility
terraform {
  # Version constraints ensure consistent behavior across environments
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"  # Pessimistic constraint for stability
    }
  }

  # Azure backend with OIDC for secure, keyless authentication
  backend "azurerm" {
    use_oidc = true
  }
}

# Provider configuration using OIDC for enhanced security
provider "powerplatform" {
  use_oidc = true
}

# Resource lifecycle management (for res-* modules)
#
# All resource modules must include a lifecycle block as shown:
#
# resource "powerplatform_resource" "example" {
#   # ... resource arguments ...
#   lifecycle {
#     ignore_changes  = [display_name, tags]
#   }
# }
```
}
```

**tests/integration.tftest.hcl Pattern**:
```hcl
# Integration Tests for {Configuration Title}
#
# These integration tests validate the {primary purpose} against
# a real Power Platform tenant. Tests require authentication via OIDC
# and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 15+ for utl-*, 20+ for res-* (plan/apply), 25+ for ptn-*
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Resource Validation: Resource-specific structure and constraints
# - Output Validation: AVM compliance and data integrity
# - Security Validation: Sensitive data handling and access controls

variables {
  # Test configuration - adjustable for different environments
  expected_minimum_count = 0  # Allow empty tenants in test environments
  test_timeout_minutes   = 5  # Reasonable timeout for CI/CD
}

# Comprehensive validation run - optimized for CI/CD performance
run "plan_validation" {
  command = plan
  # ... at least 10 assertions ...
}
run "apply_validation" {
  command = apply
  # ... at least 10 assertions ...
}
# Add more assertions as needed to meet minimum coverage for module type
```

**tfvars Pattern**:
```hcl
# {Environment} Environment Configuration for {Configuration Title}
#
# This file contains environment-specific values for the {environment}
# environment. Values are structured to match variable definitions
# and include explanatory comments for operational teams.
#
# Configuration Philosophy:
# - Environment Appropriate: Values suited for {environment} workloads
# - Security Conscious: No sensitive data, references to secure storage
# - Operationally Friendly: Clear naming and documentation for support teams
# - Change Trackable: Version controlled for audit and rollback capability

# Core resource configuration for {environment} environment
example_config = {
  # Environment-appropriate naming following organizational standards
  property_name = "{environment}-example-name"  # Follows {org}-{env}-{purpose} pattern
  
  # {environment}-specific settings with operational reasoning
  # Note: These values optimized for {environment} workload characteristics
}

# Environment-specific feature flags
# These control optional functionality based on environment maturity
feature_flags = {
  enable_advanced_logging = true   # Full logging appropriate for {environment}
  enable_monitoring      = true   # Comprehensive monitoring for {environment}
}
```

### Phase 1: Template-Based Foundation (MANDATORY)

⚠️ **CRITICAL**: You must NEVER manually create template files. Always use the copy operation below.

1. **MANDATORY: Verify Template Exists**
  - First use `list_dir` to confirm `.github/terraform-configuration-template/` exists
  - Verify template contains: `_header.md`, `_footer.md`, `.terraform-docs.yml`
  - **STOP** if template directory is missing or incomplete

2. **MANDATORY: Copy Template Directory Using Terminal Command**
  - Execute in terminal: `cp -r .github/terraform-configuration-template configurations/{configuration-name}`
  - **NEVER** use create_file or other tools to recreate template content
  - Use `list_dir` to confirm all template files were copied successfully

3. **MANDATORY: Read Copied Template Files**
  - Use `read_file` to read the copied `_header.md` and `_footer.md` from the new configuration directory
  - **DO NOT** read from the template directory - only from the copied files
  - Verify the copied files contain placeholder variables ({{PLACEHOLDER}})

4. **MANDATORY: Inventory All Placeholders**
  - Scan the copied `_header.md` and `_footer.md` for ALL `{{PLACEHOLDER}}` variables
  - List every placeholder found before proceeding
  - **DO NOT** rewrite template content—only replace placeholders

5. **MANDATORY: Replace Placeholders Systematically**
  - Create a mapping of placeholder-to-value using user input and classification logic
  - Replace ALL placeholders in the copied files using editing tools
  - **NEVER** alter the template structure or add/remove sections

6. **Validate Template Copy Process**
  - Confirm `.terraform-docs.yml` contains `header-from: "_header.md"` and `footer-from: "_footer.md"`
  - Verify `_header.md` and `_footer.md` no longer contain placeholder variables
  - **STOP** if template wasn't copied properly or placeholders weren't replaced correctly

### Phase 2: Classification-Specific Customization

5. **Generate Core Files**
  - Create `versions.tf`, `main.tf` based on classification
6. **Add Variables** (res-*, ptn-*, utl-*)
  - Create `variables.tf` with input parameters if needed
7. **Add Outputs** (utl-*, some res-* and ptn-*)
  - Create `outputs.tf` for anti-corruption layer/data export if required
8. **Create tfvars** (res-*, ptn-*)
  - Generate `tfvars/` directory and environment files if multi-environment support is needed
9. **Create Tests**
  - Add `tests/integration.tftest.hcl` with basic validation

### Phase 3: Finalization

10. **MANDATORY: Format Validation and Correction**
  - Navigate to configuration directory: `cd configurations/{configuration-name}`
  - Run format check: `terraform fmt -check`
  - If formatting issues found, auto-correct: `terraform fmt`
  - Re-verify formatting: `terraform fmt -check` (must pass with no output)
  - **STOP** if formatting cannot be resolved - investigate and fix manually
11. **Validate Structure**
  - Ensure AVM compliance and repository standards
12. **Update Changelog**
  - Add entry for new configuration

---

## ⚡ Execution Instructions (STRICT)

🚨 **NEVER CREATE TEMPLATE FILES MANUALLY** 🚨

1. **Confirm Understanding**: State the configuration to be created and its classification
2. **Validate Inputs**: Ensure naming follows conventions and requirements are clear
3. **MANDATORY: Copy Template First**: Use `cp -r` command to copy template directory - NEVER create files manually
4. **Verify Copy Success**: Confirm all template files were copied before proceeding
5. **Replace Placeholders Only**: Only modify placeholder values, never alter template structure
6. **Customize for Classification**: Add/modify files as needed for resource, pattern, or utility module
7. **Test, Format, and Document**: 
  - Validate syntax with `terraform validate`
  - **MANDATORY**: Apply formatting with `terraform fmt` and verify with `terraform fmt -check`
  - Update changelog

---

## 📁 File Structure (After Initialization)

```
configurations/{configuration-name}/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md (automatically generated by GitHub Actions when new configuration is pushed)
├── .terraform-docs.yml
├── _header.md
├── _footer.md
├── tests/
│   └── integration.tftest.hcl
└── tfvars/
   ├── dev.tfvars
   ├── staging.tfvars
   └── prod.tfvars
```

---

## 📝 Notes

- The template provides a consistent starting point for all configurations. **Never rewrite or bypass it.**
- Placeholder replacement ensures documentation and metadata are always up to date. **Always inventory and replace all placeholders.**
- Classification-specific logic (resource, pattern, utility) is applied after the template is in place.

---

## 📋 Required Placeholder Inventory

**Configuration Metadata:**
- `{{CONFIGURATION_TITLE}}` - Human-readable title
- `{{CONFIGURATION_NAME}}` - Technical name (e.g., utl-export-connectors)
- `{{PRIMARY_PURPOSE}}` - Brief purpose description

**Use Cases (4 required):**
- `{{USE_CASE_1}}` through `{{USE_CASE_4}}`
- `{{USE_CASE_1_DESCRIPTION}}` through `{{USE_CASE_4_DESCRIPTION}}`

**Workflow Integration:**
- `{{WORKFLOW_TYPE}}` - Type of workflow integration
- `{{TFVARS_EXAMPLE}}` - Example tfvars if applicable

**AVM Compliance:**
- `{{TFFR2_IMPLEMENTATION}}` - Anti-corruption layer implementation
- `{{CLASSIFICATION_PURPOSE}}` - Purpose based on classification
- `{{CLASSIFICATION_DESCRIPTION}}` - Classification-specific description

**Troubleshooting:**
- `{{PERMISSION_CONTEXT}}` - Permission context for the resource type
- `{{TROUBLESHOOTING_SPECIFIC}}` - Configuration-specific troubleshooting

**Documentation:**
- `{{RESOURCE_DOCUMENTATION_TITLE}}` - Official docs title
- `{{RESOURCE_DOCUMENTATION_URL}}` - Official docs URL

---

## 📋 Classification-Specific Placeholder Values

**For utl-* (Utility Modules):**
- `{{CLASSIFICATION_PURPOSE}}`: "Data Export and Analysis"
- `{{CLASSIFICATION_DESCRIPTION}}`: "Provides reusable data sources without deploying resources"
- `{{TFFR2_IMPLEMENTATION}}`: "outputting discrete computed attributes instead of full resource objects"
- `{{WORKFLOW_TYPE}}`: "Data Export Workflows"

**For res-* (Resource Modules):**
- `{{CLASSIFICATION_PURPOSE}}`: "Resource Deployment"
- `{{CLASSIFICATION_DESCRIPTION}}`: "Deploys primary Power Platform resources following WAF best practices"
- `{{TFFR2_IMPLEMENTATION}}`: "outputting resource IDs and computed attributes as discrete outputs"

**For ptn-* (Pattern Modules):**
- `{{CLASSIFICATION_PURPOSE}}`: "Pattern Implementation"
- `{{CLASSIFICATION_DESCRIPTION}}`: "Deploys multiple resources using composable patterns"
- `{{TFFR2_IMPLEMENTATION}}`: "outputting key resource identifiers and computed values from the pattern"

---

## 🔍 Final Validation Checklist


Before considering the task complete, verify:
- [ ] Template directory was copied using `cp -r` command (not manually created)
- [ ] All placeholder variables have been replaced with actual values
- [ ] No template structure was altered (only placeholders replaced)
- [ ] `.terraform-docs.yml` points to the correct header/footer files
- [ ] All required files exist in the new configuration directory
- [ ] **MANDATORY: `terraform fmt -check` passes with no output (all files properly formatted)**
- [ ] **MANDATORY: `terraform validate` passes (syntax validation)**
## 🎯 Format Standards Integration

**Terraform formatting is mandatory for AVM compliance and CI/CD success:**

### Automatic Format Correction Process
1. **Check**: Run `terraform fmt -check` to identify formatting issues
2. **Fix**: Run `terraform fmt` to auto-correct alignment and spacing
3. **Verify**: Re-run `terraform fmt -check` to confirm no issues remain
4. **Commit**: Only proceed with initialization completion after format validation passes

### Common Format Issues Prevented
- **Variable Alignment**: Ensures consistent spacing in `type`, `default`, and `description` blocks
- **Output Alignment**: Standardizes `value` and `description` spacing  
- **Comment Spacing**: Normalizes inline comment positioning
- **Resource Indentation**: Maintains consistent HCL block structure

### Integration with CI/CD
- Format validation prevents GitHub Actions workflow failures
- Ensures consistent code quality across all configurations
- Reduces manual remediation steps in development workflow
- Maintains AVM compliance standards automatically

**This process eliminates the format issues we've encountered and ensures every new configuration meets quality standards from creation.**

**Ready to proceed? Please provide the module classification, configuration name, and primary purpose.**