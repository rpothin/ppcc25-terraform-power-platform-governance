# Power Platform Environment Group Configuration

This configuration creates and manages Power Platform Environment Groups for organizing environments with consistent governance policies following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Environment Organization**: Group related environments (dev, test, prod) into logical units for streamlined administration and consistent policy application across the environment lifecycle
2. **Governance at Scale**: Apply standardized rules and policies to multiple environments simultaneously, reducing manual configuration overhead and ensuring compliance across large Power Platform estates
3. **Environment Routing**: Configure automatic routing of new developer environments to specific environment groups, ensuring consistent governance from environment creation
4. **Lifecycle Management**: Organize environments by function, project, or business unit to support structured application lifecycle management and controlled deployment patterns

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-environment-group'
  tfvars-file: 'environment_group_config = {
    display_name = "Development Environment Group"
    description  = "Group for all development environments"
  }'
```