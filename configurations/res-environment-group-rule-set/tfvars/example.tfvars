# Example Environment Group Rule Set Configuration for Power Platform Governance
#
# This file demonstrates environment group rule set configuration patterns for applying
# consistent governance policies across environments within a group at scale.
# Choose the example that best matches your use case and customize accordingly.
#
# Usage:
#   terraform plan -var-file="example.tfvars"
#   terraform apply -var-file="example.tfvars"

# =============================================================================
# Example 1: COMPREHENSIVE GOVERNANCE RULE SET (Recommended Starting Point)
# =============================================================================
# This example creates a complete rule set for production environment groups

environment_group_id = "12345678-1234-1234-1234-123456789012" # Replace with your environment group GUID

rules = {
  # Sharing controls for security and compliance
  sharing_controls = {
    share_mode      = "exclude sharing with security groups" # Secure default
    share_max_limit = 25                                     # Reasonable sharing limit
  }

  # Usage insights for monitoring and optimization
  usage_insights = {
    insights_enabled = true # Enable weekly email digests with environment usage
  }

  # Maker welcome content for onboarding and guidance
  maker_welcome_content = {
    maker_onboarding_url      = "https://contoso.com/powerplatform/onboarding"
    maker_onboarding_markdown = "## Welcome to Contoso Power Platform!\n\n**Getting Started:**\n- Review our [governance policies](https://contoso.com/policies)\n- Complete [required training](https://contoso.com/training)\n- Join our [community workspace](https://contoso.com/community)"
  }

  # Solution checker enforcement for quality assurance
  solution_checker_enforcement = {
    solution_checker_mode = "block"      # Block deployment of non-compliant solutions
    send_emails_enabled   = true        # Notify makers of checker results
  }

  # Backup retention for data protection
  backup_retention = {
    period_in_days = 21 # Retain backups for 3 weeks (7, 14, 21, or 28 days)
  }

  # AI features governance
  ai_generated_descriptions = {
    ai_description_enabled = false # Disable AI-generated descriptions for security
  }

  # AI generative settings for compliance
  ai_generative_settings = {
    move_data_across_regions_enabled = false # Strict data residency requirements
    bing_search_enabled              = true  # Allow Bing search for productivity
  }
}

# =============================================================================
# Alternative Configuration Examples
# =============================================================================

# ----------------------------
# DEVELOPMENT ENVIRONMENT GROUP EXAMPLE
# ----------------------------
# Uncomment and modify as needed for development environment groups:
#
# environment_group_id = "11111111-2222-3333-4444-555555555555"
# 
# rules = {
#   # Relaxed sharing for collaboration
#   sharing_controls = {
#     share_mode      = "allow sharing with security groups"
#     share_max_limit = 100
#   }
# 
#   # Enable insights for development tracking
#   usage_insights = {
#     insights_enabled = true
#   }
# 
#   # Solution checker in audit mode for learning
#   solution_checker_enforcement = {
#     solution_checker_mode = "audit"  # Allow deployment with warnings
#     send_emails_enabled   = false   # Reduce noise in development
#   }
# 
#   # Shorter retention for development
#   backup_retention = {
#     period_in_days = 7  # Weekly retention for development environments
#   }
# 
#   # Enable AI features for innovation
#   ai_generated_descriptions = {
#     ai_description_enabled = true
#   }
# 
#   ai_generative_settings = {
#     move_data_across_regions_enabled = true   # Allow for development flexibility
#     bing_search_enabled              = true
#   }
# }

# ----------------------------
# MINIMAL RULE SET EXAMPLE
# ----------------------------
# Uncomment and modify as needed for basic governance requirements:
#
# environment_group_id = "22222222-3333-4444-5555-666666666666"
# 
# rules = {
#   # Basic sharing controls only
#   sharing_controls = {
#     share_mode      = "exclude sharing with security groups"
#     share_max_limit = 10
#   }
# 
#   # Basic backup retention
#   backup_retention = {
#     period_in_days = 14
#   }
# }

# ----------------------------
# HIGH-SECURITY ENVIRONMENT GROUP EXAMPLE
# ----------------------------
# Uncomment and modify as needed for high-security environments:
#
# environment_group_id = "33333333-4444-5555-6666-777777777777"
# 
# rules = {
#   # Strict sharing controls
#   sharing_controls = {
#     share_mode      = "exclude sharing with security groups"
#     share_max_limit = 5   # Very limited sharing
#   }
# 
#   # Disable usage insights for privacy
#   usage_insights = {
#     insights_enabled = false
#   }
# 
#   # Strict solution checker
#   solution_checker_enforcement = {
#     solution_checker_mode = "block"
#     send_emails_enabled   = true
#   }
# 
#   # Extended backup retention
#   backup_retention = {
#     period_in_days = 28  # Maximum retention period
#   }
# 
#   # Disable AI features for security
#   ai_generated_descriptions = {
#     ai_description_enabled = false
#   }
# 
#   ai_generative_settings = {
#     move_data_across_regions_enabled = false  # Strict data residency
#     bing_search_enabled              = false  # Disable external searches
#   }
# }

# =============================================================================
# Configuration Guidelines
# =============================================================================

# 1. Environment Group ID Requirements:
#    - Must be a valid GUID format (32 hexadecimal digits in 8-4-4-4-12 pattern)
#    - Environment group must already exist in your Power Platform tenant
#    - You must have appropriate permissions to modify the environment group
#    - Can be found in Power Platform admin center under Environment groups

# 2. Sharing Controls Best Practices:
#    - Use "exclude sharing with security groups" for secure environments
#    - Set share_max_limit based on organizational policies (1-10000)
#    - Consider team size and collaboration requirements
#    - Monitor actual sharing patterns to adjust limits

# 3. Solution Checker Enforcement:
#    - Use "block" mode for production environments to enforce quality
#    - Use "audit" mode for development to allow learning
#    - Enable email notifications for awareness and feedback
#    - Review and customize rule overrides if needed

# 4. Backup Retention Policies:
#    - Choose from 7, 14, 21, or 28 days based on organizational requirements
#    - Consider regulatory compliance and data protection needs
#    - Balance storage costs with recovery requirements
#    - Document retention decisions for audit purposes

# 5. AI Governance Considerations:
#    - Review data residency requirements for AI features
#    - Consider organizational policies on AI-generated content
#    - Balance productivity benefits with security concerns
#    - Monitor and audit AI feature usage as needed

# 6. Integration with Environment Groups:
#    - Rules are applied to all environments within the group
#    - Individual environment settings become locked when group rules apply
#    - Plan rule changes carefully as they affect all group environments
#    - Consider environment group membership before applying rules