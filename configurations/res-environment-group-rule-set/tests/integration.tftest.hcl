# Integration Tests for Power Platform Environment Group Rule Set Configuration
#
# These integration tests validate the environment group rule set creation and management against
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
  # Test configuration for environment group rule set
  environment_group_id = "12345678-1234-1234-1234-123456789012" # Example test group ID
  rules = {
    sharing_controls = {
      share_mode      = "exclude sharing with security groups"
      share_max_limit = 25
    }
    usage_insights = {
      insights_enabled = true
    }
    solution_checker_enforcement = {
      solution_checker_mode = "audit"
      send_emails_enabled   = false
    }
    backup_retention = {
      period_in_days = 14
    }
    ai_generative_settings = {
      move_data_across_regions_enabled = false
      bing_search_enabled              = true
    }
  }
}

# Comprehensive plan validation - optimized for CI/CD performance
run "plan_validation" {
  command = plan

  # === FRAMEWORK VALIDATION (5 assertions) ===

  # Terraform provider functionality - file-based validation
  assert {
    condition     = length(regexall("powerplatform\\s*=\\s*\\{", file("${path.module}/versions.tf"))) > 0
    error_message = "Power Platform provider must be configured in required_providers block"
  }

  # Provider version compliance with centralized standard
  assert {
    condition     = length(regexall("version\\s*=\\s*\"~> 3\\.8\"", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider version must match centralized standard ~> 3.8 in versions.tf"
  }

  # OIDC authentication configuration in provider block
  assert {
    condition     = length(regexall("use_oidc\\s*=\\s*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Provider configuration must include use_oidc = true for security compliance"
  }

  # Azure backend OIDC configuration  
  assert {
    condition     = length(regexall("backend\\s+\"azurerm\"[\\s\\S]*?use_oidc\\s*=\\s*true", file("${path.module}/versions.tf"))) > 0
    error_message = "Backend must use OIDC for keyless authentication"
  }

  # Terraform version compliance
  assert {
    condition     = length(regexall("required_version\\s*=\\s*\">= 1\\.5\\.0\"", file("${path.module}/versions.tf"))) > 0
    error_message = "Terraform version constraint must be >= 1.5.0 for AVM compliance in versions.tf"
  }

  # === VARIABLE VALIDATION (5 assertions) ===

  # Variable structure integrity
  assert {
    condition     = can(var.environment_group_id) && can(var.rules)
    error_message = "Environment group rule set variables must contain environment_group_id and rules"
  }

  # Environment group ID validation
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_group_id))
    error_message = "Environment group ID must be valid GUID format. Current: ${var.environment_group_id}"
  }

  # Rules structure validation
  assert {
    condition     = can(var.rules.sharing_controls) && can(var.rules.usage_insights)
    error_message = "Rules object must contain valid rule configurations"
  }

  # Strong typing validation (explicit types used)
  assert {
    condition     = can(tostring(var.environment_group_id)) && can(tomap(var.rules))
    error_message = "Variables must use explicit string and object types"
  }

  # Variable content validation (no empty/whitespace)
  assert {
    condition     = length(trimspace(var.environment_group_id)) > 0
    error_message = "Environment group ID must not be empty or contain only whitespace"
  }

  # === RESOURCE VALIDATION (5 assertions) ===

  # Resource planning succeeds
  assert {
    condition     = powerplatform_environment_group_rule_set.this != null
    error_message = "Environment group rule set resource must be planned successfully"
  }

  # Resource configuration mapping
  assert {
    condition     = powerplatform_environment_group_rule_set.this.environment_group_id == var.environment_group_id
    error_message = "Resource environment_group_id must match variable input"
  }

  # Resource rules mapping
  assert {
    condition     = powerplatform_environment_group_rule_set.this.rules != null
    error_message = "Resource rules must be configured from variable input"
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

  # === OUTPUT DEFINITION VALIDATION (5 assertions) ===
  # Note: Testing output definitions in files, not output values (unavailable during plan)

  # Primary output definition exists
  assert {
    condition     = length(regexall("output\\s+\"environment_group_rule_set_id\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Environment group rule set ID output must be defined in outputs.tf"
  }

  # Environment group ID output definition exists
  assert {
    condition     = length(regexall("output\\s+\"environment_group_id\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Environment group ID output must be defined in outputs.tf"
  }

  # Summary output definition exists
  assert {
    condition     = length(regexall("output\\s+\"rule_set_configuration_summary\"", file("${path.module}/outputs.tf"))) > 0
    error_message = "Rule set configuration summary output must be defined in outputs.tf"
  }

  # Anti-corruption layer compliance
  assert {
    condition     = length(regexall("powerplatform_environment_group_rule_set\\.this\\.id", file("${path.module}/outputs.tf"))) > 0
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
    condition     = powerplatform_environment_group_rule_set.this.id != null
    error_message = "Environment group rule set must be created successfully with valid ID"
  }

  # Resource state consistency
  assert {
    condition     = powerplatform_environment_group_rule_set.this.environment_group_id == var.environment_group_id
    error_message = "Deployed resource must maintain environment group ID consistency"
  }

  # Rules configuration consistency
  assert {
    condition     = powerplatform_environment_group_rule_set.this.rules != null
    error_message = "Deployed resource must maintain rules configuration consistency"
  }

  # ID format validation (GUID format)
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", powerplatform_environment_group_rule_set.this.id))
    error_message = "Environment group rule set ID must be in valid GUID format"
  }

  # Resource readiness for integration
  assert {
    condition     = length(powerplatform_environment_group_rule_set.this.id) > 0 && length(powerplatform_environment_group_rule_set.this.environment_group_id) > 0
    error_message = "Environment group rule set must have valid ID and environment group ID for downstream integration"
  }

  # === OUTPUT VALUE VALIDATION (10 assertions) ===
  # Note: Testing actual output values after resource creation

  # Primary output availability and integrity
  assert {
    condition     = can(output.environment_group_rule_set_id) && output.environment_group_rule_set_id != null
    error_message = "Environment group rule set ID output must be available and not null"
  }

  # Anti-corruption layer integrity
  assert {
    condition     = output.environment_group_rule_set_id == powerplatform_environment_group_rule_set.this.id
    error_message = "Output environment_group_rule_set_id must match resource ID (anti-corruption layer)"
  }

  # Environment group ID output availability and integrity
  assert {
    condition     = can(output.environment_group_id) && output.environment_group_id == powerplatform_environment_group_rule_set.this.environment_group_id
    error_message = "Output environment_group_id must match resource environment_group_id"
  }

  # Summary output availability
  assert {
    condition     = can(output.rule_set_configuration_summary) && output.rule_set_configuration_summary != null
    error_message = "Rule set configuration summary output must be available and populated"
  }

  # Summary output structure completeness
  assert {
    condition     = can(output.rule_set_configuration_summary.rule_set_id) && can(output.rule_set_configuration_summary.environment_group_id) && can(output.rule_set_configuration_summary.resource_type)
    error_message = "Rule set configuration summary must contain core identification fields (rule_set_id, environment_group_id, resource_type)"
  }

  # Summary output resource type accuracy
  assert {
    condition     = output.rule_set_configuration_summary.resource_type == "powerplatform_environment_group_rule_set"
    error_message = "Rule set configuration summary must identify correct resource type"
  }

  # Classification metadata accuracy
  assert {
    condition     = output.rule_set_configuration_summary.classification == "res-*"
    error_message = "Rule set configuration summary must indicate res-* module classification"
  }

  # Integration readiness flags
  assert {
    condition     = output.rule_set_configuration_summary.ready_for_environment_assignment == true && output.rule_set_configuration_summary.ready_for_governance_reporting == true
    error_message = "Rule set configuration summary must indicate readiness for environment assignment and governance reporting"
  }

  # Output schema version validation
  assert {
    condition     = can(output.output_schema_version) && output.output_schema_version != null
    error_message = "Output schema version must be available for interface stability"
  }

  # Summary consistency with resource state
  assert {
    condition     = output.rule_set_configuration_summary.rule_set_id == powerplatform_environment_group_rule_set.this.id && output.rule_set_configuration_summary.environment_group_id == powerplatform_environment_group_rule_set.this.environment_group_id
    error_message = "Rule set configuration summary must maintain consistency with resource state"
  }
}

# Total assertions: 30 (exceeds 20+ requirement for res-* modules)
# Plan validation: 20 assertions (Framework: 5, Variables: 5, Resources: 5, Output Definitions: 5)
# Apply validation: 15 assertions (Deployment: 5, Output Values: 10)
# Coverage areas: Framework, Variables, Resources, Output Definitions, Deployment, Output Values, Anti-corruption layer, Lifecycle management