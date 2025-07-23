# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **GitHub Actions Workflows**
  - Replaced inline summary generation in terraform-docs workflow with reusable execution summary workflow for consistency with other Terraform operations
  - Enhanced terraform-docs workflow to leverage standardized reusable-execution-summary.yml pattern used in terraform-output.yml

### Fixed
- **GitHub Actions Workflows**
  - Fixed missing `actions: read` permission in terraform-docs workflow required by reusable execution summary workflow
  - Fixed input parameter handling in terraform-docs workflow execution summary for non-manual triggers (push/pull_request events)
  - Fixed input parameter handling in terraform-docs workflow for non-manual triggers
  - Fixed metadata generation in reusable change detection workflow with proper JSON escaping and default values for push/pull_request events
  - Simplified metadata generation to avoid GitHub expression evaluation issues in shell scripts
  - Fixed shell arithmetic and date formatting in terraform-docs workflow summary generation to prevent script failures
- **Repository Infrastructure**
  - MIT License for open-source collaboration
  - Comprehensive .gitignore for Terraform, environment files, and development artifacts
  - CODEOWNERS file with demonstration repository ownership (@rpothin)
  - Project README with badges, quick start guide, and workflow status dashboard

- **Development Environment**
  - DevContainer configuration (`devcontainer.json`) with Terraform, Azure CLI, Python, and Power Platform tools
  - Post-create setup script (`post-create.sh`) for YAML validation tools installation
  - VS Code extensions for Power Platform, Terraform, YAML, and GitHub Copilot development

- **Configuration Management**
  - Environment configuration templates (`config.env.example`) for secure setup
  - YAML validation configuration (`.yamllint`) optimized for GitHub Actions workflows
  - Terraform backend configuration with OIDC authentication support

- **Terraform Configurations**
  - **DLP Policies Export** (`configurations/01-dlp-policies/`) - Export current Data Loss Prevention policies for migration analysis
  - **DLP Policy Management** (`configurations/02-dlp-policy/`) - Create and manage specific DLP policies with multiple tfvars examples:
    - Finance-specific DLP policy (`tfvars/dlp-finance.tfvars`)
    - HR-specific DLP policy (`tfvars/dlp-hr.tfvars`)

### Changed
- **GitHub Actions Workflows**
  - **Terraform Output Workflow** (`terraform-output.yml`) - Updated commenting style to follow GitHub automation standards, integrated metadata consumption from reusable workflow, replaced inline execution summary with reusable summary workflow for consistency, added optional `output_filename` input parameter for flexible output file naming
  - **Terraform Documentation Workflow** (`terraform-docs.yml`) - Updated commenting style to align with GitHub automation standards, enhanced header structure with comprehensive governance context, improved section documentation with operational context and security rationale, replaced inline change detection with reusable change detection workflow achieving 60-80% code reduction and improved consistency

### Fixed
- **GitHub Actions Workflows**
  - **Terraform Output Workflow** (`terraform-output.yml`) - Corrected input parameters for reusable execution summary workflow call, removed invalid `metadata` and `include-artifacts` inputs, enhanced with proper configuration context and detailed summary level
  - **Terraform Output Workflow** (`terraform-output.yml`) - Fixed regression in output file naming to use consistent filenames (`terraform-output.json/yaml`) instead of timestamped files, enabling proper Git-based change tracking 
  - **Terraform Output Workflow** (`terraform-output.yml`) - Fixed job output declarations and cross-job references, added missing `outputs` section to `process-and-commit` job and corrected execution-summary workflow call to use `needs.process-and-commit.outputs.output-filename` instead of invalid step reference
  - **Reusable Execution Summary Workflow** (`reusable-execution-summary.yml`) - Added missing `output-filename` input parameter definition to match usage in summary generation logic, enabling proper output file path references in execution summaries 
  - **Terraform Documentation Workflow** (`terraform-docs.yml`) - Fixed input parameter handling for non-manual triggers (push, pull_request) by providing default values when `github.event.inputs` is empty, preventing YAML syntax errors in reusable workflow calls
  - **Environment Management** (`configurations/03-environment/`) - Power Platform environment configuration with tfvars examples:
    - Production environment (`tfvars/env-production.tfvars`)
    - Development environment (`tfvars/env-development.tfvars`)

- **GitHub Actions Automation**
  - **Core Workflows**:
    - Terraform Plan & Apply workflow (`terraform-plan-apply.yml`) with matrix strategy support
    - Terraform Testing workflow (`terraform-test.yml`) for validation
    - Terraform Documentation generation (`terraform-docs.yml`)
    - Terraform Output extraction (`terraform-output.yml`)
    - Terraform Import workflow (`terraform-import.yml`) for existing resources
    - Terraform Destroy workflow (`terraform-destroy.yml`) for cleanup
    - YAML validation workflow (`yaml-validation.yml`)
  - **Reusable Workflows**:
    - Base Terraform workflow (`reusable-terraform-base.yml`) with common setup
    - Change detection workflow (`reusable-change-detection.yml`) for optimization
    - Validation suite (`reusable-validation-suite.yml`) for quality assurance
    - Documentation generation (`reusable-docs-generation.yml`)
    - Artifact management (`reusable-artifact-management.yml`)
    - **Execution Summary Workflow** (`reusable-execution-summary.yml`) - Standardized execution reporting across all workflows with always-on visibility for troubleshooting and optional output-filename input for accurate file path references
    - Reusable Execution Summary Workflow (`reusable-execution-summary.yml`) for standardized execution reporting across all workflows with always-on visibility for troubleshooting

- **Custom GitHub Actions**
  - **Terraform Change Detection** (`actions/detect-terraform-changes/`) - Intelligent detection of changed configurations for optimized CI/CD
  - **Workflow Metadata Generation** (`actions/generate-workflow-metadata/`) - Dynamic workflow information
  - **JIT Network Access** (`actions/jit-network-access/`) - Just-in-time network access for Terraform backend
  - **Terraform Init with Backend** (`actions/terraform-init-with-backend/`) - Secure backend initialization

- **Setup and Automation Scripts**
  - **Setup Scripts** (`scripts/setup/`):
    - Master setup orchestrator (`setup.sh`) for complete infrastructure setup
    - Service Principal creation (`01-create-service-principal-config.sh`) with OIDC configuration
    - Terraform backend creation (`02-create-terraform-backend-config.sh`) with JIT access
    - GitHub secrets configuration (`03-create-github-secrets-config.sh`)
    - Configuration restoration (`restore-config.sh`) for backup management
    - Setup validation (`validate-setup.sh`) for verification
    - Bicep template for Terraform backend storage (`terraform-backend-storage.bicep`)
  - **Cleanup Scripts** (`scripts/cleanup/`):
    - Master cleanup orchestrator (`cleanup.sh`) for complete teardown
    - Service Principal cleanup (`cleanup-service-principal-config.sh`)
    - Terraform backend cleanup (`cleanup-terraform-backend-config.sh`)
    - GitHub secrets cleanup (`cleanup-github-secrets-config.sh`)

- **Utility Libraries** (`scripts/utils/`)
  - Azure CLI utilities (`azure.sh`) for Azure operations
  - GitHub API utilities (`github.sh`) for repository management
  - Configuration management (`config.sh`) for environment handling
  - Color output functions (`colors.sh`) for enhanced CLI experience
  - Common utilities (`common.sh`) and main utility loader (`utils.sh`)
  - JIT network access utilities (`jit-network-access.sh`)
  - Prerequisites validation (`prerequisites.sh`)
  - Timing and performance utilities (`timing.sh`)
  - YAML validation tools (`validate-yaml.sh`) and installer (`yaml-tools-installer.sh`)

- **Dependency Management**
  - Dependabot configuration (`.github/dependabot.yml`) with comprehensive update grouping patterns:
    - GitHub Actions patterns for current and anticipated dependencies
    - Terraform provider patterns for Microsoft, HashiCorp, and third-party ecosystems
    - Docker container patterns for multiple registries
    - DevContainer features patterns for development tools
    - Future-ready patterns to minimize maintenance overhead

- **Documentation Framework**
  - Documentation index (`docs/index.md`) following Diataxis framework structure
  - **How-to Guides** (`docs/guides/`):
    - Complete setup guide (`setup-guide.md`) with manual configuration instructions
    - Workflow improvement planning (`workflow-improvement-plan.md`)
  - **Explanations** (`docs/explanations/`):
    - Setup automation ROI justification with research-based analysis
    - Cleanup manual time estimates justification with process analysis
    - Power Platform provider exception documentation
  - **References** (`docs/references/`):
    - GitHub Actions version inventory for dependency tracking

- **Coding Standards and Guidelines**
  - **Baseline coding guidelines** (`.github/instructions/baseline.instructions.md`) with security-first principles
  - **Terraform Infrastructure as Code standards** (`.github/instructions/terraform-iac.instructions.md`) following AVM principles
  - **Bash scripting standards** (`.github/instructions/bash-scripts.instructions.md`)
  - **Documentation standards** (`.github/instructions/docs.instructions.md`) following Diataxis framework
  - **GitHub automation standards** (`.github/instructions/github-automation.instructions.md`)

- **AI-Assisted Development**
  - GitHub Copilot prompts (`/.github/prompts/`):
    - Assessment prompts for guidelines and standards validation
    - Dependabot groups and patterns update prompts for maintenance

- **Module Structure**
  - Prepared `modules/` directory for reusable Terraform modules following AVM patterns
