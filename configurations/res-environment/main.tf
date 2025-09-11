# Power Platform Environment Configuration - Provider Schema Compliant
#
# This configuration uses ONLY the arguments that actually exist in the
# microsoft/power-platform provider to ensure 100% compatibility.
#
# For production environments with existing resources:
# - Use 'terraform import' to bring existing environments under management
# - Implement organizational policies to prevent manual environment creation
# - Consider using 'terraform plan' to identify conflicts before apply
#
# ⚠️  KNOWN LIMITATIONS:
# - Developer environments are NOT SUPPORTED with service principal authentication
# - This module only supports Sandbox, Production, and Trial environment types
# - Environment groups require Dataverse configuration (provider constraint)
#
# Supported Environment Types:
# - Sandbox: For development and testing
# - Production: For live business applications  
# - Trial: For evaluation purposes

# Domain calculation and environment group logic
locals {
  # Always calculate domain from display_name when dataverse is enabled
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
  environment_group_id = var.dataverse != null ? var.environment.environment_group_id : null
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