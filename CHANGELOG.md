# Unreleased

### Removed
- **BREAKING**: Removed `utl-test-environment-managed-sequence` configuration as sequential deployment testing is no longer needed after consolidating managed environment functionality into `res-environment` module
- **DEPRECATED**: Removed `res-managed-environment` standalone module in favor of integrated managed environment functionality within `res-environment` module. This consolidation eliminates timing issues and follows AVM best practices for atomic resource creation. Migration guide: Use `res-environment` with `enable_managed_environment = true` instead of separate module calls

### Added
- **DOCUMENTATION**: Simple "Known Limitations and Platform Constraints" documentation following baseline instruction principles of simplicity and clarity. Documents Power Platform teardown limitation with application admin resources, providing clear problem statement (exact error messages), root cause explanation (intentional platform security design), simple workaround (manual cleanup via Power Platform Admin Center), and framework for documenting future limitations. Focuses on essential information for PPCC25 demonstrations while maintaining educational value without unnecessary complexity. Emphasizes transparency and practical solutions over theoretical analysis.

### Fixed
- **CRITICAL**: Power Platform managed environment deployment reliability improvements to prevent "Request url must be an absolute url" errors. Consolidated managed environment functionality into res-environment module with: comprehensive environment ID validation using lifecycle preconditions, sequential deployment control in ptn-environment-group to prevent API overwhelm, explicit dependency chains (group → environments → managed_environment), comprehensive error handling with actionable error messages, troubleshooting guidance in module outputs with common issues and recovery procedures, validation steps and recovery procedures for failed deployments. Pattern mod...

### Added
  - **NEW**: Standalone comprehensive GitHub Actions consumption analyzer (`analyze-repository-actions-consumption.sh`) for deep-dive analysis of workflow consumption targeting high-consumer repositories. Features include: modular architecture with separate data fetching (`github-actions-data.sh`) and report generation (`github-actions-report.sh`) modules following DRY principles, smart pagination handling with rate limit protection and retry logic, comprehensive job-level billing calculation with runner type multipliers (Windows 2x, macOS 10x), intelligent caching system to reduce redundant API calls, progress tracking for long-running analyses, and detailed consumption reports with top workflow identification, runner distribution analysis, and optimization recommendations. Supports targeted analysis by repository and month with proper argument parsing, follows all bash scripting safety standards with set -euo pipefail and proper cleanup handling, and integrates with existing common.sh utilities including retry_with_backoff and output formatting functions. Script stays within 200-line limit through modular design while providing production-ready analysis capabilities for GitHub Actions optimization efforts.
  - **ENHANCED**: Enhanced common.sh utility library with format_duration function for consistent time formatting across all scripts, supporting human-readable duration display in seconds, minutes/seconds, and hours/minutes/seconds formats. Function exported for use in other scripts and integrates with existing timing utilities.
  - **PERFORMANCE**: Implemented Phase 2 GitHub Actions optimization - smart Terraform provider caching. Added provider caching to reusable-terraform-base.yml and terraform-single-path-validation.yml workflows to reduce initialization time by 1-2 minutes per run. Cache key based on .terraform.lock.hcl file hash ensures automatic invalidation when provider versions change. Expected cumulative savings: ~1,260 minutes/month with >80% cache hit rate. Implementation follows security and simplicity guidelines with multi-path cache configuration and environment variable setup for immediate cache usage.
  - **ENHANCED**: GitHub Actions optimization strategies integrated into automation standards. New comprehensive performance optimization section includes: data-driven workflow consumption analysis with GitHub API monitoring, frequency optimization patterns with intelligent path filtering and trigger pattern optimization, conditional execution strategies to skip unnecessary operations, execution summary optimization for high-frequency workflows, message cleanup patterns to reduce duration, organizational optimization requirements with mandatory monthly analysis, and comprehensive success metrics targeting 75-85% minutes reduction. These patterns successfully achieve 81% consumption reduction (from 1,984 to 386 minutes/month) while maintaining demonstration quality for PPCC25 sessions.
  - **ENHANCED**: Template system for Terraform configuration initialization with conditional content sections and improved documentation patterns. Template enhancements include: Key Features sections for detailed capability descriptions, additional use cases (5-6) for comprehensive scenarios, configuration categories for complex multi-setting configurations, environment-specific configuration patterns with Dev/Test/Prod examples, service principal permission requirements with automated script examples, advanced usage patterns for orchestration and template selection, enhanced troubleshooting sections for complex scenarios, conditional placeholder system with classification-specific content generation (utl-*, res-*, ptn-*), comprehensive placeholder inventory with 20+ new placeholders, and enhanced execution checklist with validation steps. Prompt enhancements include: systematic conditional content processing logic, classification-specific content patterns and examples, enhanced quality assurance validation steps, and comprehensive documentation generation guidance. This enhancement incorporates all successful patterns learned from comprehensive configuration tour and standardizes advanced documentation patterns for future consistency.
    - **ENHANCED**: Resource configuration `res-environment` expanded with integrated managed environment functionality for creating and managing Power Platform Managed Environments with comprehensive governance controls and user-friendly defaults. Features include: AVM-compliant child module architecture with lifecycle protection, governance-friendly default values (group sharing enabled, usage insights disabled, solution checker in Warn mode), comprehensive variable validation with corrected provider values, anti-corruption layer outputs with deployment summaries, and 30+ test assertions covering plan/apply s...
  - **NEW**: Pattern configuration `ptn-environment-group` for demonstrating environment group creation with multiple environments using proper AVM module orchestration. Features: Uses res-environment-group and res-environment modules instead of direct resource creation, variable transformation layer with language code mapping (string to LCID), explicit dependency management with depends_on, for_each compatibility for multiple environments, and anti-corruption layer outputs referencing module outputs. Demonstrates transition from ClickOps to IaC with governance-ready patterns for PPCC25 educational objectives.
  - **NEW**: Resource configuration `res-environment-group` for creating and managing Power Platform Environment Groups to organize environments with consistent governance policies, enabling streamlined administration and environment routing at scale. Features include: AVM-compliant structure with res-* module patterns, strong variable typing with comprehensive validation for display_name and description, lifecycle protection with ignore_changes for manual admin center modifications, anti-corruption layer outputs (environment_group_id, environment_group_name, environment_group_summary), comprehensive 25+ test assertions covering plan/apply scenarios, OIDC authentication support, and integration readiness for environment routing and rule set application. Supports organizing environments by function, project, or business unit for structured governance and automated policy application.
  - **NEW**: Resource configuration `res-environment-settings` for managing Power Platform environment settings to control various aspects of Power Platform features and behaviors after environment creation, enabling standardized governance and compliance controls through Infrastructure as Code. Features include: AVM-compliant structure with res-* module patterns, comprehensive environment settings configuration (audit/logging, email, product security/features/behaviors), strong variable typing with GUID validation and property-level validation, lifecycle protection with ignore_changes for manual admin center modifications, anti-corruption layer outputs (environment_settings_id, environment_id, applied_settings_summary, settings_configuration_summary), comprehensive 25+ test assertions covering plan/apply scenarios, OIDC authentication support, and complete environment lifecycle progression from creation through permission assignment to settings configuration. Demonstrates end-to-end IaC governance patterns for PPCC25 educational objectives.
  - **NEW**: Resource configuration `res-environment-application-admin` for automating the assignment of application admin permissions within Power Platform environments, enabling service principals and applications to manage environment resources programmatically while maintaining proper governance and security controls. Features include: AVM-compliant structure with res-* module patterns, strong variable typing with GUID validation, lifecycle protection with prevent_destroy, anti-corruption layer outputs (assignment_id, environment_id, application_id, assignment_summary), comprehensive 25+ test assertions covering plan/apply scenarios, OIDC authentication support, and troubleshooting guidance for permission assignment failures and application registration issues.
  - **NEW**: Resource configuration `res-environment` for creating and managing Power Platform environments following Azure Verified Module (AVM) standards. Features include: duplicate detection for onboarding existing environments, lifecycle protection with prevent_destroy, comprehensive variable validation with strong typing, multi-environment support with tfvars structure, anti-corruption layer outputs, and 25+ test assertions covering plan/apply scenarios. Supports both Dataverse and non-Dataverse environments with optional configuration.
  - **NEW**: Utility configuration `utl-generate-dlp-tfvars` for automated generation of tfvars files for DLP policy management. Processes exported DLP policy and connector data, supports both new policy creation (from governance templates) and onboarding of existing policies to IaC. Implements AVM-compliant structure, strong variable typing, anti-corruption outputs, and comprehensive integration test. Includes template-based documentation and troubleshooting guidance.

### DLP tfvars Management Implementation
- **Refactored Generator Utility**: `utl-generate-dlp-tfvars` now focuses solely on onboarding existing DLP policies to Infrastructure as Code (IaC), transforming exports to tfvars files. Template generation logic removed for clarity and simplicity.
- **Template tfvars for New Policies**: Created `configurations/res-dlp-policy/tfvars/template.tfvars` with secure defaults, clear comments, and concise documentation. README added to explain usage and customization.
- **Documentation and Usage Guides**: Added step-by-step guides in `docs/guides/` for onboarding existing policies and creating new ones, clarifying when to use the generator utility versus the template.
- **Validation**: Both onboarding and template flows tested end-to-end with real data to ensure reliability and usability.
- **Communication**: Announced new approach in project documentation for clear separation of onboarding and new policy creation flows.

### Changed
- **MAJOR ARCHITECTURE REFACTORING**: All Terraform configurations converted to proper Azure Verified Module (AVM) child module architecture for better orchestration and composition. **Breaking changes include**:
  - **All res-* modules**: Removed standalone provider and backend blocks from versions.tf files. Modules now receive provider configuration from parent modules, enabling for_each and depends_on usage in pattern modules.
  - **All res-* module tests**: Added provider configuration blocks to integration.tftest.hcl files to support testing child modules independently.
  - **ptn-environment-group**: Completely refactored from direct resource creation (anti-pattern) to proper module orchestration using res-environment-group and res-environment modules. Now demonstrates true AVM pattern with variable transformation layer and explicit dependency management.
  - **Module compatibility**: All modules now support count, for_each, and depends_on as required by AVM standards. Previous "Module is incompatible with count, for_each, and depends_on" errors resolved.
  - **Provider inheritance**: Child modules inherit provider configuration from parent, eliminating duplicate provider blocks and enabling proper module composition.
- **BREAKING**: `res-environment` module - Removed individual AI settings (`allow_bing_search`, `allow_moving_data_across_regions`) from environment variable since these are controlled by environment group governance rules. Environment groups now manage AI capabilities centrally through `ai_generative_settings` rules, eliminating conflicts between individual and group policies. Update your tfvars files to remove these settings and configure AI capabilities through environment group rules instead. This change resolves provider errors when environment groups have AI governance configured and aligns with Power Platform's governance-first architecture.
- **Terraform Configurations**
  - **BREAKING**: Refactored `res-dlp-policy` to expose all connector bucket variables as full provider schema objects (no longer accepts list of strings for business_connectors). All configuration, logic, and tests updated for AVM compliance. Users must now provide connector objects for all buckets. See plan/avm-dlp-policy-full-schema-exposure.md for migration details.
  - **res-dlp-policy**: Removed lifecycle `prevent_destroy` safeguard to enable intentional refactors and controlled teardown operations. Duplicate protection and state-aware guardrails remain for safety. Adopt manual review and workflow dispatch protections instead of hard prevention.
  - **res-environment**: Removed mention (and usage if present) of `prevent_destroy`; rely on workflow protections.

### Release
- **MAJOR VERSION BUMP**: This release introduces breaking changes to the `res-dlp-policy` interface. Update your configuration and tfvars files accordingly.
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


### Changed
- **Terraform Configurations**
  - **res-dlp-policy**: Aligned all variable defaults, example usage, configuration logic, and tests with security-first defaults. Now enforces `environment_type = "OnlyEnvironments"` and blocks all custom connectors by default. Example and test cases updated to match new logic. Null checks for `custom_connectors_patterns` removed for clarity and security. All changes validated with local validation script.

### Added
- **Terraform Configurations**
  - **NEW**: Utility configuration `utl-export-connectors` for exporting a list of all available Power Platform connectors in the tenant. Includes AVM-compliant template, documentation, and integration test stub. Supports governance, analytics, and DLP policy design use cases.
- **Terraform Configurations**
  - **NEW**: Resource configuration `res-dlp-policy` for deploying and managing Power Platform Data Loss Prevention (DLP) policies. Implements AVM-compliant structure, OIDC authentication, anti-corruption outputs, and comprehensive integration test. Includes template-based documentation and troubleshooting guidance.
- **Development Prompts**
  - **NEW**: Comprehensive `init-terraform-configuration.prompt.md` for standardized creation of Terraform configurations following AVM (Azure Verified Modules) principles. Includes classification-specific templates for Resource Modules (`res-*`), Pattern Modules (`ptn-*`), and Utility Modules (`utl-*`) with Power Platform provider exception documentation, security best practices, and testing requirements.

### Changed
- **Terraform Configurations**
  - **BREAKING**: Renamed `configurations/01-dlp-policies/` to `configurations/utl-export-dlp-policies/` for AVM utility module compliance and clarity. Updated all references in workflows, documentation, and state file logic. No resource state migration required (data-only configuration).
  - All workflow, automation, and documentation references updated to use the new name.
  - State files validated and correctly named for the new configuration.

### Changed
 - **GitHub Actions Workflows**
   - **Added**: New `terraform-validation-detect-and-dispatch.yml` workflow for Detect-Then-Dispatch pattern, enabling robust, parallel, and isolated validation of changed Terraform configurations and modules. Integrates with composite change detection action and per-path validation workflow. See `docs/guides/terraform-validation-detect-and-dispatch.md` for usage and migration guidance.

 - **Documentation**
   - **Added**: Guide for the new validation detect-and-dispatch workflow at `docs/guides/terraform-validation-detect-and-dispatch.md`.
- **GitHub Actions Workflows**
  - **BREAKING**: Integrated terraform-init-with-backend composite action patterns into terraform-test workflow integration testing for standardized backend initialization within test execution
  - Simplified integration testing workflow to use proven enterprise-grade initialization patterns from terraform-init-with-backend composite action directly within test execution step
  - Removed unnecessary job separation for backend initialization - composite action patterns now integrated inline for better performance and maintainability
  - Enhanced terraform-docs workflow to track and report specific documentation files generated (e.g., configurations/01-dlp-policies/README.md)
  - Replaced inline summary generation in terraform-docs workflow with reusable execution summary workflow for consistency with other Terraform operations
  - Enhanced terraform-docs workflow to leverage standardized reusable-execution-summary.yml pattern used in terraform-output.yml
  - Updated terraform-docs workflow commenting style to fully comply with GitHub automation documentation standards
  - Improved terraform-docs workflow structure to follow required order: name, concurrency, on, run-name, permissions

### Fixed
- **GitHub Actions Workflows**
  - Fixed reusable execution summary workflow to display output filenames for "docs" operation type (terraform-docs workflow)
  - Fixed missing `actions: read` permission in terraform-docs workflow required by reusable execution summary workflow
  - Fixed input parameter handling in terraform-docs workflow execution summary for non-manual triggers (push/pull_request events)
  - Fixed input parameter handling in terraform-docs workflow for non-manual triggers
  - Fixed metadata generation in reusable change detection workflow with proper JSON escaping and default values for push/pull_request events
  - Fixed YAML syntax and formatting issues in terraform-docs workflow to comply with project yamllint standards
  - Fixed step indentation and line length issues in terraform-docs workflow for proper YAML structure
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
