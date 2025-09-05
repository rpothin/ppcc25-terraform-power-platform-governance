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
# WHY: Use proven res-managed-environment module with minimal configuration
# Let module defaults handle all non-essential settings to avoid provider bugs
module "test_managed_environment" {
  source = "../res-managed-environment"

  # WHY: Only pass required environment_id, let module defaults handle everything else
  # This avoids provider consistency bugs and uses battle-tested configurations
  environment_id = powerplatform_environment.test.id

  # WHY: Explicit dependency ensures managed environment waits for environment creation
  depends_on = [powerplatform_environment.test]
}