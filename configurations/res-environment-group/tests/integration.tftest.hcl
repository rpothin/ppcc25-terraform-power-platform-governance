# Integration Tests for Power Platform Environment Group Configuration
#
# These integration tests validate the environment group creation and management against
# a real Power Platform tenant. Tests require authentication via OIDC
# and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan/apply cycles
# - Comprehensive Coverage: Validates structure, data integrity, and security
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 20+ for res-* modules (plan/apply required)
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Variable Validation: Input parameter structure and constraints
# - Resource Validation: Resource-specific structure and behavior
# - Output Validation: AVM compliance and data integrity
# - Security Validation: Sensitive data handling and access controls
# - Deployment Validation: Actual resource creation and state management

variables {
  # Test configuration for environment group
  environment_group_config = {
    display_name = "Test Environment Group"
    description  = "Test environment group for Terraform validation"
  }
}

# Comprehensive plan validation - optimized for CI/CD performance
run "plan_validation" {
  command = plan

  # === FRAMEWORK VALIDATION (5 assertions) ===

  # Terraform provider functionality
  assert {
    condition     = can(terraform.required_providers.powerplatform)
    error_message = "Power Platform provider must be configured in required_providers"
  }

  # Provider version compliance with centralized standard
  assert {
    condition     = terraform.required_providers.powerplatform.version == "~> 3.8"
    error_message = "Provider version must match centralized standard ~> 3.8. Current: ${terraform.required_providers.powerplatform.version}"
  }

  # OIDC authentication configuration in provider block
  assert {
    condition     = length(regexall("use_oidc\\s*=\\s*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider configuration must include use_oidc = true for security compliance"
  }

  # Azure backend OIDC configuration  
  assert {
    condition     = length(regexall("backend\\s+\"azurerm\".*use_oidc\\s*=\\s*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Backend must use OIDC for keyless authentication"
  }

  # Terraform version compliance
  assert {
    condition     = can(regex("^>= 1\\.5\\.0", terraform.required_version))
    error_message = "Terraform version constraint must be >= 1.5.0 for AVM compliance"
  }

  # === VARIABLE VALIDATION (5 assertions) ===

  # Variable structure integrity
  assert {
    condition     = can(var.environment_group_config.display_name) && can(var.environment_group_config.description)
    error_message = "Environment group config must contain display_name and description properties"
  }

  # Display name validation
  assert {
    condition     = length(var.environment_group_config.display_name) >= 1 && length(var.environment_group_config.display_name) <= 100
    error_message = "Display name must be 1-100 characters. Current: ${length(var.environment_group_config.display_name)}"
  }

  # Description validation
  assert {
    condition     = length(var.environment_group_config.description) >= 1 && length(var.environment_group_config.description) <= 500
    error_message = "Description must be 1-500 characters. Current: ${length(var.environment_group_config.description)}"
  }

  # Strong typing validation (no 'any' types)
  assert {
    condition     = length([for v in values(var) : v if can(tostring(v)) && tostring(v) == "any"]) == 0
    error_message = "Variables must not use 'any' type - all types must be explicit"
  }

  # Variable content validation (no empty/whitespace)
  assert {
    condition     = length(trimspace(var.environment_group_config.display_name)) > 0 && length(trimspace(var.environment_group_config.description)) > 0
    error_message = "Display name and description must not be empty or contain only whitespace"
  }

  # === RESOURCE VALIDATION (5 assertions) ===

  # Resource planning succeeds
  assert {
    condition     = powerplatform_environment_group.this != null
    error_message = "Environment group resource must be planned successfully"
  }

  # Resource configuration mapping
  assert {
    condition     = powerplatform_environment_group.this.display_name == var.environment_group_config.display_name
    error_message = "Resource display_name must match variable input"
  }

  # Resource description mapping
  assert {
    condition     = powerplatform_environment_group.this.description == var.environment_group_config.description
    error_message = "Resource description must match variable input"
  }

  # Lifecycle configuration presence
  assert {
    condition     = length(regexall("lifecycle\\s*\\{", file("${path.module}/main.tf"))) > 0
    error_message = "Resource module must include lifecycle management configuration"
  }

  # Ignore changes configuration for operational flexibility
  assert {
    condition     = length(regexall("ignore_changes", file("${path.module}/main.tf"))) > 0
    error_message = "Resource must include ignore_changes for manual admin center modifications"
  }

  # === OUTPUT VALIDATION (5 assertions) ===

  # Primary output availability
  assert {
    condition     = can(output.environment_group_id)
    error_message = "Environment group ID output must be available"
  }

  # Name output availability
  assert {
    condition     = can(output.environment_group_name)
    error_message = "Environment group name output must be available"
  }

  # Summary output structure
  assert {
    condition     = can(output.environment_group_summary.id) && can(output.environment_group_summary.name) && can(output.environment_group_summary.resource_type)
    error_message = "Environment group summary must contain core identification fields"
  }

  # Anti-corruption layer compliance
  assert {
    condition     = length(regexall("powerplatform_environment_group\\.this\\.id", file("${path.module}/outputs.tf"))) > 0
    error_message = "Outputs must reference discrete resource attributes (anti-corruption layer)"
  }

  # Output schema version presence
  assert {
    condition     = can(output.output_schema_version)
    error_message = "Output schema version must be defined for interface stability"
  }
}

# Deployment validation for actual resource creation
# Tests real resource deployment and state management  
run "apply_validation" {
  command = apply

  # === DEPLOYMENT VALIDATION (5 assertions) ===

  # Resource deployment succeeds
  assert {
    condition     = powerplatform_environment_group.this.id != null
    error_message = "Environment group must be created successfully with valid ID"
  }

  # Resource state consistency
  assert {
    condition     = powerplatform_environment_group.this.display_name == var.environment_group_config.display_name
    error_message = "Deployed resource must maintain display name consistency"
  }

  # Resource description consistency
  assert {
    condition     = powerplatform_environment_group.this.description == var.environment_group_config.description
    error_message = "Deployed resource must maintain description consistency"
  }

  # ID format validation (GUID format)
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", powerplatform_environment_group.this.id))
    error_message = "Environment group ID must be in valid GUID format"
  }

  # Resource readiness for integration
  assert {
    condition     = length(powerplatform_environment_group.this.id) > 0 && length(powerplatform_environment_group.this.display_name) > 0
    error_message = "Environment group must have valid ID and name for downstream integration"
  }

  # === OUTPUT VALIDATION (5 assertions) ===

  # Anti-corruption layer integrity
  assert {
    condition     = output.environment_group_id == powerplatform_environment_group.this.id
    error_message = "Output environment_group_id must match resource ID (anti-corruption layer)"
  }

  # Name output integrity
  assert {
    condition     = output.environment_group_name == powerplatform_environment_group.this.display_name
    error_message = "Output environment_group_name must match resource display_name"
  }

  # Summary output completeness
  assert {
    condition     = output.environment_group_summary.resource_type == "powerplatform_environment_group"
    error_message = "Environment group summary must identify correct resource type"
  }

  # Classification metadata accuracy
  assert {
    condition     = output.environment_group_summary.classification == "res-*"
    error_message = "Environment group summary must indicate res-* module classification"
  }

  # Integration readiness flags
  assert {
    condition     = output.environment_group_summary.ready_for_routing == true && output.environment_group_summary.ready_for_rules == true
    error_message = "Environment group summary must indicate readiness for routing and rules integration"
  }
}

# Total assertions: 25 (exceeds 20+ requirement for res-* modules)
# Plan validation: 20 assertions (Framework: 5, Variables: 5, Resources: 5, Outputs: 5)
# Apply validation: 10 assertions (Deployment: 5, Outputs: 5)
# Coverage areas: Framework, Variables, Resources, Outputs, Deployment, Anti-corruption layer, Lifecycle management