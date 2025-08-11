# Output Values for Power Platform Environment Application Admin Configuration
#
# This file implements the AVM anti-corruption layer pattern by outputting
# discrete computed attributes instead of complete resource objects.
# This approach enhances security and maintains interface stability.

# Primary assignment identifier for downstream configurations
output "assignment_id" {
  description = <<DESCRIPTION
The unique identifier of the environment application admin assignment.

This output provides the primary key for referencing this permission assignment
in other Terraform configurations or external systems. The ID can be used for
dependency management and cross-configuration references.

Format: Resource-specific identifier from Power Platform
Usage: Reference in downstream configurations requiring this assignment
DESCRIPTION
  value       = powerplatform_environment_application_admin.this.id
}

# Environment identifier for validation and tracking
output "environment_id" {
  description = <<DESCRIPTION
The Power Platform environment ID where the admin assignment was created.

This output confirms the target environment for the permission assignment,
useful for validation and audit trails in multi-environment deployments.

Format: GUID identifier of the Power Platform environment
Usage: Environment validation and cross-reference in governance reports
DESCRIPTION
  value       = powerplatform_environment_application_admin.this.environment_id
}

# Application identifier for permission tracking
output "application_id" {
  description = <<DESCRIPTION
The Azure AD application ID that received the admin permissions.

This output identifies which application was granted admin access,
essential for security auditing and permission management workflows.

Format: GUID identifier of the Azure AD application
Usage: Security audits and permission inventory reporting
DESCRIPTION
  value       = powerplatform_environment_application_admin.this.application_id
}

# Configuration summary for validation and compliance reporting
output "assignment_summary" {
  description = <<DESCRIPTION
Summary of the environment application admin assignment for validation and compliance reporting.

This consolidated output provides key assignment details in a structured format
suitable for governance dashboards, audit reports, and operational monitoring.

Contents:
- assignment_id: Unique identifier of the permission assignment
- environment_id: Target environment identifier
- application_id: Application that received permissions
- security_role: Security role automatically assigned (System Administrator)
- resource_type: Type of resource deployed (for reporting)
- deployment_timestamp: When the assignment was created
- lifecycle_protection: Whether prevent_destroy is enabled

Usage: Governance reporting, audit trails, operational dashboards
DESCRIPTION
  value = {
    assignment_id        = powerplatform_environment_application_admin.this.id
    environment_id       = powerplatform_environment_application_admin.this.environment_id
    application_id       = powerplatform_environment_application_admin.this.application_id
    security_role        = "System Administrator" # Automatically assigned by Power Platform
    resource_type        = "powerplatform_environment_application_admin"
    deployment_timestamp = timestamp()
    lifecycle_protection = true # Always enabled for production safety
  }
}