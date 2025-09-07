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

  # Lifecycle management with duplicate detection and environment group validation
  lifecycle {
    # DUPLICATE DETECTION - moved to lifecycle precondition for better error handling
    precondition {
      condition     = !var.enable_duplicate_protection || !local.has_duplicate
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
# WHY: Use external res-managed-environment module for managed environment creation
# This follows the proven pattern from utl-test-environment-managed-sequence that
# eliminates the "Request url must be an absolute url" error by using proper
# module boundaries and dependency management

# Managed environment module call (simplified pattern)
# WHY: Only pass required environment_id, let module defaults handle everything else
# This avoids provider consistency bugs and uses battle-tested configurations
module "managed_environment" {
  count = var.enable_managed_environment && var.environment.environment_type != "Developer" ? 1 : 0

  source = "../res-managed-environment"

  # WHY: Only pass required environment_id, let module defaults handle everything else
  # This avoids provider consistency bugs and uses battle-tested configurations
  environment_id = powerplatform_environment.this.id

  # WHY: Explicit dependency ensures managed environment waits for environment creation
  depends_on = [powerplatform_environment.this]
}