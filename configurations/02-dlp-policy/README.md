# DLP Policy Configuration

This configuration manages Data Loss Prevention (DLP) policies for Power Platform governance.

## Usage

### Department-Specific Configurations
To deploy a specific DLP policy for a department:
```bash
# In GitHub Actions workflow:
# - Configuration: 02-dlp-policy  
# - tfvars file: dlp-finance
```

## Available tfvars Files

| File | Input Name | Description | Use Case |
|------|------------|-------------|----------|
| `tfvars/dlp-finance.tfvars` | `dlp-finance` | Finance department policy | Strict controls for financial data |
| `tfvars/dlp-hr.tfvars` | `dlp-hr` | HR department policy | Privacy-focused controls for PII |
| `tfvars/dlp-general.tfvars` | `dlp-general` | General business policy | Balanced controls for business units |

## Adding New DLP Policies

1. Create a new `.tfvars` file in the `tfvars/` folder
2. Follow the naming convention: `dlp-<purpose>.tfvars`
3. Copy the structure from an existing tfvars file
4. Customize the DLP policy settings for your specific requirements
5. Use the new tfvars file in the GitHub Actions workflow (specify just the name without extension, e.g., `dlp-purpose`)

## Variables

The configuration uses the following variable structure:

- `dlp_policy_name`: Name of the DLP policy
- `dlp_policy_description`: Description of the policy
- `environments`: Target environments for the policy
- `dlp_policy_settings`: DLP policy configuration including connector classifications
- `dlp_tags`: Tags applied to the DLP policy resource

## Best Practices

1. **Explicit Configuration**: Always specify a tfvars file - no default fallback
2. **Naming**: Use descriptive names that clearly indicate the policy's purpose
3. **Tagging**: Include appropriate tags for governance and compliance tracking
4. **Testing**: Always test new policies in a development environment first
5. **Documentation**: Document any custom DLP policies and their business justification
6. **Review**: Regularly review and update DLP policies as business requirements change
