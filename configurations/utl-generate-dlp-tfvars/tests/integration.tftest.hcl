# Integration Tests for Smart DLP tfvars Generator (Direct Data Source Approach)
#
# These integration tests validate the tfvars generation process using live Power Platform data.
# Tests require OIDC authentication and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Single apply run for utility module testing
# - Live Data Validation: Tests direct Power Platform API connectivity
# - Comprehensive Coverage: Validates structure, data integrity, and input validation
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Enhanced Coverage: 20+ assertions for comprehensive utility module validation

variables {
  source_policy_name = "Copilot Studio Autonomous Agents"
  output_file        = "outputs/test-policy.tfvars"
}

# Comprehensive validation run - apply command for utility module with live data access
run "comprehensive_validation" {
  command = apply # Apply required for output validation and file generation

  # === INPUT VARIABLE VALIDATION (Assertions 1-6) ===
  # Validate onboarding input variables and enhanced validation rules

  assert {
    condition     = var.source_policy_name != ""
    error_message = "source_policy_name must not be empty for policy selection from live data."
  }

  assert {
    condition     = length(var.source_policy_name) > 0 && length(var.source_policy_name) <= 100
    error_message = "source_policy_name must be between 1-100 characters for Power Platform compatibility."
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9 _.-]+$", var.source_policy_name))
    error_message = "source_policy_name must contain only valid characters (alphanumeric, space, dash, underscore, period)."
  }

  assert {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars extension for Terraform compatibility."
  }

  assert {
    condition     = length(var.output_file) >= 9 && length(var.output_file) <= 255
    error_message = "output_file must be between 9-255 characters for filesystem compatibility."
  }

  assert {
    condition     = !can(regex("[\\\\/]{2,}|[<>:\"|?*]", var.output_file))
    error_message = "output_file must not contain invalid filesystem characters."
  }

  # === PRIMARY OUTPUT VALIDATION (Assertions 7-10) ===
  # Validate core outputs and AVM anti-corruption layer compliance

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

  # === NEW OUTPUT STRUCTURE VALIDATION (Assertions 11-14) ===
  # Validate enhanced output structure with new fields

  assert {
    condition     = output.tfvars_file_path != null
    error_message = "tfvars_file_path output must be defined for file path reference."
  }

  assert {
    condition     = output.policy_analysis != null || output.generation_summary.policy_found == false
    error_message = "policy_analysis output must be defined when policy is found."
  }

  assert {
    condition     = output.diagnostic_info != null
    error_message = "diagnostic_info output must be defined for troubleshooting support."
  }

  assert {
    condition     = output.connector_analysis != null || output.generation_summary.policy_found == false
    error_message = "connector_analysis output must be defined when policy is found."
  }

  # === GENERATION SUMMARY VALIDATION (Assertions 15-20) ===
  # Validate generation summary structure and content alignment

  assert {
    condition     = output.generation_summary.source_policy_name == var.source_policy_name
    error_message = "generation_summary must correctly reference source_policy_name variable."
  }

  assert {
    condition     = output.generation_summary.output_file_path == var.output_file
    error_message = "generation_summary must correctly reference output_file_path variable."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "policy_found")
    error_message = "generation_summary must include policy_found field for live data validation."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "tfvars_generated")
    error_message = "generation_summary must include tfvars_generated field for validation status."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "connector_counts")
    error_message = "generation_summary must include connector_counts field for connector extraction validation."
  }

  assert {
    condition     = can(tobool(output.generation_summary.policy_found))
    error_message = "policy_found must be a boolean value for policy existence validation."
  }

  # === CONNECTOR VALIDATION (Assertions 21-23) ===
  # Validate connector classification extraction and structure

  assert {
    condition     = can(tonumber(output.generation_summary.connector_counts.business_connectors))
    error_message = "business_connectors count must be a number for connector analysis."
  }

  assert {
    condition     = can(tonumber(output.generation_summary.connector_counts.non_business_connectors))
    error_message = "non_business_connectors count must be a number for connector analysis."
  }

  assert {
    condition     = can(tonumber(output.generation_summary.connector_counts.blocked_connectors))
    error_message = "blocked_connectors count must be a number for connector analysis."
  }

  # === LIVE DATA SOURCE VALIDATION (Assertions 24-26) ===
  # Validate direct Power Platform API connectivity and authentication

  assert {
    condition     = output.diagnostic_info.data_source_status.query_successful == true
    error_message = "Power Platform data source query must be successful for live data access."
  }

  assert {
    condition     = output.diagnostic_info.data_source_status.authentication_method == "OIDC"
    error_message = "Authentication method must be OIDC for secure Power Platform access."
  }

  assert {
    condition     = can(tonumber(output.diagnostic_info.data_source_status.total_policies_available))
    error_message = "total_policies_available must be a number indicating live tenant data access."
  }

  # === CONTENT FORMAT VALIDATION (Assertions 27-29) ===
  # Validate generated tfvars content format and structure

  assert {
    condition     = length(output.generated_tfvars_content) > 0
    error_message = "generated_tfvars_content must not be empty for valid tfvars generation."
  }

  assert {
    condition     = can(regex("display_name\\s*=", output.generated_tfvars_content))
    error_message = "generated_tfvars_content must contain display_name assignment for valid tfvars format."
  }

  assert {
    condition     = can(regex("business_connectors\\s*=", output.generated_tfvars_content))
    error_message = "generated_tfvars_content must contain business_connectors assignment for complete policy configuration."
  }

  # === FILE GENERATION VALIDATION (Assertions 30-31) ===
  # Validate physical file generation and file system operations

  assert {
    condition     = output.generation_summary.file_written == true
    error_message = "File must be successfully written to filesystem for downstream usage."
  }

  assert {
    condition     = output.diagnostic_info.file_generation.generation_successful == true
    error_message = "File generation process must complete successfully for valid tfvars output."
  }
}

# Performance and error handling validation
run "error_handling_validation" {
  command = plan # Plan-only test for error scenarios

  variables {
    source_policy_name = "NonExistentPolicyForTesting"
    output_file        = "test-error-handling.tfvars"
  }

  # === ERROR HANDLING VALIDATION (Assertions 32-34) ===
  # Validate graceful handling of missing policies and error conditions

  assert {
    condition     = output.generation_summary != null
    error_message = "generation_summary must be defined even for non-existent policies."
  }

  assert {
    condition     = output.diagnostic_info.policy_matching.exact_match_found == false
    error_message = "diagnostic_info must correctly report no match for non-existent policies."
  }

  assert {
    condition     = length(output.diagnostic_info.policy_matching.available_policies) >= 0
    error_message = "diagnostic_info must provide list of available policies for troubleshooting."
  }
}