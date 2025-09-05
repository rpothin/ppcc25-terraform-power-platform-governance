# ==============================================================================
# POWER PLATFORM ENVIRONMENT AND MANAGED ENVIRONMENT SEQUENTIAL TEST
# ==============================================================================
# This utility configuration tests the sequential deployment of Power Platform
# environments followed by managed environment enablement to isolate the root
# cause of "Request url must be an absolute url" errors.
#
# WHY: Validates whether environment → managed environment sequencing works
# with provider v3.8+ by creating a minimal, isolated test case that eliminates
# complex orchestration variables.
# ==============================================================================

locals {
  # WHY: Centralize naming logic for consistent resource identification
  resource_prefix = "test-${substr(replace(var.test_name, "_", "-"), 0, 20)}"

  # WHY: Create timestamps for debugging sequential deployment timing
  deployment_metadata = {
    initiated_at  = timestamp()
    test_purpose  = "validate-sequential-deployment"
    configuration = "utl-test-environment-managed-sequence"
  }
}

# ==============================================================================
# PHASE 1: POWER PLATFORM ENVIRONMENT CREATION (DIRECT RESOURCE)
# ==============================================================================
# WHY: Use direct resource creation for test utility to avoid complex dependencies
# and focus on testing the sequential deployment pattern itself
resource "powerplatform_environment" "test" {
  display_name     = "${local.resource_prefix}-env"
  location         = var.location
  environment_type = "Sandbox"
  description      = "Test environment for sequential managed environment validation - ${local.deployment_metadata.initiated_at}"

  # WHY: Create Dataverse instance for managed environment compatibility
  dataverse = {
    language_code     = 1033
    currency_code     = "USD"
    security_group_id = var.security_group_id
  }
}

# ==============================================================================
# PHASE 2: MANAGED ENVIRONMENT ENABLEMENT
# ==============================================================================
# WHY: Use proven res-managed-environment module with explicit dependency chain
# to test if sequential deployment resolves the URL error
module "test_managed_environment" {
  source = "../res-managed-environment"

  # WHY: Pass validated environment_id to managed environment module
  environment_id = powerplatform_environment.test.id

  sharing_settings = {
    # WHY: Use permissive settings for testing to avoid additional restrictions
    is_group_sharing_disabled = false
    limit_sharing_mode        = "NoLimit"
    max_limit_user_sharing    = -1
  }

  # WHY: Disable usage insights to simplify test configuration
  usage_insights_disabled = true

  solution_checker = {
    # WHY: Use warn mode to allow test deployment without blocking
    mode                       = "Warn"
    suppress_validation_emails = true
    # WHY: Omit rule_overrides to let module's optional default handle provider inconsistency
    # res-managed-environment uses optional(set(string), []) which handles null gracefully
  }

  maker_onboarding = {
    # WHY: Provide clear identification of test purpose in UI
    markdown_content = "Test managed environment for sequential deployment validation - Created: ${local.deployment_metadata.initiated_at}"
    learn_more_url   = "https://learn.microsoft.com/power-platform/"
  }

  # WHY: Explicit dependency ensures managed environment waits for environment creation
  depends_on = [powerplatform_environment.test]
}

# ==============================================================================
# PHASE 3: COMPREHENSIVE LOGGING (CONDITIONAL)
# ==============================================================================
# WHY: Provide detailed logging when debugging is enabled to track state
resource "null_resource" "comprehensive_logging" {
  count = var.enable_comprehensive_logging ? 1 : 0

  triggers = {
    deployment_complete = timestamp()
    environment_id      = powerplatform_environment.test.id
    managed_env_ready   = module.test_managed_environment.managed_environment_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Sequential Deployment Test Completed ==="
      echo "Test Name: ${var.test_name}"
      echo "Environment ID: ${powerplatform_environment.test.id}"
      echo "Managed Environment ID: ${module.test_managed_environment.managed_environment_id}"
      echo "Deployment Time: ${local.deployment_metadata.initiated_at}"

      echo "============================================="
    EOT
  }

  depends_on = [
    powerplatform_environment.test,
    module.test_managed_environment
  ]
}