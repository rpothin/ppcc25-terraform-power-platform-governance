# Power Platform Environment Configuration - Provider Schema Compliant
#
# This configuration uses ONLY the arguments that actually exist in the
# microsoft/power-platform provider to ensure 100% compatibility.

# Query existing environments for duplicate detection
data "powerplatform_environments" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Duplicate detection logic
locals {
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
  depends_on = [null_resource.environment_duplicate_guardrail]

  # ✅ REAL ARGUMENTS ONLY
  display_name                     = var.environment.display_name
  location                         = var.environment.location
  environment_type                 = var.environment.environment_type
  owner_id                         = var.environment.owner_id
  description                      = var.environment.description
  azure_region                     = var.environment.azure_region
  cadence                          = var.environment.cadence
  allow_bing_search                = var.environment.allow_bing_search
  allow_moving_data_across_regions = var.environment.allow_moving_data_across_regions
  billing_policy_id                = var.environment.billing_policy_id
  environment_group_id             = var.environment.environment_group_id
  release_cycle                    = var.environment.release_cycle

  # ✅ REAL DATAVERSE BLOCK - FIXED TYPE CONSISTENCY
  dataverse = var.dataverse != null ? {
    # Use provided dataverse configuration
    language_code                = var.dataverse.language_code
    currency_code                = var.dataverse.currency_code
    security_group_id            = var.dataverse.security_group_id
    domain                       = var.dataverse.domain
    administration_mode_enabled  = var.dataverse.administration_mode_enabled
    background_operation_enabled = var.dataverse.background_operation_enabled
    template_metadata            = var.dataverse.template_metadata
    templates                    = var.dataverse.templates
    } : (
    # Default Dataverse for Developer environments (CONSISTENT TYPE)
    var.environment.environment_type == "Developer" && var.environment.owner_id != null ? {
      language_code                = 1033  # English (United States)
      currency_code                = "USD" # US Dollar
      security_group_id            = null  # No security group by default
      domain                       = null  # Auto-generated domain
      administration_mode_enabled  = null  # Use platform default
      background_operation_enabled = null  # Use platform default
      template_metadata            = null  # No template metadata
      templates                    = null  # No templates
    } : null                               # No Dataverse for non-Developer environments without explicit config
  )

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      description, # Allow manual updates in admin center
    ]
  }
}