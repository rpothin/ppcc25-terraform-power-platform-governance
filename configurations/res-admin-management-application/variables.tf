# Input Variables for Power Platform Admin Management Application
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Core Configuration: Service principal identification and registration settings
# - Validation Settings: Controls for optional validation and safety checks
# - Timeout Settings: Operational timeout configuration for resource operations
#
# CRITICAL: All complex variables use explicit object types with property-level validation.
# The `any` type is forbidden in all production modules.

variable "client_id" {
  type        = string
  description = <<DESCRIPTION
Service principal client ID (Application ID) to register as Power Platform administrator.

This variable specifies the Azure AD service principal that will be granted 
Power Platform administrator privileges for tenant governance operations.

The client ID must be:
- A valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
- An existing service principal in the Azure AD tenant
- Accessible to the current authentication context
- Not already registered as a Power Platform administrator (unless importing)

Example:
client_id = "12345678-1234-1234-1234-123456789012"

Validation Rules:
- Must be a valid UUID format for Azure AD compatibility
- Required field - cannot be empty or null
- Used as the primary identifier for the admin registration resource

Security Considerations:
- This value is not sensitive but should be managed through secure configuration
- Service principal should follow principle of least privilege
- Consider using dedicated service principals for governance automation
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.client_id))
    error_message = "Client ID must be a valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx). Received: '${var.client_id}'. Verify the service principal client ID is correct."
  }

  validation {
    condition     = length(var.client_id) > 0
    error_message = "Client ID cannot be empty. Please provide a valid service principal client ID for Power Platform admin registration."
  }
}

variable "enable_validation" {
  type        = bool
  description = <<DESCRIPTION
Enable additional validation checks for service principal registration.

When enabled, this variable activates supplementary validation to ensure:
- Client ID format is valid UUID
- Service principal accessibility verification
- Registration prerequisite validation

Set to false to disable validation checks (not recommended for production).

Example:
enable_validation = true

Validation Rules:
- Must be a boolean value (true/false)
- Defaults to true for production safety
- Can be temporarily disabled for troubleshooting or import scenarios

Operational Impact:
- When true: Provides early detection of configuration issues
- When false: Skips validation but may result in deployment failures
- Recommended: Keep enabled except for specific troubleshooting scenarios
DESCRIPTION

  default = true

  validation {
    condition     = can(tobool(var.enable_validation))
    error_message = "Enable validation must be a boolean value (true or false)."
  }
}

variable "timeout_configuration" {
  type = object({
    create = optional(string, "5m")
    delete = optional(string, "5m")
    read   = optional(string, "2m")
  })
  description = <<DESCRIPTION
Timeout configuration for Power Platform admin management operations.

This variable configures operation timeouts to handle varying response times
for Power Platform admin registration operations across different tenants.

Properties:
- create: Timeout for creating admin registration (default: "5m")
- delete: Timeout for removing admin registration (default: "5m")  
- read: Timeout for reading admin registration status (default: "2m")

Example:
timeout_configuration = {
  create = "10m"  # Extended timeout for large tenants
  delete = "5m"   # Standard timeout for deregistration
  read   = "2m"   # Quick timeout for status checks
}

Validation Rules:
- All timeout values must be valid Go duration strings
- Minimum recommended: 1m for create/delete, 30s for read
- Maximum recommended: 30m for any operation
- Format: "1m", "2h30m", "45s" etc.

Operational Considerations:
- Larger tenants may require longer timeouts
- Network latency affects operation duration
- Power Platform service throttling may extend operation time
DESCRIPTION

  default = null

  validation {
    condition = var.timeout_configuration == null || alltrue([
      for timeout in [var.timeout_configuration.create, var.timeout_configuration.delete, var.timeout_configuration.read] :
      timeout == null || can(regex("^[0-9]+[smh]$", timeout))
    ])
    error_message = "All timeout values must be valid Go duration strings (e.g., '5m', '1h', '30s'). Check that create, delete, and read timeouts use valid duration format."
  }

  validation {
    condition = var.timeout_configuration == null || alltrue([
      for timeout in values(var.timeout_configuration) :
      timeout == null || (
        can(regex("^[0-9]+[smh]$", timeout)) &&
        tonumber(regex("^([0-9]+)", timeout)[0]) > 0
      )
    ])
    error_message = "Timeout values must be positive durations. Zero or negative timeouts are not allowed for operational reliability."
  }
}