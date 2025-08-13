# Example Environment Configuration for Power Platform Environment
#
# This file contains example values for the res-environment configuration.
# Copy this file and customize it for your specific environment needs.
#
# Configuration Philosophy:
# - Environment Appropriate: Values suited for general purpose workloads
# - Security Conscious: No sensitive data, references to secure storage
# - Operationally Friendly: Clear naming and documentation for support teams
# - Change Trackable: Version controlled for audit and rollback capability

# Core environment configuration
environment = {
  # Example naming following organizational standards
  display_name         = "Example Development Environment"      # Follows descriptive naming pattern
  location             = "unitedstates"                         # Primary region for most organizations
  environment_type     = "Sandbox"                              # Safe default for development/testing
  environment_group_id = "12345678-1234-1234-1234-123456789012" # REQUIRED: Azure AD group for governance
}

# Dataverse configuration (optional - remove entire block if not needed)
dataverse = {
  language_code     = 1033                                   # English (United States)
  currency_code     = "USD"                                  # US Dollar
  security_group_id = "87654321-4321-4321-4321-210987654321" # REQUIRED: Azure AD group for Dataverse access
  domain            = null                                   # Optional: Auto-calculated from display_name if not provided
}

# Alternatively, to create environment without Dataverse:
# dataverse = null

# Enable duplicate protection for production safety
enable_duplicate_protection = true