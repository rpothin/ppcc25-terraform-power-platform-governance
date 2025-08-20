# Example Configuration for Power Platform Managed Environment
#
# This file demonstrates the minimal required configuration for deploying a managed
# environment. All other settings use sensible defaults defined in variables.tf.
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
# OPTIONAL CUSTOMIZATIONS (uncomment and modify as needed)
# =============================================================================

# Override sharing settings for more restrictive environments:
# sharing_settings = {
#   is_group_sharing_disabled = true                    # Disable group sharing
#   limit_sharing_mode        = "ExcludeSharingToSecurityGroups"
#   max_limit_user_sharing    = 10                     # Limit to 10 individual users
# }

# Enable usage insights for critical production environments:
# usage_insights_disabled = false

# Customize solution checker for specific development patterns:
# solution_checker = {
#   mode                       = "Block"                # Strict validation
#   suppress_validation_emails = false                 # Send all validation emails
#   rule_overrides = [
#     "meta-avoid-reg-no-attribute",    # Allow certain registry patterns
#     "app-use-delayoutput-text-input", # Allow delayed output in text inputs
#   ]
# }

# Provide custom maker onboarding experience:
# maker_onboarding = {
#   markdown_content = <<-EOT
#     ## Welcome to Our Power Platform Environment
#     
#     ### Getting Started
#     Before creating your first app, please:
#     - Review our [development guidelines](https://company.com/guidelines)
#     - Complete [security training](https://company.com/training)
#     
#     ### Need Help?
#     Contact our team at powerplatform@company.com
#   EOT
#   learn_more_url = "https://company.com/power-platform-resources"
# }

# =============================================================================
# CONFIGURATION NOTES
# =============================================================================

# Default configuration provides:
# 
# ✅ Balanced Sharing: Group sharing enabled (governance best practice)
# ✅ Quality Control: Solution checker in warning mode with full validation
# ✅ Minimal Noise: Usage insights disabled to reduce email volume
# ✅ Basic Onboarding: Simple welcome message with official documentation
# 
# These defaults follow Power Platform governance best practices and can be
# customized by uncommenting and modifying the sections above based on your
# organization's specific requirements.