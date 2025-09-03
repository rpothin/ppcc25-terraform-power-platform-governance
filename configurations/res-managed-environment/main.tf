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

# Environment readiness validation resource
# This ensures the environment is fully provisioned before attempting managed environment configuration
resource "null_resource" "environment_readiness_check" {
  # Validation triggers to ensure environment is ready
  triggers = {
    environment_id       = var.environment_id
    validation_timestamp = timestamp()
    configuration_hash = sha256(jsonencode({
      sharing_settings = var.sharing_settings
      solution_checker = var.solution_checker
      maker_onboarding = var.maker_onboarding
      usage_insights   = var.usage_insights_disabled
    }))
  }

  # Validate environment ID format and readiness
  lifecycle {
    precondition {
      condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
      error_message = "🚨 INVALID ENVIRONMENT ID FORMAT: Environment ID must be a valid GUID. Received: '${var.environment_id}'. Ensure the environment is fully created before applying managed environment settings."
    }

    precondition {
      condition     = length(trimspace(var.environment_id)) > 0
      error_message = "🚨 EMPTY ENVIRONMENT ID: Environment ID cannot be empty. This typically indicates the environment resource hasn't completed creation. Check the environment module dependencies and ensure 'depends_on' is properly configured."
    }
  }
}

# Primary managed environment resource with comprehensive governance controls
# Managed environments provide premium capabilities for Power Platform governance at scale
# All configuration changes must be made through Infrastructure as Code to maintain
# strict governance compliance and operational consistency
resource "powerplatform_managed_environment" "this" {
  # Explicit dependency on readiness check
  depends_on = [null_resource.environment_readiness_check]

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

  # Lifecycle management for resource modules with enhanced validation
  lifecycle {
    # Environment ID validation at apply time
    precondition {
      condition     = length(trimspace(var.environment_id)) > 0 && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
      error_message = "🚨 MANAGED ENVIRONMENT CREATION FAILED: Invalid or empty environment_id '${var.environment_id}'. This error typically occurs when the environment resource hasn't completed creation or there's a dependency timing issue. Ensure environments are fully created before applying managed environment settings."
    }

    # Sharing settings validation
    precondition {
      condition = (
        var.sharing_settings.is_group_sharing_disabled == false
        ? var.sharing_settings.max_limit_user_sharing == -1
        : var.sharing_settings.max_limit_user_sharing > 0
      )
      error_message = "🚨 SHARING CONFIGURATION ERROR: When group sharing is enabled (is_group_sharing_disabled = false), max_limit_user_sharing must be -1. When disabled, it must be > 0. Current: is_group_sharing_disabled = ${var.sharing_settings.is_group_sharing_disabled}, max_limit_user_sharing = ${var.sharing_settings.max_limit_user_sharing}."
    }

    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []
  }
}