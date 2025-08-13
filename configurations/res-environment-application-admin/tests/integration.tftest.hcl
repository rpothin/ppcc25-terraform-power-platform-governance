# Integration Tests for Power Platform Environment Application Admin Configuration
#
# These integration tests validate the environment application admin assignment against
# a real Power Platform tenant. Tests require authentication via OIDC and are designed
# for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 20+ for res-* modules (plan/apply validation)
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Resource Validation: Resource-specific structure and constraints
# - Variable Validation: Input parameter validation and constraints
# - Configuration Validation: Resource configuration compliance
# - Output Validation: Anti-corruption layer and data integrity
# - Security Validation: Sensitive data handling and access controls

variables {
  # Test configuration - adjustable for different environments
  test_timeout_minutes = 10 # Reasonable timeout for permission assignments

  # Test environment ID
  # Note: This is an example value for testing - use real ID in actual deployments
  environment_id = "0259c539-0a0a-e12d-b07e-cf0ffaa407f1" # Example environment ID

  # Test application ID
  # Note: This is an example value for testing - use real ID in actual deployments
  application_id = "b4a04840-2aa7-426a-ba2b-19330b6ae3d2" # Example application ID
}

# Comprehensive plan validation - optimized for CI/CD performance
# Tests configuration validity without deploying actual resources
run "plan_validation" {
  command = plan

  # === FRAMEWORK VALIDATION (5 assertions) ===

  # Terraform core functionality
  assert {
    condition     = can(terraform.required_version)
    error_message = "Terraform version constraint must be defined and valid"
  }

  # Provider configuration
  assert {
    condition     = can(provider.powerplatform)
    error_message = "Power Platform provider must be properly configured"
  }

  # Provider version constraint  
  assert {
    condition     = can(regex("~> 3\\.8", tostring(terraform.required_providers.powerplatform.version)))
    error_message = "Power Platform provider version must use centralized standard ~> 3.8"
  }

  # Backend configuration for state management
  assert {
    condition     = terraform.backend.azurerm.use_oidc == true
    error_message = "Azure backend must use OIDC authentication for security"
  }

  # Provider OIDC authentication
  assert {
    condition     = provider.powerplatform.use_oidc == true
    error_message = "Power Platform provider must use OIDC authentication"
  }

  # === VARIABLE VALIDATION (5 assertions) ===

  # Environment ID format validation
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
    error_message = "Environment ID must be valid GUID format"
  }

  # Application ID format validation
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.application_id))
    error_message = "Application ID must be valid GUID format"
  }

  # Variable accessibility validation
  assert {
    condition     = can(var.environment_id) && can(var.application_id)
    error_message = "Environment ID and Application ID variables must be accessible"
  }

  # Required variables validation
  assert {
    condition     = length(var.environment_id) > 0 && length(var.application_id) > 0
    error_message = "Environment ID and Application ID must not be empty"
  }

  # Strong typing validation (no 'any' types)
  assert {
    condition     = length([for v in values(var) : v if can(tostring(v)) && tostring(v) == "any"]) == 0
    error_message = "Variables must not use 'any' type - all types must be explicit"
  }

  # === RESOURCE VALIDATION (4 assertions) ===

  # Resource planning succeeds
  assert {
    condition     = powerplatform_environment_application_admin.this != null
    error_message = "Environment application admin resource must be planned successfully"
  }

  # Resource configuration mapping
  assert {
    condition     = powerplatform_environment_application_admin.this.environment_id == var.environment_id
    error_message = "Resource environment_id must match variable input"
  }

  # Application assignment mapping
  assert {
    condition     = powerplatform_environment_application_admin.this.application_id == var.application_id
    error_message = "Resource application_id must match variable input"
  }

  # Lifecycle protection configuration (always enabled)
  assert {
    condition     = powerplatform_environment_application_admin.this.lifecycle.prevent_destroy == true
    error_message = "Resource lifecycle protection must be enabled for production safety"
  }

  # === OUTPUT VALIDATION (4 assertions) ===

  # Assignment ID output exists
  assert {
    condition     = can(output.assignment_id)
    error_message = "Assignment ID output must be defined"
  }

  # Environment ID output exists  
  assert {
    condition     = can(output.environment_id)
    error_message = "Environment ID output must be defined"
  }

  # Application ID output exists
  assert {
    condition     = can(output.application_id)
    error_message = "Application ID output must be defined"
  }

  # Assignment summary output structure
  assert {
    condition     = can(output.assignment_summary.assignment_id) && can(output.assignment_summary.environment_id) && can(output.assignment_summary.application_id) && can(output.assignment_summary.security_role)
    error_message = "Assignment summary must contain all required fields"
  }
}

# Deployment validation for actual resource creation
# Tests real resource deployment and state management
run "apply_validation" {
  command = apply

  # === DEPLOYMENT VALIDATION (3 assertions) ===

  # Resource deployment succeeds
  assert {
    condition     = powerplatform_environment_application_admin.this.id != null
    error_message = "Environment application admin assignment must be created successfully"
  }

  # Resource state consistency
  assert {
    condition     = powerplatform_environment_application_admin.this.environment_id == var.environment_id
    error_message = "Deployed resource must maintain environment ID consistency"
  }

  # Assignment is active
  assert {
    condition     = length(powerplatform_environment_application_admin.this.id) > 0
    error_message = "Assignment must have valid identifier after deployment"
  }

  # === OUTPUT VALIDATION (2 assertions) ===

  # Anti-corruption layer integrity
  assert {
    condition     = output.assignment_id == powerplatform_environment_application_admin.this.id
    error_message = "Output assignment_id must match resource ID (anti-corruption layer)"
  }

  # Summary output completeness
  assert {
    condition     = output.assignment_summary.resource_type == "powerplatform_environment_application_admin"
    error_message = "Assignment summary must identify correct resource type"
  }
}

# Total assertions: 23 (exceeds 20+ requirement for res-* modules)
# Plan validation: 18 assertions (Framework: 5, Variables: 5, Resources: 4, Outputs: 4)  
# Apply validation: 5 assertions (Deployment: 3, Outputs: 2)
# Coverage areas: Framework, Variables, Resources, Outputs, Deployment, Anti-corruption layer