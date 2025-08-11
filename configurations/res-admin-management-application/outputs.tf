# Output Values for Power Platform Admin Management Application
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

# Primary resource identifier for downstream configurations
output "registration_id" {
  description = <<DESCRIPTION
The client ID of the registered service principal.

This output provides the primary identifier for the Power Platform admin
registration, which can be used for referencing this registration in other
Terraform configurations or external systems.

The value represents the same client ID that was provided as input,
confirming successful registration as a Power Platform administrator.
DESCRIPTION
  value       = powerplatform_admin_management_application.this.id
}

# Registration status and operational information
output "registration_status" {
  description = <<DESCRIPTION
Status information about the admin registration operation.

This output provides operational details about the registration process,
including confirmation that the service principal is successfully registered
as a Power Platform administrator.

Value indicates successful completion of the registration process.
DESCRIPTION
  value       = "registered"
}

# Configuration summary for validation and reporting
output "configuration_summary" {
  description = <<DESCRIPTION
Summary of deployed admin registration configuration for validation and compliance reporting.

This output provides a comprehensive overview of the admin registration
deployment, including key configuration details, operational status,
and metadata for governance and audit purposes.

The summary includes:
- Client ID of the registered service principal
- Resource type and classification information
- Deployment timestamp and validation status
- Configuration parameters used during deployment

This information supports compliance reporting, operational validation,
and integration with downstream automation systems.
DESCRIPTION
  value = {
    client_id          = powerplatform_admin_management_application.this.id
    resource_type      = "powerplatform_admin_management_application"
    classification     = "res-"
    deployment_status  = "registered"
    registration_date  = timestamp()
    validation_enabled = var.enable_validation
    timeout_configured = var.timeout_configuration != null
    module_version     = "1.0.0"
  }
}