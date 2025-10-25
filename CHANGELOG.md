# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### 🏗️ Terraform Configurations

**Resource Modules (res-*)**
- **res-dlp-policy** - Comprehensive DLP policy management with full connector classification support, security-first defaults, and multiple example tfvars (finance, HR, demo scenarios)
- **res-environment** - Power Platform environment creation with integrated managed environment support, Dataverse configuration, and environment group membership
- **res-environment-application-admin** - Service principal permission assignment for programmatic environment management
- **res-environment-group** - Environment group management for centralized governance policies and AI settings control
- **res-environment-settings** - Post-creation environment settings configuration including audit, email, and product behavior controls
- **res-enterprise-policy** - Advanced enterprise policies using azapi provider for NetworkInjection and Encryption scenarios
- **res-enterprise-policy-link** - Environment-to-enterprise-policy association for VNet injection and CMK encryption

**Pattern Modules (ptn-*)**
- **ptn-azure-vnet-extension** - Enterprise dual-VNet architecture with primary/failover regions (Canada Central/East), zero-trust NSG rules, private DNS zones, and Power Platform subnet integration
- **ptn-environment-group** - Complete environment group orchestration demonstrating proper AVM module composition with res-environment-group and res-environment modules

**Utility Modules (utl-*)**
- **utl-export-connectors** - Export all available Power Platform connectors for governance analysis
- **utl-export-dlp-policies** - Export existing DLP policies for migration to Infrastructure as Code
- **utl-generate-dlp-tfvars** - Transform exported DLP policies into ready-to-use tfvars files for IaC onboarding

#### 🤖 GitHub Actions Workflows

**Core Workflows**
- **terraform-plan-apply.yml** - Production deployment workflow with OIDC authentication and matrix strategy support
- **terraform-test.yml** - Comprehensive testing workflow with integration test execution
- **terraform-docs.yml** - Automated documentation generation using terraform-docs
- **terraform-output.yml** - Extract and commit Terraform outputs in JSON/YAML formats
- **terraform-import.yml** - Import existing resources into Terraform state
- **terraform-destroy.yml** - Controlled resource teardown with safety confirmations
- **terraform-validation-detect-and-dispatch.yml** - Intelligent parallel validation of changed configurations
- **yaml-validation.yml** - YAML linting with auto-fix capabilities using PAT authentication

**Reusable Workflows**
- **reusable-terraform-base.yml** - Common Terraform setup with provider caching optimization
- **reusable-change-detection.yml** - Smart detection of changed configurations for CI/CD optimization
- **reusable-validation-suite.yml** - Comprehensive validation checks for Terraform configurations
- **reusable-docs-generation.yml** - Standardized documentation generation
- **reusable-artifact-management.yml** - Artifact upload/download patterns
- **reusable-execution-summary.yml** - Consistent execution reporting across all workflows

**Custom GitHub Actions**
- **actions/detect-terraform-changes** - Intelligent change detection for optimized CI/CD pipelines
- **actions/generate-workflow-metadata** - Dynamic workflow metadata generation
- **actions/jit-network-access** - Just-in-time network access for secure backend connectivity
- **actions/terraform-init-with-backend** - Secure Terraform initialization with backend configuration

#### 🛠️ Setup and Automation Scripts

**Setup Scripts (scripts/setup/)**
- **setup.sh** - Master orchestrator for complete infrastructure setup
- **01-create-service-principal-config.sh** - Azure service principal creation with OIDC federation
- **02-create-terraform-backend-config.sh** - Terraform backend storage with JIT network access
- **03-create-github-secrets-config.sh** - GitHub secrets and PAT configuration for automation
- **terraform-backend-storage.bicep** - Bicep template for backend infrastructure
- **restore-config.sh** - Configuration backup restoration
- **validate-setup.sh** - Setup verification and validation

**Cleanup Scripts (scripts/cleanup/)**
- **cleanup.sh** - Master cleanup orchestrator for complete teardown
- **cleanup-service-principal-config.sh** - Service principal removal
- **cleanup-terraform-backend-config.sh** - Backend storage cleanup
- **cleanup-github-secrets-config.sh** - GitHub secrets removal

**Demo Scripts (scripts/demo/)**
- **demo-key-vault-private-endpoint.sh** - Key Vault with private endpoint demonstration
- **cleanup-key-vault-private-endpoint.sh** - Demo resource cleanup

**Utility Scripts (scripts/utils/)**
- **analyze-repository-actions-consumption.sh** - GitHub Actions usage analysis with detailed reporting
- **github-actions-data.sh** - Workflow run data fetching module
- **github-actions-report.sh** - Consumption report generation
- **terraform-local-validation.sh** - Local Terraform validation with auto-fix
- **validate-yaml.sh** - YAML validation with auto-fix capabilities
- **yaml-tools-installer.sh** - YAML tools installation (yamllint, actionlint, yq)
- Common utilities: azure.sh, github.sh, config.sh, colors.sh, common.sh, timing.sh, prerequisites.sh

#### 📚 Documentation

**Framework Structure**
- Diataxis-compliant documentation organization (tutorials, how-to guides, explanations, references)
- Comprehensive README with quick start guide and workflow status dashboard

**How-to Guides (docs/guides/)**
- **setup-guide.md** - Complete manual setup instructions
- **dlp-tfvars-management-guide.md** - DLP policy onboarding and creation workflows
- **terraform-validation-detect-and-dispatch.md** - Parallel validation workflow usage
- **migration-workflow.md** - Power Platform resource migration to IaC
- **revert-license-readme-guide.md** - File restoration procedures
- **workflow-improvement-plan.md** - CI/CD optimization strategies

**Explanations (docs/explanations/)**
- **known-limitations-and-platform-constraints.md** - Platform limitations and workarounds
- **prevent-destroy-governance-decision.md** - Lifecycle protection strategy
- **provider-configuration-architecture.md** - Provider inheritance patterns
- **setup-automation-roi.md** - Automation investment justification
- **cleanup-manual-time-estimates.md** - Time savings analysis

**References (docs/references/)**
- **github-actions-version-inventory.md** - Action version tracking and security compliance
- **utility-modules.md** - Utility module catalog and usage patterns

#### 📋 Coding Standards and Guidelines

**Instruction Files (.github/instructions/)**
- **baseline.instructions.md** - Core coding principles emphasizing security, simplicity, and reusability
- **terraform-iac.instructions.md** - Terraform IaC standards following Azure Verified Modules
- **bash-scripts.instructions.md** - Shell scripting best practices
- **docs.instructions.md** - Documentation standards using Diataxis framework
- **github-automation.instructions.md** - GitHub Actions optimization and standards

---

<!-- No releases/tags yet; add [unreleased] link after first release -->
[unreleased]: https://github.com/rpothin/ppcc25-terraform-power-platform-governance