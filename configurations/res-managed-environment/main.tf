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
# - "No Touch Prod" Governance: All changes enforced through Infrastructure as Code only
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single resource focused on managed environment configuration
# - Governance Integration: Designed to work with environment groups and DLP policies
# - Drift Detection: Terraform enforces configuration compliance and detects manual changes
#
# Managed Environment Capabilities:
# - Enhanced sharing controls and limits
# - Solution checker enforcement and validation
# - Usage insights and maker onboarding
# - Advanced security and compliance features

# Primary managed environment resource with comprehensive governance controls
# Managed environments provide premium capabilities for Power Platform governance at scale
# All configuration changes must be made through Infrastructure as Code to maintain
# strict governance compliance and operational consistency
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
  lifecycle {
    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []
  }
}