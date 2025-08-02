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
environment_config = {
  # Example naming following organizational standards
  display_name     = "Example Development Environment" # Follows descriptive naming pattern
  location         = "unitedstates"                    # Primary region for most organizations
  environment_type = "Sandbox"                         # Safe default for development/testing
}

# Dataverse configuration (optional - remove entire block if not needed)
dataverse_config = {
  language_code     = 1033 # English (United States)
  currency_code     = "USD"  # US Dollar
  security_group_id = null   # Optional: Set to Azure AD group ID for access control
  domain            = null   # Optional: Custom domain (auto-generated if not provided)
}

# Alternatively, to create environment without Dataverse:
# dataverse_config = null

# Enable duplicate protection for production safety
enable_duplicate_protection = true

# Optional tags for organization and cost tracking
tags = {
  Environment = "Development"
  Department  = "IT"
  Owner       = "platform-team@example.com"
  Project     = "Power Platform Governance"
  CostCenter  = "IT-001"
}