# Power Platform Environment Configuration - Provider Schema Compliant
#
# This configuration uses ONLY the arguments that actually exist in the
# microsoft/power-platform provider to ensure 100% compatibility.
#
# ⚠️  KNOWN LIMITATIONS:
# - Developer environments are NOT SUPPORTED with service principal authentication
# - This module only supports Sandbox, Production, and Trial environment types
# - Developer environments require user authentication (not service principal)
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

  # ✅ REAL ARGUMENTS ONLY - NO DEVELOPER ENVIRONMENT SUPPORT
  display_name                     = var.environment.display_name
  location                         = var.environment.location
  environment_type                 = var.environment.environment_type
  description                      = var.environment.description
  azure_region                     = var.environment.azure_region
  cadence                          = var.environment.cadence
  allow_bing_search                = var.environment.allow_bing_search
  allow_moving_data_across_regions = var.environment.allow_moving_data_across_regions
  billing_policy_id                = var.environment.billing_policy_id
  environment_group_id             = var.environment.environment_group_id
  release_cycle                    = var.environment.release_cycle

  # ✅ SIMPLIFIED DATAVERSE BLOCK - NO DEVELOPER ENVIRONMENT HANDLING
  dataverse = var.dataverse != null ? {
    language_code                = var.dataverse.language_code
    currency_code                = var.dataverse.currency_code
    security_group_id            = var.dataverse.security_group_id
    domain                       = var.dataverse.domain
    administration_mode_enabled  = var.dataverse.administration_mode_enabled
    background_operation_enabled = var.dataverse.background_operation_enabled
    template_metadata            = var.dataverse.template_metadata
    templates                    = var.dataverse.templates
  } : null

  # Lifecycle management
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description, # Allow manual updates in admin center
    ]
  }
}