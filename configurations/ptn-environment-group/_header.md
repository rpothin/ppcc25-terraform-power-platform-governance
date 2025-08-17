# Power Platform Environment Group Pattern

This pattern creates a complete environment group setup with multiple environments for demonstrating Power Platform governance through Infrastructure as Code. It orchestrates the creation of an environment group and multiple environments that are automatically assigned to the group.

## Use Cases

This pattern is designed for organizations that need to:

1. **Governance at Scale**: Implement consistent governance policies across multiple environments through centralized environment group management
2. **Environment Lifecycle**: Demonstrate complete environment provisioning patterns with automatic group assignment and policy inheritance
3. **Multi-Resource Orchestration**: Show how to coordinate multiple Power Platform resources with proper dependency management
4. **Development Team Organization**: Set up structured environment groups for different teams, projects, or application lifecycles
5. **Compliance Automation**: Automate the creation of governable environment structures that support audit and compliance requirements

## Pattern Components

- **Environment Group**: Central governance container for organizing environments
- **Multiple Environments**: Demonstration environments with Dataverse enabled for group membership
- **Automatic Assignment**: Environments are automatically assigned to the group during creation
- **Dependency Management**: Proper orchestration ensures environment group exists before environment creation

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'ptn-environment-group'
  tfvars-file: 'environment_group_config = {
    display_name = "Development Team Environment Group"
    description  = "Centralized group for development team environments with standardized governance"
  }
  environments = [
    {
      display_name     = "Development Environment"
      location         = "unitedstates"
      environment_type = "Sandbox"
      domain           = "dev-env"
    },
    {
      display_name     = "Testing Environment"
      location         = "unitedstates"
      environment_type = "Sandbox"
      domain           = "test-env"
    }
  ]'
```

<!-- markdownlint-disable MD033 -->