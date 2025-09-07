# Power Platform Environment Configuration with Managed Environment Integration

This configuration creates and manages Power Platform environments with optional managed environment features, following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## 🎯 Key Features

- **Consolidated Governance**: Environment and managed environment creation in a single atomic operation
- **Default Best Practices**: Managed environment features enabled by default for enhanced governance
- **Flexible Configuration**: Comprehensive settings for sharing, solution checking, and maker onboarding
- **Backward Compatibility**: Existing configurations continue to work unchanged
- **Provider Optimization**: Eliminates timing issues from separate module orchestration

## Use Cases

This configuration is designed for organizations that need to:

1. **Governed Environment Deployment**: Create environments with built-in governance controls, sharing policies, and solution validation
2. **Consolidated Management**: Manage both environment and governance features through a single Terraform configuration
3. **Enterprise Compliance**: Enforce organization-wide policies for maker onboarding, solution quality, and data sharing
4. **Migration from Separate Modules**: Transition from `res-environment` + `res-managed-environment` to consolidated pattern
5. **Production-Ready Governance**: Deploy environments with enterprise-grade controls enabled by default

## 🆕 What's New: Managed Environment Integration

This module now includes optional managed environment capabilities that provide:

- **Enhanced Sharing Controls**: Group-based sharing policies and user limits
- **Solution Quality Gates**: Automated solution checker validation before deployment
- **Maker Guidance**: Customizable onboarding content for new Power Platform makers
- **Usage Insights**: Optional weekly usage reporting for environment administrators
- **Enterprise Policies**: Advanced governance features for organizational compliance

### Default Behavior (Managed Environment Enabled)

```hcl
module "environment" {
  source = "./configurations/res-environment"
  
  environment = {
    display_name         = "Production Finance Environment"
    location             = "unitedstates"
    environment_group_id = "12345678-1234-1234-1234-123456789012"
  }
  
  dataverse = {
    currency_code     = "USD"
    security_group_id = "your-security-group-id"
  }
  
  # Managed environment enabled by default
  # enable_managed_environment = true (default)
  # managed_environment_settings = {} (uses secure defaults)
}
```

### Opt-Out for Basic Environments

```hcl
module "environment" {
  source = "./configurations/res-environment"
  
  environment = {
    display_name = "Development Sandbox"
    location     = "unitedstates"
  }
  
  # Disable managed features for basic development
  enable_managed_environment = false
}
```

### Custom Governance Configuration

```hcl
module "environment" {
  source = "./configurations/res-environment"
  
  environment = {
    display_name         = "Strict Production Environment"
    location             = "unitedstates"
    environment_type     = "Production"
    environment_group_id = "12345678-1234-1234-1234-123456789012"
  }
  
  dataverse = {
    currency_code     = "USD"
    security_group_id = "your-security-group-id"
  }
  
  managed_environment_settings = {
    sharing_settings = {
      is_group_sharing_disabled = true
      limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
      max_limit_user_sharing    = 5
    }
    solution_checker = {
      mode                       = "Block"
      suppress_validation_emails = false
    }
    maker_onboarding = {
      markdown_content = "Welcome to Production! Please review our development standards."
      learn_more_url   = "https://company.com/powerplatform-guidelines"
    }
  }
}
```

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment'
  tfvars-file: 'production'  # Uses tfvars/production.tfvars
```

## Pre-requisites - Granting Service Principal System Administrator Permissions

To ensure the service principal used by Terraform has the necessary permissions to manage Power Platform environments, you must assign it the **System Administrator** role in each target environment. This is required for successful resource provisioning and lifecycle management.

Use the provided script to automate this process:

```bash
./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve
```

**Script Purpose:**
- Adds the service principal (configured in `config.env`) as System Administrator on all Power Platform environments.
- Supports targeting specific environments, dry-run mode, and interactive confirmation.

**Requirements:**
- Power Platform CLI (`pac`) installed and authenticated
- Service principal configured in Azure AD and `config.env`
- Power Platform Administrator privileges for the executing user

**Example:**
```bash
# Assign permissions to all environments automatically
./scripts/utils/assign-sp-power-platform-envs.sh --auto-approve

# Assign permissions to a specific environment
./scripts/utils/assign-sp-power-platform-envs.sh --environment "<environment-id>" --auto-approve
```

> **Note:** This step is mandatory before running Terraform to avoid permission errors during environment creation or management.