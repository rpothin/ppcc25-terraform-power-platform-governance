# Power Platform Environment Configuration

This configuration creates and manages Power Platform environments following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Environment Standardization**: Deploy consistent Power Platform environments with standardized naming, regions, and security settings across development, staging, and production
2. **Lifecycle Management**: Onboard existing environments to Infrastructure as Code management while preventing accidental deletion through lifecycle protection
3. **Governance Compliance**: Ensure environments meet organizational standards with validated configuration parameters and security-first defaults
4. **Multi-Environment Deployment**: Support scalable environment provisioning across multiple tenants and regions with environment-specific configurations

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