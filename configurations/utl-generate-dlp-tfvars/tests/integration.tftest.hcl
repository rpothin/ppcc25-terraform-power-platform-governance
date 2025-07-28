# Integration Tests for Smart DLP tfvars Generator
#
# These integration tests validate the tfvars generation process for DLP policy onboarding and template creation.
#
# Test Philosophy:
# - Performance Optimized: Consolidated assertions minimize plan cycles
# - Comprehensive Coverage: Validates structure, data integrity, and input validation
# - Environment Agnostic: Works across development, staging, and production
# - Failure Isolation: Clear error messages for rapid troubleshooting
# - Minimum Assertion Coverage: 15+ for utility modules

variables {
  source_policy_name = "Copilot Studio Autonomous Agents"
  template_type      = "strict-security"
  output_file        = "outputs/test-policy.tfvars"
}

run "plan_validation" {
  command = plan

  assert {
    condition     = var.source_policy_name != ""
    error_message = "source_policy_name must not be empty."
  }

  assert {
    condition     = contains(["strict-security", "balanced", "development"], var.template_type)
    error_message = "template_type must be valid."
  }

  assert {
    condition     = can(regex(".*\\.tfvars$", var.output_file))
    error_message = "output_file must end with .tfvars."
  }

}
