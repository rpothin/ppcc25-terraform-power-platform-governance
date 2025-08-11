# Input Variables for Power Platform Environment Application Admin Configuration
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Primary application admin assignment settings
# - Environment Settings: Target environment and application parameters
# - Security Settings: Authentication and access controls
# - Feature Flags: Optional functionality toggles
#
# CRITICAL: All complex variables use explicit object types with property-level validation.
# The `any` type is forbidden in all production modules.

variable "environment_application_admin_config" {
  type = object({
    environment_id = string
    application_id = string
  })
  description = <<DESCRIPTION
Configuration object for environment application admin permission assignment.

This variable consolidates core settings for granting application admin permissions
within a Power Platform environment, enabling programmatic access and management.
The System Administrator role is automatically assigned to the application user.

Properties:
- environment_id: The unique identifier of the target Power Platform environment (GUID format)
- application_id: The Azure AD application (client) ID that will receive admin permissions (GUID format)

Example:
environment_application_admin_config = {
  environment_id = "12345678-1234-1234-1234-123456789012"
  application_id = "87654321-4321-4321-4321-210987654321"
}

Validation Rules:
- All IDs must be valid GUID format for Power Platform compatibility
- Environment must exist and be accessible by the service principal
- Application must be registered in Azure AD with Power Platform service principal

Important: The System Administrator role is automatically assigned by Power Platform
and cannot be customized. This ensures the application has full administrative
permissions required for environment management operations.

Note: Lifecycle protection (prevent_destroy) is always enabled for production safety.
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_application_admin_config.environment_id))
    error_message = "Environment ID must be a valid GUID format (e.g., '12345678-1234-1234-1234-123456789012'). Verify the environment exists in your Power Platform tenant and is accessible."
  }

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_application_admin_config.application_id))
    error_message = "Application ID must be a valid GUID format (e.g., '87654321-4321-4321-4321-210987654321'). This should be the Azure AD application (client) ID from your app registration."
  }
}