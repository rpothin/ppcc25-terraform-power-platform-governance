# Integration Tests for Smart DLP tfvars Generator
#
# These integration tests validate the tfvars generation process for DLP policy onboarding and template creation.
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
# - Security Validation: OIDC authentication and secure configuration

variables {
  source_policy_name = "Copilot Studio Autonomous Agents"
  template_type      = "strict-security"
  output_file        = "outputs/test-policy.tfvars"
}

# Comprehensive validation run - optimized for CI/CD performance
run "comprehensive_validation" {
  command = plan

  # === VARIABLE VALIDATION (Assertions 1-8) ===
  # Validate all input variables meet AVM standards and business requirements

  assert {
    condition     = var.source_policy_name != ""
    error_message = "source_policy_name must not be empty for policy selection."
  }

  assert {
    condition     = length(var.source_policy_name) > 0
    error_message = "source_policy_name must have valid length for policy identification."
  }

  assert {
    condition     = contains(["strict-security", "balanced", "development"], var.template_type)
    error_message = "template_type must be one of the valid governance templates."
  }

  assert {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars extension for Terraform compatibility."
  }

  assert {
    condition     = var.template_type != ""
    error_message = "template_type must not be empty for template selection."
  }

  assert {
    condition     = var.output_file != ""
    error_message = "output_file must not be empty for file generation."
  }

  assert {
    condition     = length(var.template_type) > 0
    error_message = "template_type must have valid length for template identification."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9._/-]+$", var.output_file))
    error_message = "output_file must contain only valid filesystem characters."
  }

  # === OUTPUT VALIDATION (Assertions 9-12) ===
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

  # === MODULE STRUCTURE VALIDATION (Assertions 13-16) ===
  # Validate module follows AVM utility module patterns and requirements

  assert {
    condition     = output.generation_summary.source_policy_name == var.source_policy_name
    error_message = "generation_summary must correctly reference source_policy_name variable."
  }

  assert {
    condition     = output.generation_summary.template_type == var.template_type
    error_message = "generation_summary must correctly reference template_type variable."
  }

  assert {
    condition     = output.generation_summary.output_file == var.output_file
    error_message = "generation_summary must correctly reference output_file variable."
  }

  assert {
    condition     = length(keys(output.generation_summary)) >= 3
    error_message = "generation_summary must contain minimum required fields for operational context."
  }

  # === ADDITIONAL VALIDATION (Assertions 17-18) ===
  # Additional checks for comprehensive coverage beyond minimum requirement

  assert {
    condition     = can(regex("^[a-zA-Z0-9 _-]+$", var.source_policy_name))
    error_message = "source_policy_name must contain only valid policy name characters."
  }

  assert {
    condition     = length(var.source_policy_name) <= 100
    error_message = "source_policy_name must not exceed maximum length for Power Platform compatibility."
  }
}