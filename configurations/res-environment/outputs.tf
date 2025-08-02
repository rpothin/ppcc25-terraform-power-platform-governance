# Output Values for Power Platform Environment Configuration
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

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
  value       = try(powerplatform_environment.this.dataverse.url, null)
}

# Dataverse organization URL (when Dataverse is enabled)
output "dataverse_organization_url" {
  description = <<DESCRIPTION
The organization URL for the Dataverse database, if enabled.

Returns the base URL for Dataverse API access and application integrations.
Will be null if Dataverse is not configured for this environment.
DESCRIPTION
  value       = try(powerplatform_environment.this.dataverse.url, null)
}

# Environment configuration summary for validation and reporting
output "environment_summary" {
  description = "Summary of deployed environment configuration for validation and compliance reporting"
  value = {
    name                         = powerplatform_environment.this.display_name
    environment_id               = powerplatform_environment.this.id
    location                     = powerplatform_environment.this.location
    environment_type             = powerplatform_environment.this.environment_type
    environment_url              = try(powerplatform_environment.this.dataverse.url, null)
    has_dataverse                = var.dataverse_config != null
    dataverse_url                = try(powerplatform_environment.this.dataverse.url, null)
    deployment_timestamp         = timestamp()
    resource_type                = "powerplatform_environment"
    classification               = "res-environment"
    terraform_managed            = true
    duplicate_protection_enabled = var.enable_duplicate_protection
  }
}

# Dataverse configuration details (when enabled)
output "dataverse_configuration" {
  description = "Dataverse database configuration details when enabled, null otherwise"
  value = var.dataverse_config != null ? {
    organization_url  = try(powerplatform_environment.this.dataverse.url, null)
    language_code     = var.dataverse_config.language_code
    currency_code     = var.dataverse_config.currency_code
    security_group_id = var.dataverse_config.security_group_id
    domain            = var.dataverse_config.domain
    organization_name = var.dataverse_config.organization_name
  } : null
  sensitive = false # Organization details are not sensitive for operations teams
}