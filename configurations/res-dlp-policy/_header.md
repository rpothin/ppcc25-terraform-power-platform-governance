# res-dlp-policy

This configuration deploys and manages a Power Platform Data Loss Prevention (DLP) policy following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Enforce strict data boundaries**: Prevent data exfiltration by classifying connectors and blocking risky actions.
2. **Automate DLP policy deployment**: Use Infrastructure as Code to standardize DLP policy rollout across environments.
3. **Support compliance initiatives**: Ensure consistent DLP enforcement for regulatory and internal compliance.
4. **Enable rapid policy updates**: Quickly adapt to new business or regulatory requirements with version-controlled policies.

## Connector ID Validation

This module validates that all provided business connector IDs exist in your Power Platform tenant. If you provide an invalid connector ID, Terraform will fail during the plan phase with a clear error message.

**To see available connectors:**

```bash
terraform plan -target=data.powerplatform_connectors.all
```

**Example error when using an invalid connector ID:**

```
Error: Invalid business connector IDs detected: /providers/Microsoft.PowerApps/apis/shared_invalid
To see available connectors, run:
  terraform plan -target=data.powerplatform_connectors.all
```

**Troubleshooting:**
- Use the `available_connectors` output to find valid connector IDs
- Connector IDs are case-sensitive and must match exactly
- Some connectors may not be available in all tenants

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-dlp-policy'
```