# Power Platform Managed Environment Configuration

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

This configuration creates and manages Power Platform Managed Environments to provide enhanced governance, control, and administrative capabilities following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

**Last Updated**: 2025-01-17  
**Estimated Reading Time**: 8 minutes  
**Prerequisites**: Power Platform Environment Admin role, Premium licensing for managed environment features

## Use Cases

This module enables managed environment capabilities for Power Platform environments, providing:

- **Enhanced Governance**: Sharing controls, usage insights, and solution validation
- **Quality Assurance**: Automated solution checker enforcement with configurable rules
- **Maker Support**: Customizable onboarding content and learning resources
- **Compliance**: Advanced security features and administrative controls

## Usage with Resource Deployment Workflows

```hcl
module "managed_environment" {
  source = "./configurations/res-managed-environment"

  environment_id          = "12345678-1234-1234-1234-123456789012"
  usage_insights_disabled = false

  sharing_settings = {
    is_group_sharing_disabled = true
    limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
    max_limit_user_sharing    = 10
  }

  solution_checker = {
    mode                      = "Warn"
    suppress_validation_emails = true
    rule_overrides            = ["meta-avoid-reg-no-attribute"]
  }

  maker_onboarding = {
    markdown_content = "## Welcome\\n\\nPlease follow our guidelines."
    learn_more_url   = "https://company.com/power-platform-resources"
  }
}
```