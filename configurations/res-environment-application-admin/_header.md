# Power Platform Environment Application Admin Configuration

This configuration automates the assignment of application admin permissions within Power Platform environments, enabling service principals and applications to manage environment resources programmatically while maintaining proper governance and security controls following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Automated Service Principal Permissions**: Grant Terraform service principals the necessary admin permissions for environment management and resource deployment automation without manual intervention
2. **Application Integration Security**: Securely assign application-specific admin roles to custom applications requiring environment-level access for integration scenarios
3. **Multi-Environment Governance**: Standardize permission assignments across development, staging, and production environments using consistent, auditable Infrastructure as Code practices
4. **Compliance and Audit Requirements**: Maintain comprehensive audit trails and compliance reporting for application admin permissions through version-controlled configuration management

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment-application-admin'
  tfvars-file: 'environment_application_admin = {
  environment_id   = "12345678-1234-1234-1234-123456789012"
  application_id   = "87654321-4321-4321-4321-210987654321"
  security_role_id = "11111111-2222-3333-4444-555555555555"
}'
```