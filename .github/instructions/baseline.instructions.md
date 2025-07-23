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
- Build composable components that can be combined flexibly
- Document reusable patterns for easy adoption
- Prefer configuration over code duplication for variations

## 💬 Clear and Concise Comments

**Comments should enhance understanding without noise:**
- Explain **why** decisions were made, not just **what** the code does
- Document non-obvious behavior and important assumptions
- Include context for Power Platform governance requirements
- Reference official documentation for complex configurations
- Keep comments up-to-date with code changes
- Use headers to explain the purpose of each configuration section

**Good comment examples:**
```hcl
# DLP policies require explicit connector classification for governance
# This ensures all connectors are intentionally categorized as business/non-business

# Using data source to reference existing environment avoids state conflicts
# when multiple configurations manage different aspects of the same environment
```

## 📁 File Organization and Structure

**Maintain clean, predictable file organization:**

### Core Directory Structure
- `scripts/` - All shell scripts for setup, cleanup, and utilities
  - `scripts/setup/` - Setup and initialization scripts
  - `scripts/cleanup/` - Cleanup and teardown scripts  
  - `scripts/utils/` - Shared utility libraries and functions
- `configurations/` - Ready-to-use infrastructure configurations
- `modules/` - Reusable modules and components
- `docs/` - All documentation organized by Diataxis framework
- `.github/` - GitHub workflows, actions, and automation

### File Type Routing Guidelines
- **Shell scripts (*.sh)** → Place in appropriate `scripts/` subfolder
- **Configuration files (*.tf, *.tfvars)** → Place in `configurations/` or `modules/`
- **Documentation (*.md)** → Place in `docs/` with proper categorization
- **Workflows (*.yml)** → Place in `.github/workflows/`
- **Actions** → Place in `.github/actions/[action-name]/`

### Naming Conventions
- Use **kebab-case** for directories and files (e.g., `setup-guide.md`)
- Use **descriptive names** that clearly indicate purpose
- Follow **consistent patterns** within each directory type
- Keep file names **under 50 characters** when possible

## 📚 Documentation and Learning Focus

**Support the educational mission:**
- Provide practical examples that users can adapt
- Document the transition from manual "ClickOps" to automated IaC
- Include troubleshooting guidance for common issues
- Reference relevant Power Platform governance concepts
- Show progressive complexity from basic to advanced patterns

## 🔄 Consistency and Standards

**Maintain professional demonstration quality:**
- Follow established file organization patterns across all configurations
- Use consistent variable naming and description formats
- Implement standardized error handling approaches
- Include proper validation for all user inputs
