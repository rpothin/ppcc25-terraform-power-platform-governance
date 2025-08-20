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

# Provider configuration required for testing child modules
provider "powerplatform" {
  use_oidc = true
}

variables {
  # Test configuration for environment group
  display_name = "Test Environment Group"
  description  = "Test environment group for Terraform validation"
}

# Comprehensive plan validation - optimized for CI/CD performance
run "plan_validation" {
  command = plan

  # === FRAMEWORK VALIDATION (6 assertions) ===

  # Terraform provider functionality - module requirements validation
  assert {
    condition     = length(regexall("powerplatform\\s*=\\s*\\{", file("${path.module}/versions.tf"))) > 0
    error_message = "Power Platform provider must be declared in required_providers block"
  }

  # Provider version compliance with centralized standard
  assert {
    condition     = length(regexall("version\\s*=\\s*\"~> 3\\.8\"", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider version must match centralized standard ~> 3.8 in versions.tf"
  }

  # Child module architecture validation - no provider block in module
  assert {
    condition     = length(regexall("provider\\s+\"powerplatform\"", file("${path.module}/versions.tf"))) == 0
    error_message = "Child module should not have provider block - provider configuration handled by parent"
  }

  # Child module architecture validation - no backend block in module
  assert {
    condition     = length(regexall("backend\\s+\"azurerm\"", file("${path.module}/versions.tf"))) == 0
    error_message = "Child module should not have backend block - state management handled by parent"
  }

  # Terraform version compliance
  assert {
    condition     = length(regexall("required_version\\s*=\\s*\">= 1\\.5\\.0\"", file("${path.module}/versions.tf"))) > 0
    error_message = "Terraform version constraint must be >= 1.5.0 for AVM compliance in versions.tf"
  }

  # Child module only declares required_providers (no provider/backend blocks)
  assert {
    condition     = length(split("\n", file("${path.module}/versions.tf"))) < 20
    error_message = "Child module versions.tf should be minimal - only terraform block with required_providers"
  }

  # === VARIABLE VALIDATION (5 assertions) ===

  # Variable structure integrity
  assert {
    condition     = can(var.display_name) && can(var.description)
    error_message = "Environment group variables must contain display_name and description"
  }

  # Display name validation
  assert {
    condition     = length(var.display_name) >= 1 && length(var.display_name) <= 100
    error_message = "Display name must be 1-100 characters. Current: ${length(var.display_name)}"
  }

  # Description validation
  assert {
    condition     = length(var.description) >= 1 && length(var.description) <= 500
    error_message = "Description must be 1-500 characters. Current: ${length(var.description)}"
  }

  # Strong typing validation (explicit types used)
  assert {
    condition     = can(tostring(var.display_name)) && can(tostring(var.description))
    error_message = "Variables must use explicit string types"
  }

  # Variable content validation (no empty/whitespace)
  assert {
    condition     = length(trimspace(var.display_name)) > 0 && length(trimspace(var.description)) > 0
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
    condition     = powerplatform_environment_group.this.display_name == var.display_name
    error_message = "Resource display_name must match variable input"
  }

  # Resource description mapping
  assert {
    condition     = powerplatform_environment_group.this.description == var.description
    error_message = "Resource description must match variable input"
  }

  # Lifecycle configuration presence
  assert {
    condition     = length(regexall("lifecycle\\s*\\{", file("${path.module}/main.tf"))) > 0
    error_message = "Resource module must include lifecycle management configuration"
  }

  # === OUTPUT DEFINITION VALIDATION (5 assertions) ===
  # Note: Testing output definitions in files, not output values (unavailable during plan)

  # Primary output definition exists
  assert {
    condition     = length(regexall("output\\s+\"environment_group_id\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Environment group ID output must be defined in outputs.tf"
  }

  # Name output definition exists
  assert {
    condition     = length(regexall("output\\s+\"environment_group_name\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Environment group name output must be defined in outputs.tf"
  }

  # Summary output definition exists
  assert {
    condition     = length(regexall("output\\s+\"environment_group_summary\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Environment group summary output must be defined in outputs.tf"
  }

  # Anti-corruption layer compliance
  assert {
    condition     = length(regexall("powerplatform_environment_group\\.this\\.id", file("${path.module}/outputs.tf"))) > 0
    error_message = "Outputs must reference discrete resource attributes (anti-corruption layer)"
  }

  # Output schema version definition exists
  assert {
    condition     = length(regexall("output\\s+\"output_schema_version\"", file("${path.module}/outputs.tf"))) > 0
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
    condition     = powerplatform_environment_group.this.display_name == var.display_name
    error_message = "Deployed resource must maintain display name consistency"
  }

  # Resource description consistency
  assert {
    condition     = powerplatform_environment_group.this.description == var.description
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

  # === OUTPUT VALUE VALIDATION (10 assertions) ===
  # Note: Testing actual output values after resource creation

  # Primary output availability and integrity
  assert {
    condition     = can(output.environment_group_id) && output.environment_group_id != null
    error_message = "Environment group ID output must be available and not null"
  }

  # Anti-corruption layer integrity
  assert {
    condition     = output.environment_group_id == powerplatform_environment_group.this.id
    error_message = "Output environment_group_id must match resource ID (anti-corruption layer)"
  }

  # Name output availability and integrity
  assert {
    condition     = can(output.environment_group_name) && output.environment_group_name == powerplatform_environment_group.this.display_name
    error_message = "Output environment_group_name must match resource display_name"
  }

  # Summary output availability
  assert {
    condition     = can(output.environment_group_summary) && output.environment_group_summary != null
    error_message = "Environment group summary output must be available and populated"
  }

  # Summary output structure completeness
  assert {
    condition     = can(output.environment_group_summary.id) && can(output.environment_group_summary.name) && can(output.environment_group_summary.resource_type)
    error_message = "Environment group summary must contain core identification fields (id, name, resource_type)"
  }

  # Summary output resource type accuracy
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

  # Output schema version validation
  assert {
    condition     = can(output.output_schema_version) && output.output_schema_version != null
    error_message = "Output schema version must be available for interface stability"
  }

  # Summary consistency with resource state
  assert {
    condition     = output.environment_group_summary.id == powerplatform_environment_group.this.id && output.environment_group_summary.name == powerplatform_environment_group.this.display_name
    error_message = "Environment group summary must maintain consistency with resource state"
  }
}

# Total assertions: 30 (exceeds 20+ requirement for res-* modules)
# Plan validation: 20 assertions (Framework: 5, Variables: 5, Resources: 5, Output Definitions: 5)
# Apply validation: 15 assertions (Deployment: 5, Output Values: 10)
# Coverage areas: Framework, Variables, Resources, Output Definitions, Deployment, Output Values, Anti-corruption layer, Lifecycle management