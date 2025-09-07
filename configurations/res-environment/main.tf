# Power Platform Environment Configuration - Provider Schema Compliant
#
# This configuration uses ONLY the arguments that actually exist in the
# microsoft/power-platform provider to ensure 100% compatibility.
#
# ⚠️  KNOWN LIMITATIONS:
# - Developer environments are NOT SUPPORTED with service principal authentication
# - This module only supports Sandbox, Production, and Trial environment types
# - Developer environments require user authentication (not service principal)
# - Environment groups require Dataverse configuration (provider constraint)
# - See: https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/environment
#
# Supported Environment Types:
# - Sandbox: For development and testing
# - Production: For live business applications  
# - Trial: For evaluation purposes

# Query existing environments for duplicate detection
data "powerplatform_environments" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Domain calculation and duplicate detection logic
locals {
  # Always calculate domain from display_name when dataverse is enabled (for transparency and validation)
  calculated_domain = var.dataverse != null ? (
    substr(
      replace(
        replace(
          lower(var.environment.display_name),
          "/[^a-z0-9]+/", "-" # Replace any non-alphanumeric sequence with single hyphen
        ),
        "/^-+|-+$/", "" # Remove leading and trailing hyphens
      ),
      0,
      63 # Truncate to 63 characters maximum
    )
  ) : null

  # Use manual domain if provided, otherwise use calculated domain
  final_domain = var.dataverse != null ? (
    var.dataverse.domain != null ? var.dataverse.domain : local.calculated_domain
  ) : null

  # Conditional environment group assignment based on Dataverse configuration
  # Provider constraint: environment_group_id requires dataverse to be specified
  environment_group_id = var.dataverse != null ? var.environment.environment_group_id : null

  # Duplicate detection logic (unchanged)
  existing_environment_matches = var.enable_duplicate_protection ? [
    for env in try(data.powerplatform_environments.all[0].environments, []) : env
    if env.display_name == var.environment.display_name
  ] : []

  has_duplicate            = var.enable_duplicate_protection && length(local.existing_environment_matches) > 0
  duplicate_environment_id = local.has_duplicate ? local.existing_environment_matches[0].id : null
}

# Duplicate protection guardrail
resource "null_resource" "environment_duplicate_guardrail" {
  count = var.enable_duplicate_protection ? 1 : 0

  lifecycle {
    precondition {
      condition     = !local.has_duplicate
      error_message = <<-EOT
      🚨 DUPLICATE ENVIRONMENT DETECTED!
      Environment Name: "${var.environment.display_name}"
      Existing Environment ID: ${coalesce(local.duplicate_environment_id, "unknown")}
      
      RESOLUTION OPTIONS:
      1. Import existing environment:
         terraform import powerplatform_environment.this ${coalesce(local.duplicate_environment_id, "ENVIRONMENT_ID_HERE")}
      
      2. Use a different display_name
      
      3. Temporarily disable protection:
         Set enable_duplicate_protection = false
      EOT
    }
  }

  triggers = {
    display_name         = var.environment.display_name
    duplicate_protection = var.enable_duplicate_protection
  }
}

# Main Power Platform Environment Resource - REAL SCHEMA ONLY
resource "powerplatform_environment" "this" {
  depends_on = [
    null_resource.environment_duplicate_guardrail
  ]

  # ✅ REAL ARGUMENTS ONLY - NO DEVELOPER ENVIRONMENT SUPPORT
  display_name     = var.environment.display_name
  location         = var.environment.location
  environment_type = var.environment.environment_type
  description      = var.environment.description
  azure_region     = var.environment.azure_region
  cadence          = var.environment.cadence
  # AI settings removed - controlled by environment group rules
  # allow_bing_search                = var.environment.allow_bing_search
  # allow_moving_data_across_regions = var.environment.allow_moving_data_across_regions
  billing_policy_id    = var.environment.billing_policy_id
  environment_group_id = local.environment_group_id # Conditional assignment
  release_cycle        = var.environment.release_cycle

  # ✅ SIMPLIFIED DATAVERSE BLOCK with AUTO-CALCULATED DOMAIN
  dataverse = var.dataverse != null ? {
    language_code                = var.dataverse.language_code
    currency_code                = var.dataverse.currency_code
    security_group_id            = var.dataverse.security_group_id
    domain                       = local.final_domain
    administration_mode_enabled  = var.dataverse.administration_mode_enabled
    background_operation_enabled = var.dataverse.background_operation_enabled
    template_metadata            = var.dataverse.template_metadata
    templates                    = var.dataverse.templates
  } : null

  # Lifecycle management with environment group validation
  lifecycle {
    # Environment group validation - moved to lifecycle precondition
    precondition {
      condition     = var.environment.environment_group_id == null || var.dataverse != null
      error_message = <<-EOT
      🚨 ENVIRONMENT GROUP REQUIRES DATAVERSE!
      Environment Group ID: "${coalesce(var.environment.environment_group_id, "null")}"
      
      RESOLUTION OPTIONS:
      1. Add Dataverse configuration:
         dataverse = {
           language_code     = 1033
           currency_code     = "USD"
           security_group_id = "your-security-group-id"
         }
      
      2. Remove environment_group_id if Dataverse is not needed:
         Set environment_group_id = null
      
      BACKGROUND:
      The Power Platform provider requires Dataverse configuration when
      environment_group_id is specified. This is a provider constraint.
      EOT
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

# ==============================================================================
# MANAGED ENVIRONMENT CONFIGURATION (OPTIONAL)
# ==============================================================================
# WHY: Consolidate managed environment creation with environment creation
# This eliminates timing issues by creating both resources in same module context
# following the proven pattern from utl-test-environment-managed-sequence

# Local value resolution for managed environment settings
# WHY: Ensure nested optional object defaults are properly resolved
# This prevents provider errors when empty objects are passed as variables
locals {
  # Resolve sharing settings with explicit defaults
  managed_sharing_settings = {
    is_group_sharing_disabled = try(var.managed_environment_settings.sharing_settings.is_group_sharing_disabled, false)
    limit_sharing_mode        = try(var.managed_environment_settings.sharing_settings.limit_sharing_mode, "NoLimit")
    max_limit_user_sharing    = try(var.managed_environment_settings.sharing_settings.max_limit_user_sharing, -1)
  }

  # Resolve solution checker settings with explicit defaults
  managed_solution_checker = {
    mode                       = try(var.managed_environment_settings.solution_checker.mode, "Warn")
    suppress_validation_emails = try(var.managed_environment_settings.solution_checker.suppress_validation_emails, true)
    rule_overrides             = try(var.managed_environment_settings.solution_checker.rule_overrides, null)
  }

  # Resolve maker onboarding settings with explicit defaults
  managed_maker_onboarding = {
    markdown_content = try(var.managed_environment_settings.maker_onboarding.markdown_content, "Welcome to our Power Platform environment. Please follow organizational guidelines when developing solutions.")
    learn_more_url   = try(var.managed_environment_settings.maker_onboarding.learn_more_url, "https://learn.microsoft.com/power-platform/")
  }

  # Resolve usage insights setting with explicit default
  managed_usage_insights_disabled = try(var.managed_environment_settings.usage_insights_disabled, true)
}

resource "powerplatform_managed_environment" "this" {
  count = var.enable_managed_environment && var.environment.environment_type != "Developer" ? 1 : 0

  environment_id = powerplatform_environment.this.id

  # Sharing and collaboration controls - using resolved local values
  is_group_sharing_disabled = local.managed_sharing_settings.is_group_sharing_disabled
  limit_sharing_mode        = local.managed_sharing_settings.limit_sharing_mode
  max_limit_user_sharing    = local.managed_sharing_settings.max_limit_user_sharing

  # Usage insights and monitoring - using resolved local value
  is_usage_insights_disabled = local.managed_usage_insights_disabled

  # Solution validation and quality controls - using resolved local values
  solution_checker_mode           = local.managed_solution_checker.mode
  suppress_validation_emails      = local.managed_solution_checker.suppress_validation_emails
  solution_checker_rule_overrides = local.managed_solution_checker.rule_overrides

  # Maker onboarding and guidance - using resolved local values
  maker_onboarding_markdown = local.managed_maker_onboarding.markdown_content
  maker_onboarding_url      = local.managed_maker_onboarding.learn_more_url

  # Lifecycle management with enhanced validation
  lifecycle {
    # Environment ID validation
    precondition {
      condition     = length(trimspace(powerplatform_environment.this.id)) > 0 && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", powerplatform_environment.this.id))
      error_message = "🚨 INVALID ENVIRONMENT ID: Environment ID '${powerplatform_environment.this.id}' is invalid or empty. This should not occur when using this module correctly as the environment resource is created first. If you see this error, there may be a provider issue."
    }

    # Developer environment exclusion validation
    precondition {
      condition     = var.environment.environment_type != "Developer"
      error_message = "🚨 DEVELOPER ENVIRONMENTS NOT SUPPORTED: Developer environments do not support managed environment features with service principal authentication. Current environment_type: '${var.environment.environment_type}'. Please use 'Sandbox', 'Production', or 'Trial' environment types for managed environment capabilities."
    }

    # Sharing settings validation - using resolved local values
    precondition {
      condition = (
        local.managed_sharing_settings.is_group_sharing_disabled == false
        ? local.managed_sharing_settings.max_limit_user_sharing == -1
        : local.managed_sharing_settings.max_limit_user_sharing > 0
      )
      error_message = "🚨 SHARING CONFIGURATION ERROR: When group sharing is enabled (is_group_sharing_disabled = false), max_limit_user_sharing must be -1. When disabled, it must be > 0. Current: is_group_sharing_disabled = ${local.managed_sharing_settings.is_group_sharing_disabled}, max_limit_user_sharing = ${local.managed_sharing_settings.max_limit_user_sharing}."
    }

    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All managed environment changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []
  }

  # WHY: Explicit dependency ensures environment is fully created
  # This eliminates the need for artificial time delays
  depends_on = [powerplatform_environment.this]
}