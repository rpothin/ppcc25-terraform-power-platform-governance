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
# CRITICAL: All variables use explicit types with comprehensive validation.
# The `any` type is forbidden in all production modules.

variable "environment_id" {
  type        = string
  description = <<DESCRIPTION
The unique identifier of the target Power Platform environment where admin permissions will be assigned.

This GUID identifies the specific Power Platform environment that will receive the application
admin assignment. The environment must exist and be accessible by the service principal
executing the Terraform configuration.

Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')
Usage: Target environment for application admin permission assignment
Source: Power Platform Admin Center or PowerShell cmdlets

Example:
environment_id = "12345678-1234-1234-1234-123456789012"

Validation Rules:
- Must be valid GUID format for Power Platform compatibility
- Environment must exist and be accessible by the service principal
- Environment must allow application user assignments

Note: The System Administrator role is automatically assigned by Power Platform
and cannot be customized. This ensures the application has full administrative
permissions required for environment management operations.
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
    error_message = "Environment ID must be a valid GUID format (e.g., '12345678-1234-1234-1234-123456789012'). Verify the environment exists in your Power Platform tenant and is accessible."
  }
}

variable "application_id" {
  type        = string
  description = <<DESCRIPTION
The Azure AD application (client) ID that will receive admin permissions in the Power Platform environment.

This GUID identifies the Azure AD application registration that will be granted
System Administrator privileges within the specified Power Platform environment.
The application must be properly registered and configured for Power Platform access.

Format: GUID (e.g., '87654321-4321-4321-4321-210987654321')
Usage: Application that will receive admin permissions
Source: Azure AD App Registration or PowerShell cmdlets

Example:
application_id = "87654321-4321-4321-4321-210987654321"

Validation Rules:
- Must be valid GUID format for Azure AD compatibility
- Application must be registered in Azure AD
- Application must have Power Platform service principal permissions
- Application must not already have conflicting role assignments

Important: The System Administrator role is automatically assigned by Power Platform
and provides full administrative access to the environment. This is required for
Terraform service principals and automated environment management scenarios.

Note: Lifecycle protection (prevent_destroy) is always enabled for production safety.
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.application_id))
    error_message = "Application ID must be a valid GUID format (e.g., '87654321-4321-4321-4321-210987654321'). This should be the Azure AD application (client) ID from your app registration."
  }
}