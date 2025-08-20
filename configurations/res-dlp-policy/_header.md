# res-dlp-policy

This configuration deploys and manages a Power Platform Data Loss Prevention (DLP) policy following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Key Features

- **Intelligent Connector Validation**: Validates all connector IDs against your tenant's available connectors during plan phase
- **Comprehensive Policy Management**: Supports business, non-business, and blocked connector classifications with custom patterns
- **Environment Scoping**: Flexible targeting (AllEnvironments, OnlyEnvironments, ExceptEnvironments) with environment-specific rules
- **Custom Connector Support**: Advanced pattern matching for custom connectors with host URL filtering
- **Security-First Defaults**: Enforces secure defaults (OnlyEnvironments scope, blocks custom connectors by default)
- **Real-Time Validation**: Live connector inventory checking prevents configuration errors at deployment time

## Policy Capabilities

### Connector Classification
- **Business Connectors**: Allow data flow within business-critical systems
- **Non-Business Connectors**: Permit limited data access for productivity tools
- **Blocked Connectors**: Completely prevent data access for security/compliance
- **Custom Connector Patterns**: URL-based filtering for organization-specific connectors

### Environment Targeting
- **All Environments**: Apply policy tenant-wide (requires Global Admin)
- **Only Environments**: Target specific environments for precise control
- **Except Environments**: Apply to all except specified environments

### Advanced Security Controls
- **Custom Connector Blocking**: Default security posture blocks all custom connectors
- **HTTP Connector Restrictions**: Granular control over HTTP-based integrations
- **Cross-Environment Data Flow**: Controls for data movement between environments

## Use Cases

This configuration is designed for organizations that need to:

1. **Enforce strict data boundaries**: Prevent data exfiltration by classifying connectors and blocking risky actions.
2. **Automate DLP policy deployment**: Use Infrastructure as Code to standardize DLP policy rollout across environments.
3. **Support compliance initiatives**: Ensure consistent DLP enforcement for regulatory and internal compliance.
4. **Enable rapid policy updates**: Quickly adapt to new business or regulatory requirements with version-controlled policies.
5. **Implement zero-trust data governance**: Apply least-privilege principles to connector access and data flow
6. **Manage custom connector security**: Control organization-specific integrations with pattern-based rules

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

## Security-First Configuration

```hcl
# Example: Secure corporate DLP policy
display_name    = "Corporate Data Protection"
environment_type = "OnlyEnvironments"  # Target specific environments only

# Allow essential business connectors
business_connectors = [
  {
    id                            = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    action_rules                  = []
    endpoint_rules                = []
    default_action_rule_behavior  = "Allow"
    default_endpoint_rule_behavior = "Allow"
  }
]

# Block all custom connectors by default
custom_connectors_patterns = []  # Empty = block all custom connectors
```

## Usage with Resource Deployment Workflows

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'res-dlp-policy'
```