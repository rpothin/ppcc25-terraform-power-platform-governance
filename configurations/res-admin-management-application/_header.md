# Power Platform Admin Management Application

This configuration registers and manages service principals as Power Platform administrators for tenant governance following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Centralized Tenant Governance**: Register service principals for automated Power Platform administration and governance operations
2. **Service Principal Management**: Manage the lifecycle of admin service principals with proper registration and deregistration
3. **OIDC Authentication Setup**: Configure service principals for secure OIDC-based authentication in CI/CD pipelines
4. **Compliance and Audit**: Maintain auditable records of service principal registrations for governance compliance

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-admin-management-application'
  tfvars-file: 'prod.tfvars'
```