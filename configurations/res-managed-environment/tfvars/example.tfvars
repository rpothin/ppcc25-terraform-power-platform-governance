# Example Configuration for Power Platform Managed Environment
#
# This file provides a complete example configuration for deploying a managed
# environment with appropriate governance controls, sharing limitations, and
# quality assurance measures.
#
# Usage:
#   terraform apply -var-file="tfvars/example.tfvars"

# =============================================================================
# REQUIRED CONFIGURATION
# =============================================================================

# Target Power Platform environment to configure as managed
# Replace with your actual environment GUID
environment_id = "12345678-1234-1234-1234-123456789012"

# =============================================================================
# SHARING AND COLLABORATION CONTROLS
# =============================================================================

sharing_settings = {
  # Disable sharing with Azure AD security groups for tighter control
  is_group_sharing_disabled = true

  # Restrict sharing to exclude security group distribution
  limit_sharing_mode = "ExcludeSharingToSecurityGroups"

  # Limit individual user sharing to 10 users maximum
  # Note: When group sharing is disabled, this must be > 0
  max_limit_user_sharing = 10
}

# =============================================================================
# MONITORING AND INSIGHTS
# =============================================================================

# Enable weekly usage insights for administrators
# Set to false to receive governance and usage reports
usage_insights_disabled = false

# =============================================================================
# SOLUTION QUALITY CONTROLS
# =============================================================================

solution_checker = {
  # Warning mode: flag issues but allow imports to proceed
  # Options: "None" (disabled), "Warn" (advisory), "Block" (strict)
  mode = "Warn"

  # Only send emails when solutions are blocked, not for warnings
  suppress_validation_emails = true

  # Override specific solution checker rules that may be too restrictive
  # Common overrides for Power Platform development patterns
  rule_overrides = [
    "meta-avoid-reg-no-attribute",    # Allow certain registry patterns
    "app-use-delayoutput-text-input", # Allow delayed output in text inputs
    "web-use-org-setting"             # Allow organization setting usage
  ]
}

# =============================================================================
# MAKER ONBOARDING AND GUIDANCE
# =============================================================================

maker_onboarding = {
  # Rich text content displayed to first-time makers in Power Apps Studio
  markdown_content = <<-EOT
    ## Welcome to Our Power Platform Environment
    
    ### Getting Started
    Before creating your first app, please:
    - Review our [development guidelines](https://company.com/power-platform-guidelines)
    - Complete the [security training](https://company.com/security-training)
    - Join our [Teams channel](https://teams.microsoft.com/l/channel/...) for support
    
    ### Best Practices
    - Use descriptive names for your apps and flows
    - Test thoroughly before sharing with others
    - Follow our data classification standards
    - Request appropriate permissions before accessing sensitive data
    
    ### Need Help?
    Contact our Power Platform team at powerplatform@company.com
  EOT

  # URL for comprehensive documentation and learning resources
  learn_more_url = "https://company.com/power-platform-resources"
}

# =============================================================================
# CONFIGURATION NOTES
# =============================================================================

# This example configuration provides:
# 
# ✅ Secure Sharing: Groups disabled, individual sharing limited to 10 users
# ✅ Quality Control: Solution checker in warning mode with practical overrides
# ✅ Governance Visibility: Usage insights enabled for administrative oversight
# ✅ Maker Support: Comprehensive onboarding with links to resources
# 
# Customize these values based on your organization's:
# - Security requirements and compliance needs
# - Development team size and collaboration patterns  
# - Quality assurance processes and standards
# - Training and support infrastructure