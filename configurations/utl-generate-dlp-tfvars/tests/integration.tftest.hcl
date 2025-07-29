# Integration Tests for Smart DLP tfvars Generator (Onboarding Only)
#
# These integration tests validate the tfvars generation process for DLP policy onboarding.
# Tests require authentication via OIDC and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan cycles
# - Comprehensive Coverage: Validates structure, data integrity, and input validation
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 15+ for utility modules (AVM requirement)
#
# Test Categories:
# - Framework Validation: Basic Terraform and provider functionality
# - Variable Validation: Input parameter structure and constraints
# - Output Validation: AVM compliance and data integrity
# - Onboarding Logic: Policy existence and connector extraction validation

variables {
  source_policy_name = "Copilot Studio Autonomous Agents"
  output_file        = "outputs/test-policy.tfvars"
}

# Comprehensive validation run - optimized for CI/CD performance
run "comprehensive_validation" {
  command = plan

  # === VARIABLE VALIDATION (Assertions 1-4) ===
  # Validate onboarding input variables

  assert {
    condition     = var.source_policy_name != ""
    error_message = "source_policy_name must not be empty for policy selection."
  }

  assert {
    condition     = length(var.source_policy_name) > 0
    error_message = "source_policy_name must have valid length for policy identification."
  }

  assert {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars extension for Terraform compatibility."
  }

  assert {
    condition     = var.output_file != ""
    error_message = "output_file must not be empty for file generation."
  }

  # === OUTPUT VALIDATION (Assertions 5-8) ===
  # Validate AVM anti-corruption layer compliance and output structure

  assert {
    condition     = output.generated_tfvars_content != null
    error_message = "generated_tfvars_content output must be defined for AVM compliance."
  }

  assert {
    condition     = output.generation_summary != null
    error_message = "generation_summary output must be defined for operational visibility."
  }

  assert {
    condition     = can(tostring(output.generated_tfvars_content))
    error_message = "generated_tfvars_content must be a string type for file content."
  }

  assert {
    condition     = can(keys(output.generation_summary))
    error_message = "generation_summary must be a map type for structured data."
  }

  # === MODULE STRUCTURE VALIDATION (Assertions 9-12) ===
  # Validate module follows AVM utility module patterns and requirements

  assert {
    condition     = output.generation_summary.source_policy_name == var.source_policy_name
    error_message = "generation_summary must correctly reference source_policy_name variable."
  }

  assert {
    condition     = output.generation_summary.output_file == var.output_file
    error_message = "generation_summary must correctly reference output_file variable."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9 _-]+$", var.source_policy_name))
    error_message = "source_policy_name must contain only valid policy name characters."
  }

  assert {
    condition     = length(var.source_policy_name) <= 100
    error_message = "source_policy_name must not exceed maximum length for Power Platform compatibility."
  }

  # === ONBOARDING LOGIC VALIDATION (Assertions 13-18) ===
  # Validate onboarding-specific functionality and data extraction

  assert {
    condition     = contains(keys(output.generation_summary), "policy_exists")
    error_message = "generation_summary must include policy_exists field for onboarding validation."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "tfvars_valid")
    error_message = "generation_summary must include tfvars_valid field for validation status."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "business_connectors")
    error_message = "generation_summary must include business_connectors field for connector extraction validation."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "non_business_connectors")
    error_message = "generation_summary must include non_business_connectors field for connector extraction validation."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "blocked_connectors")
    error_message = "generation_summary must include blocked_connectors field for connector extraction validation."
  }

  assert {
    condition     = can(tobool(output.generation_summary.policy_exists))
    error_message = "policy_exists must be a boolean value for policy existence validation."
  }

  # === CONTENT VALIDATION (Assertions 19-20) ===
  # Validate generated content structure and format

  assert {
    condition     = length(output.generated_tfvars_content) > 0
    error_message = "generated_tfvars_content must not be empty for valid tfvars generation."
  }

  assert {
    condition     = can(regex("policy_name\\s*=", output.generated_tfvars_content))
    error_message = "generated_tfvars_content must contain policy_name assignment for valid tfvars format."
  }
}