## Authentication

This module requires authentication to Power Platform with appropriate permissions:

- **Environment Admin** role for the target environment
- **Power Platform Administrator** role for managed environment features
- **Premium licensing** for managed environment capabilities

## Data Collection

When using this configuration, Microsoft may collect usage data for:
- Environment governance and compliance reporting
- Solution validation and quality metrics
- Maker adoption and usage insights
- Administrative audit and security logs

## ⚠️ AVM Compliance

### Provider Exception

This module uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements since Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by outputting resource IDs and computed attributes as discrete outputs
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Child Module**: Designed for composition and orchestration by pattern modules

## Troubleshooting

### Common Issues

**Issue**: "Environment does not support managed environment features"
**Solution**: Verify the environment has the required premium licensing and is not a developer environment.

**Issue**: "Invalid sharing configuration"
**Solution**: Ensure max_limit_user_sharing is -1 when group sharing is enabled, or > 0 when disabled.

**Issue**: "Solution checker rule overrides not applied"
**Solution**: Verify rule names match the exact solution checker rule identifiers from Microsoft documentation.

### Performance Considerations

- Managed environment configuration changes may take several minutes to propagate
- Solution checker enforcement applies to future solution imports, not existing solutions
- Usage insights data is updated weekly, not in real-time

## Additional Links

- [Power Platform Managed Environments Documentation](https://learn.microsoft.com/power-platform/admin/managed-environment-overview)
- [Solution Checker Rule Reference](https://learn.microsoft.com/power-platform/admin/managed-environment-solution-checker)
- [Sharing Limits Configuration](https://learn.microsoft.com/power-platform/admin/managed-environment-sharing-limits)
- [Maker Welcome Content](https://learn.microsoft.com/power-platform/admin/welcome-content)

## Related Documentation

- [Environment Group Configuration](../res-environment-group/README.md) - Organize environments into logical groups
- [Environment Settings Configuration](../res-environment-settings/README.md) - Configure detailed environment behaviors
- [DLP Policy Configuration](../res-dlp-policy/README.md) - Implement data loss prevention policies
- [Pattern Environment Group](../ptn-environment-group/README.md) - Complete workspace orchestration
- [Power Platform Governance Guide](../../docs/guides/power-platform-governance.md) - Comprehensive governance strategy

---

_This module is part of the PPCC25 Power Platform Governance demonstration repository, showcasing Infrastructure as Code best practices for Power Platform administration._