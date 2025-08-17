# Power Platform Managed Environment Configuration
#
# This configuration creates and manages Power Platform Managed Environments to provide
# enhanced governance, control, and administrative capabilities following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Following AVM patterns with Power Platform provider adaptations
# - Anti-Corruption Layer: Discrete outputs prevent exposure of sensitive resource details
# - Security-First: OIDC authentication, no hardcoded secrets, controlled access patterns
# - Resource Module: Deploys primary Power Platform managed environment resource
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` consistency
# - Lifecycle Management: Resource modules include `ignore_changes` for operational flexibility
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single resource focused on managed environment configuration
# - Governance Integration: Designed to work with environment groups and DLP policies
#
# Managed Environment Capabilities:
# - Enhanced sharing controls and limits
# - Solution checker enforcement and validation
# - Usage insights and maker onboarding
# - Advanced security and compliance features

# Primary managed environment resource with comprehensive governance controls
# Managed environments provide premium capabilities for Power Platform governance at scale
resource "powerplatform_managed_environment" "this" {
  environment_id = var.environment_id

  # Sharing and collaboration controls
  is_group_sharing_disabled = var.sharing_settings.is_group_sharing_disabled
  limit_sharing_mode        = var.sharing_settings.limit_sharing_mode
  max_limit_user_sharing    = var.sharing_settings.max_limit_user_sharing

  # Usage insights and monitoring
  is_usage_insights_disabled = var.usage_insights_disabled

  # Solution validation and quality controls
  solution_checker_mode           = var.solution_checker.mode
  suppress_validation_emails      = var.solution_checker.suppress_validation_emails
  solution_checker_rule_overrides = var.solution_checker.rule_overrides

  # Maker onboarding and guidance
  maker_onboarding_markdown = var.maker_onboarding.markdown_content
  maker_onboarding_url      = var.maker_onboarding.learn_more_url

  # Lifecycle management for resource modules
  # Allows manual admin center changes without Terraform drift detection
  lifecycle {
    ignore_changes = [
      # Allow administrators to modify sharing settings through admin center
      # This supports dynamic organizational policy adjustments
      is_group_sharing_disabled,
      limit_sharing_mode,
      max_limit_user_sharing,

      # Allow administrators to toggle usage insights through admin center
      # Supports compliance and reporting requirement changes
      is_usage_insights_disabled,

      # Allow administrators to adjust solution checker policies through admin center
      # Enables operational flexibility for quality control processes
      solution_checker_mode,
      suppress_validation_emails,
      solution_checker_rule_overrides,

      # Allow administrators to update maker guidance through admin center
      # Supports dynamic onboarding content updates
      maker_onboarding_markdown,
      maker_onboarding_url
    ]
  }
}