---
description: "Core coding principles for PPCC25 Power Platform governance demonstration - emphasizing security, simplicity, and reusability"
applyTo: "**"
---
# Baseline Coding Guidelines

## 🎯 Repository Context

This code serves as demonstration material for **"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"** (PPCC25 session). All code should reflect:
- **Quickstart guide principles** - Easy to understand and follow
- **Demonstration quality** - Clear examples that teach concepts effectively
- **ClickOps to IaC transition** - Show best practices for automation adoption

## 🔒 Security by Design

**Security must be the foundation, not an afterthought:**

- Never hardcode secrets, credentials, or sensitive data
- Use OIDC authentication for all Azure and Power Platform connections
- Apply principle of least privilege for all permissions and access

- Implement proper resource access controls and network restrictions
- Validate all inputs and sanitize user-provided values

## 🎯 Keep It Simple

**Simplicity enables understanding and adoption:**

- Write code that is easy to understand for newcomers
- Choose clarity over cleverness - avoid complex one-liners
- Use descriptive naming that makes intent obvious

- Prefer explicit configuration over implicit defaults
- Break complex logic into smaller, understandable pieces
- Eliminate unnecessary complexity that doesn't add value

## 🧩 Modularity Over Long and Complex Files

**Structure code for maintainability and comprehension:**

- Split code into logical, focused files interacting with each other
- Create reusable modules for common patterns
- Keep individual files under 200 lines when possible

- Group related resources logically within files
- Use consistent file organization across all configurations
- Separate concerns - don't mix resource types unnecessarily

## ♻️ Reusability Over Code Duplication

**Build once, use everywhere:**

- Create modules for patterns used across multiple configurations
- Parameterize configurations to handle different environments
- Use data sources to reference existing resources instead of duplicating

## 💬 Clear and Concise Comments

**Comments should enhance understanding without noise:**

- Explain **why** decisions were made, not just **what** the code does
- Document non-obvious behavior and important assumptions
- Include context for Power Platform governance requirements

## 📁 File Organization and Structure

**Maintain clean, predictable file organization:**

### Core Directory Structure
- `scripts/` - All shell scripts for setup, cleanup, and utilities
  - `scripts/setup/` - Setup and initialization scripts
  - `scripts/cleanup/` - Cleanup and teardown scripts  

- **Shell scripts (*.sh)** → Place in appropriate `scripts/` subfolder
  - **Instructions**: `.github/instructions/bash-scripts.instructions.md`
  - **Standards**: Bash scripting safety, Azure CLI usage, error handling

- **Configuration files (*.tf, *.tfvars)** → Place in `configurations/` or `modules/`
  - **Instructions**: `.github/instructions/terraform-iac.instructions.md`
  - **Standards**: AVM compliance, provider management, security patterns

- **Documentation (*.md)** → Place in `docs/` with proper categorization
  - **Instructions**: `.github/instructions/docs.instructions.md`
  - **Standards**: Diataxis framework, badges, content organization

- **Workflows (*.yml, *.yaml)** → Place in `.github/workflows/`
  - **Instructions**: `.github/instructions/github-automation.instructions.md`
  - **Standards**: OIDC authentication, security, error handling

- **Actions** → Place in `.github/actions/[action-name]/`
  - **Instructions**: `.github/instructions/github-automation.instructions.md`
  - **Standards**: Composite actions, reusability, documentation

### Naming Conventions
- Use **kebab-case** for directories and files (e.g., `setup-guide.md`)
- Use **descriptive names** that clearly indicate purpose
- Follow **consistent patterns** within each directory type

## 📚 Documentation and Learning Focus

**Support the educational mission:**

- Provide practical examples that users can adapt
- Document the transition from manual "ClickOps" to automated IaC
- Include troubleshooting guidance for common issues

## 📊 Report Generation Guidelines

**Respect user preferences and avoid unnecessary reports:**

- **Never generate reports automatically** unless explicitly requested by the user
- **Always ask for confirmation** before creating any summary, analysis, or status report
- Focus on completing the requested task efficiently without additional overhead

**When reports are requested:**
- Structure reports clearly with sections and headers
- Include actionable insights and next steps
- Provide relevant context for Power Platform governance decisions

## 🤝 Task Collaboration and Validation

**Ensure answers are organized, clear, concise and precise**

### Pre-Task Confirmation
- **Always state your understanding** of what is expected before beginning any task
- Clarify whether you're answering a question, updating files, creating new content, etc.
- Give users opportunity to correct misalignment before work begins

### Debugging Task Approach
**Follow systematic debugging methodology:**
1. **Analyze carefully** all provided elements (screenshots, error messages, selected code)
2. **Formulate hypothesis** about the root cause based on evidence

### Complex Implementation Tasks
**Break down and validate complex work:**
- **Propose detailed plan** for tasks involving long files or multiple files
- **Ask for validation** of the approach before proceeding
- Break complex tasks into logical phases for easier review

## 🔁 Consistency and Standards

**Maintain professional demonstration quality:**

- Follow established file organization patterns across all configurations
- Use consistent variable naming and description formats
- Implement standardized error handling approaches

## 📝 Changelog Maintenance

**Keep the project history accurate and up-to-date:**

- **Always check CHANGELOG.md** when making changes to any files in the repository
- **Update the Unreleased section** if your changes represent notable additions, changes, or fixes
- Follow the existing changelog format with clear categorization:

**Examples of changelog-worthy changes:**
- New Terraform configurations or modules
- Updates to documentation structure or content
- Changes to GitHub Actions workflows

**Examples of entries that may not need changelog updates:**
- Minor typo fixes in comments
- Code formatting adjustments without functional changes
- Internal refactoring that doesn't affect end users

## 🎯 Core Principles Enforcement Summary

**These five principles serve as the north star for all development decisions:**

### 🔒 Security by Design
- **Enforcement**: Security validation checklist required before any code submission
- **Measurement**: Zero hardcoded secrets, 100% OIDC authentication usage
- **Validation**: Automated scanning for credential patterns, manual security review

### 🎯 Keep It Simple  
- **Enforcement**: Maximum 200 lines per file, complexity scoring system
- **Measurement**: File length, nesting depth, function count
- **Validation**: Line count checks, complexity score calculation

### 🧩 Modularity Over Long and Complex Files
- **Enforcement**: Single responsibility per file, logical organization requirements
- **Measurement**: File complexity scores, line counts, purpose clarity
- **Validation**: File length audits, responsibility scope reviews

### ♻️ Reusability Over Code Duplication
- **Enforcement**: Zero tolerance for copy-paste code, reusable module requirements
- **Measurement**: Duplicate pattern detection, module usage tracking
- **Validation**: Grep searches for duplicate patterns, module extraction requirements

### 💬 Clear and Concise Comments
- **Enforcement**: Comment quality guidelines, WHY-focused commenting
- **Measurement**: Comment relevance, context documentation completeness
- **Validation**: Comment review checklist, outdated comment detection
