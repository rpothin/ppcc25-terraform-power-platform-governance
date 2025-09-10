# Output Values for Power Platform Environment Configuration
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.
#
# Updated to align with the corrected provider schema and variable names.

# Primary environment identifier for downstream configurations
output "environment_id" {
  description = <<DESCRIPTION
The unique identifier of the Power Platform environment.

This output provides the primary key for referencing this environment
in other Terraform configurations, DLP policies, or external systems.
The ID is stable across environment updates and safe for external consumption.
DESCRIPTION
  value       = powerplatform_environment.this.id
}

# Environment URL for applications and integrations (via Dataverse when available)
output "environment_url" {
  description = <<DESCRIPTION
The web URL for accessing the Power Platform environment.

This URL can be used for:
- Direct admin center access
- Power Apps maker portal links
- Power Automate environment access
- API endpoint construction

Note: Returns Dataverse URL when Dataverse is enabled, otherwise null.
DESCRIPTION
  value       = try(powerplatform_environment.this.dataverse[0].url, null)
}

# Dataverse organization URL (when Dataverse is enabled)
output "dataverse_organization_url" {
  description = <<DESCRIPTION
The organization URL for the Dataverse database, if enabled.

Returns the base URL for Dataverse API access and application integrations.
Will be null if Dataverse is not configured for this environment.
DESCRIPTION
  value       = try(powerplatform_environment.this.dataverse[0].url, null)
}

# Environment configuration summary for validation and reporting
output "environment_summary" {
  description = "Summary of deployed environment configuration for validation and compliance reporting"
  value = {
    name                             = powerplatform_environment.this.display_name
    environment_id                   = powerplatform_environment.this.id
    location                         = powerplatform_environment.this.location
    environment_type                 = powerplatform_environment.this.environment_type
    azure_region                     = powerplatform_environment.this.azure_region
    environment_url                  = try(powerplatform_environment.this.dataverse[0].url, null)
    has_dataverse                    = var.dataverse != null
    dataverse_url                    = try(powerplatform_environment.this.dataverse[0].url, null)
    cadence                          = powerplatform_environment.this.cadence
    allow_bing_search                = powerplatform_environment.this.allow_bing_search
    allow_moving_data_across_regions = powerplatform_environment.this.allow_moving_data_across_regions
    billing_policy_id                = powerplatform_environment.this.billing_policy_id
    environment_group_id             = powerplatform_environment.this.environment_group_id
    release_cycle                    = powerplatform_environment.this.release_cycle
    deployment_timestamp             = timestamp()
    resource_type                    = "powerplatform_environment"
    classification                   = "res-environment"
    terraform_managed                = true
    duplicate_protection_enabled     = var.enable_duplicate_protection
  }
}

# Dataverse configuration details (when enabled) with domain calculation info
output "dataverse_configuration" {
  description = "Dataverse database configuration details when enabled, null otherwise"
  value = var.dataverse != null ? {
    organization_url             = try(powerplatform_environment.this.dataverse[0].url, null)
    organization_id              = try(powerplatform_environment.this.dataverse[0].organization_id, null)
    unique_name                  = try(powerplatform_environment.this.dataverse[0].unique_name, null)
    version                      = try(powerplatform_environment.this.dataverse[0].version, null)
    language_code                = var.dataverse.language_code
    currency_code                = var.dataverse.currency_code
    security_group_id            = var.dataverse.security_group_id
    domain_requested             = var.dataverse.domain
    domain_calculated            = local.calculated_domain
    domain_final                 = local.final_domain
    domain_source                = var.dataverse.domain != null ? "manual" : "auto-calculated"
    administration_mode_enabled  = var.dataverse.administration_mode_enabled
    background_operation_enabled = var.dataverse.background_operation_enabled
    template_metadata            = var.dataverse.template_metadata
    templates                    = var.dataverse.templates
    linked_app_id                = try(powerplatform_environment.this.dataverse[0].linked_app_id, null)
    linked_app_type              = try(powerplatform_environment.this.dataverse[0].linked_app_type, null)
    linked_app_url               = try(powerplatform_environment.this.dataverse[0].linked_app_url, null)
  } : null
  sensitive = false # Organization details are not sensitive for operations teams
}

# Enterprise policies information (read-only from provider)
output "enterprise_policies" {
  description = "Enterprise policies applied to the environment (read-only from provider)"
  value       = try(powerplatform_environment.this.enterprise_policies, [])
}

# Domain calculation details for transparency and validation
output "domain_calculation_summary" {
  description = "Summary of domain calculation logic and results for transparency"
  value = var.dataverse != null ? {
    display_name_input  = var.environment.display_name
    domain_requested    = var.dataverse.domain
    domain_calculated   = local.calculated_domain
    domain_final        = local.final_domain
    domain_source       = var.dataverse.domain != null ? "manual" : "auto-calculated"
    calculation_applied = var.dataverse.domain == null
  } : null
}

# Additional outputs for AVM compliance and operational visibility
output "environment_metadata" {
  description = "Additional environment metadata for operational monitoring and compliance"
  value = {
    provider_version = "~> 3.8"
    module_version   = "1.0.0"
    creation_method  = "terraform"
    avm_compliant    = true
    last_updated     = timestamp()
    configuration_hash = sha256(jsonencode({
      environment = var.environment
      dataverse   = var.dataverse
    }))
  }
}