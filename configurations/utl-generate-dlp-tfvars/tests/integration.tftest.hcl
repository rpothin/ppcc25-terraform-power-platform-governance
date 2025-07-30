# Integration Tests for Smart DLP tfvars Generator (Simplified Outputs)
#
# These integration tests validate the tfvars generation process using live Power Platform data.
# Tests require OIDC authentication and are designed for CI/CD environments like GitHub Actions.
#
# Test Philosophy:
# - Performance Optimized: Single apply run for utility module testing
# - Live Data Validation: Tests direct Power Platform API connectivity
# - Simplified Coverage: Focuses on core functionality following "Keep It Simple" principle
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Focused Testing: 20+ assertions covering essential functionality only

variables {
  source_policy_name = "Copilot Studio Autonomous Agents"
  output_file        = "outputs/test-policy.tfvars"
}

# Comprehensive validation run - apply command for utility module with live data access
run "comprehensive_validation" {
  command = apply # Apply required for output validation and file generation

  # === INPUT VARIABLE VALIDATION (Assertions 1-6) ===
  # Validate input variables and enhanced validation rules

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
  # Validate core outputs exist and are properly typed

  assert {
    condition     = output.generated_tfvars_content != null
    error_message = "generated_tfvars_content output must be defined for AVM compliance."
  }

  assert {
    condition     = output.tfvars_file_path != null
    error_message = "tfvars_file_path output must be defined for file path reference."
  }

  assert {
    condition     = output.generation_summary != null
    error_message = "generation_summary output must be defined for operational visibility."
  }

  assert {
    condition     = can(tostring(output.generated_tfvars_content))
    error_message = "generated_tfvars_content must be a string type for file content."
  }

  # === OUTPUT TYPE VALIDATION (Assertions 11-13) ===
  # Validate output data types match expected structure

  assert {
    condition     = can(keys(output.generation_summary))
    error_message = "generation_summary must be a map type for structured data."
  }

  assert {
    condition     = can(tostring(output.tfvars_file_path)) || output.tfvars_file_path == null
    error_message = "tfvars_file_path must be a string or null type for file path."
  }

  assert {
    condition     = can(tobool(output.generation_summary.policy_found))
    error_message = "policy_found must be a boolean value for policy existence validation."
  }

  # === GENERATION SUMMARY VALIDATION (Assertions 14-19) ===
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
    condition     = can(tobool(output.generation_summary.tfvars_generated))
    error_message = "tfvars_generated must be a boolean value for generation status validation."
  }

  # === CONNECTOR VALIDATION (Assertions 20-24) ===
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

  assert {
    condition     = can(tonumber(output.generation_summary.connector_counts.total_connectors))
    error_message = "total_connectors count must be a number for total connector validation."
  }

  assert {
    condition     = output.generation_summary.connector_counts.total_connectors >= 0
    error_message = "total_connectors count must be non-negative for valid connector data."
  }

  # === CONTENT FORMAT VALIDATION (Assertions 25-28) ===
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
    condition     = can(regex("business_connectors\\s*=", output.generated_tfvars_content)) || output.generation_summary.connector_counts.business_connectors == 0
    error_message = "generated_tfvars_content must contain business_connectors assignment when business connectors exist."
  }

  assert {
    condition     = can(regex("non_business_connectors\\s*=", output.generated_tfvars_content)) || output.generation_summary.connector_counts.non_business_connectors == 0
    error_message = "generated_tfvars_content must contain non_business_connectors assignment when non-business connectors exist."
  }

  # === FILE GENERATION VALIDATION (Assertions 29-30) ===
  # Validate physical file generation and file system operations

  assert {
    condition     = output.generation_summary.file_written == true
    error_message = "File must be successfully written to filesystem for downstream usage."
  }

  assert {
    condition     = output.tfvars_file_path != null || output.generation_summary.file_written == false
    error_message = "tfvars_file_path must be provided when file is successfully written."
  }

  # === POLICY DISCOVERY VALIDATION (Assertions 31-32) ===
  # Validate policy matching and discovery logic

  assert {
    condition     = output.generation_summary.policy_found == true || output.generation_summary.policy_found == false
    error_message = "policy_found must be a valid boolean indicating policy discovery status."
  }

  assert {
    condition     = output.generation_summary.policy_found == false || (output.generation_summary.policy_found == true && output.generation_summary.connector_counts.total_connectors >= 0)
    error_message = "When policy is found, connector counts must be non-negative numbers."
  }
}

# Error handling validation for non-existent policies
run "error_handling_validation" {
  command = apply # Changed from plan to apply for complete error handling validation

  variables {
    source_policy_name = "NonExistentPolicyForTesting12345"
    output_file        = "test-error-handling.tfvars"
  }

  # === ERROR HANDLING VALIDATION (Assertions 33-36) ===
  # Validate graceful handling of missing policies and error conditions

  assert {
    condition     = output.generation_summary != null
    error_message = "generation_summary must be defined even for non-existent policies."
  }

  assert {
    condition     = output.generated_tfvars_content != null
    error_message = "generated_tfvars_content must be defined even for non-existent policies (may be empty)."
  }

  assert {
    condition     = contains(keys(output.generation_summary), "policy_found")
    error_message = "generation_summary must include policy_found field for error scenarios."
  }

  assert {
    condition     = can(tobool(output.generation_summary.policy_found))
    error_message = "policy_found must be a boolean even for non-existent policies."
  }
}

# Input validation edge cases
run "input_validation_edge_cases" {
  command = plan # Plan-only test for input validation

  variables {
    source_policy_name = "Test Policy"
    output_file        = "minimal.tfvars"
  }

  # === INPUT EDGE CASE VALIDATION (Assertions 37-40) ===
  # Validate edge cases and boundary conditions

  assert {
    condition     = var.source_policy_name == "Test Policy"
    error_message = "Variable assignment must work correctly for simple policy names."
  }

  assert {
    condition     = var.output_file == "minimal.tfvars"
    error_message = "Variable assignment must work correctly for minimal file paths."
  }

  assert {
    condition     = output.generation_summary.source_policy_name == var.source_policy_name
    error_message = "generation_summary must correctly echo input variables in edge cases."
  }

  assert {
    condition     = output.generation_summary.output_file_path == var.output_file
    error_message = "generation_summary must correctly echo output file path in edge cases."
  }
}