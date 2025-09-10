# Power Platform Environment Group Pattern with Settings Management

This pattern creates a complete environment group setup with multiple environments and comprehensive environment settings management for demonstrating Power Platform governance through Infrastructure as Code. It orchestrates the creation of an environment group, multiple environments, and applies template-driven settings configuration that balances workspace-level defaults with environment-specific requirements.

## Key Features

- **Template-Driven**: Workspace templates (basic, simple, enterprise) with predefined environment configurations
- **Hybrid Settings Management**: Workspace-level defaults with environment-specific overrides
- **AVM Module Orchestration**: Uses res-environment-group, res-environment (with managed environment capabilities), res-environment-settings, and res-environment-application-admin modules
- **Multi-Resource Orchestration**: Coordinated deployment of environment groups, environments, and settings
- **Settings Governance**: Comprehensive audit, security, feature, and email configuration per environment
- **Template Flexibility**: Different templates support different organizational workflows

## Use Cases

This pattern is designed for organizations that need to:

1. **Governance at Scale**: Implement consistent governance policies across multiple environments through centralized environment group management with standardized settings
2. **Environment Lifecycle**: Demonstrate complete environment provisioning patterns with template-driven settings that vary by environment purpose (Dev/Test/Prod)
3. **Settings Standardization**: Apply workspace-level defaults while allowing environment-specific security, audit, and feature configurations
4. **Multi-Resource Orchestration**: Show how to coordinate multiple Power Platform resources with proper dependency management and settings application
5. **Development Team Organization**: Set up structured environment groups with appropriate settings for different environments in the development lifecycle
6. **Compliance Automation**: Automate the creation of governable environment structures with comprehensive audit and security settings
7. **Service Principal Integration**: Assign a monitoring service principal as an application admin to all environments for tenant-level governance.

## Pattern Components

- **Environment Group**: Central governance container for organizing environments
- **Template-Driven Environments**: Environments created based on workspace templates (basic: 3 envs, simple: 2 envs, enterprise: 4 envs)
- **Managed Environment**: Configuration of managed environment settings for enhanced governance.
- **Workspace Settings**: Global settings applied to all environments (features, email, security baseline)
- **Environment-Specific Settings**: Targeted settings that vary by environment purpose (audit levels, security restrictions, file limits)
- **Automatic Assignment**: Environments are automatically assigned to the group during creation
- **Settings Application**: Environment settings are applied after environment creation with proper dependency management
- **Application Admin Assignment**: Assigns the monitoring service principal as an application admin to each environment.
- **Dependency Management**: Proper orchestration ensures environment group → environments → managed environment → settings → application admin assignment deployment order

## Template-Driven Configuration

### Available Templates

- **basic**: Standard three-tier lifecycle (Dev, Test, Prod) with balanced settings
- **simple**: Minimal two-tier lifecycle (Dev, Prod) with conservative settings
- **enterprise**: Four-tier lifecycle (Dev, Staging, Test, Prod) with comprehensive security

### Settings Management Approach

1. **Workspace Settings**: Common configurations applied to all environments
   - Global feature enablement
   - Default email settings
   - Security baseline

2. **Environment-Specific Settings**: Overrides that vary by environment:
   - **Dev**: Full debugging, open access, larger file limits
   - **Test**: Balanced security, moderate auditing
   - **Prod**: Strict security, comprehensive auditing, compliance focus

## Usage with Template Selection

```hcl
# Template-driven configuration
workspace_template = "basic"
name               = "ProjectAlpha"
description        = "Project Alpha development workspace"
location           = "unitedstates"

# Results in:
# - ProjectAlpha - Environment Group
# - ProjectAlpha - Dev (Sandbox, full debugging, open access)
# - ProjectAlpha - Test (Sandbox, moderate security, balanced auditing)
# - ProjectAlpha - Prod (Production, strict security, comprehensive audit)
```

## Usage with GitHub Actions Workflows

```yaml
# GitHub Actions workflow input for template-driven deployment
inputs:
  configuration: 'ptn-environment-group'
  tfvars-file: 'basic-example.tfvars'  # Or simple-example.tfvars, enterprise-example.tfvars
  
# Example tfvars content:
# workspace_template = "enterprise"
# name               = "CriticalBusinessApp"
# description        = "Critical business application with full enterprise governance"
# location           = "unitedstates"
#
# Results in:
# - CriticalBusinessApp - Environment Group
# - CriticalBusinessApp - Dev (Sandbox, full debugging, comprehensive settings)
# - CriticalBusinessApp - Staging (Sandbox, pre-prod validation, controlled access)
# - CriticalBusinessApp - Test (Sandbox, UAT focused, moderate security)
# - CriticalBusinessApp - Prod (Production, maximum security, full compliance)
```

<!-- markdownlint-disable MD033 -->