# res-dlp-policy

This configuration deploys and manages a Power Platform Data Loss Prevention (DLP) policy following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Use Cases

This configuration is designed for organizations that need to:

1. **Enforce strict data boundaries**: Prevent data exfiltration by classifying connectors and blocking risky actions.
2. **Automate DLP policy deployment**: Use Infrastructure as Code to standardize DLP policy rollout across environments.
3. **Support compliance initiatives**: Ensure consistent DLP enforcement for regulatory and internal compliance.
4. **Enable rapid policy updates**: Quickly adapt to new business or regulatory requirements with version-controlled policies.

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-dlp-policy'
```