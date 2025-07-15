# Environment Configuration

This configuration manages Power Platform environments for governance and organizational structure.

## Usage

### Environment-Specific Configurations
To deploy a specific Power Platform environment:
```bash
# In GitHub Actions workflow:
# - Configuration: 03-environment  
# - tfvars file: env-production
```

## Available tfvars Files

| File | Input Name | Description | Use Case |
|------|------------|-------------|----------|
| `tfvars/env-production.tfvars` | `env-production` | Production environment | Live production workloads with enhanced security |
| `tfvars/env-development.tfvars` | `env-development` | Development environment | Development and testing activities |

## Adding New Environments

1. Create a new `.tfvars` file in the `tfvars/` folder
2. Follow the naming convention: `env-<purpose>.tfvars`
3. Copy the structure from an existing tfvars file
4. Customize the environment settings for your specific requirements
5. Use the new tfvars file in the GitHub Actions workflow (specify just the name without extension, e.g., `env-purpose`)

## Variables

The configuration uses the following variable structure:

- `environment_name`: Name of the Power Platform environment
- `environment_description`: Description of the environment
- `environment_settings`: Environment configuration including location, type, and security settings
- `environment_tags`: Tags applied to the environment resource

## Best Practices

1. **Explicit Configuration**: Always specify a tfvars file name (without extension)
2. **Naming**: Use descriptive names that clearly indicate the environment's purpose
3. **Tagging**: Include appropriate tags for governance and cost management
4. **Security**: Apply appropriate security settings based on environment type
5. **Capacity**: Consider capacity requirements for production environments
6. **Monitoring**: Enable monitoring and backup for critical environments
7. **Documentation**: Document the purpose and policies for each environment
