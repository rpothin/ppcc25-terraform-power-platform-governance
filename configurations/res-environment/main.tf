# Power Platform Environment Configuration
#
# This configuration creates and manages Power Platform environments following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Uses strong typing, validation, and lifecycle management
# - Anti-Corruption Layer: Outputs discrete environment attributes instead of full resource objects
# - Security-First: OIDC authentication, no hardcoded secrets, secure defaults
# - Resource-Specific: Deploys and manages Power Platform environment resources with governance
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform`
# - Lifecycle Management: Resource modules include `prevent_destroy` and `ignore_changes` (see below)
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single environment per configuration for clear governance boundaries
# - Duplicate Detection: Optional protection to support onboarding existing environments

# Query existing environments for duplicate detection (only when enabled)
data "powerplatform_environments" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Consolidated locals block for duplicate detection logic
locals {
  # Simplified state-aware resource management detection
  # Check if this environment is already managed by Terraform
  is_managed_resource = var.enable_duplicate_protection ? (
    # Check if we can find the resource in Terraform state
    can(powerplatform_environment.this.id) &&
    powerplatform_environment.this.id != null
  ) : false

  # Only check for duplicates if resource is not already managed
  should_check_duplicates = var.enable_duplicate_protection && !local.is_managed_resource

  # Duplicate detection logic (only runs when checking is needed and enabled)
  existing_environment_matches = local.should_check_duplicates ? [
    for env in try(data.powerplatform_environments.all[0].environments, []) : env
    if env.display_name == var.environment_config.display_name
  ] : []

  # Enhanced duplicate detection with state-awareness
  has_duplicate            = local.should_check_duplicates && length(local.existing_environment_matches) > 0
  duplicate_environment_id = local.has_duplicate ? local.existing_environment_matches[0].id : null
}

# Enhanced state-aware guardrail: Only fail plan for unmanaged duplicates
resource "null_resource" "environment_duplicate_guardrail" {
  count = var.enable_duplicate_protection ? 1 : 0

  lifecycle {
    precondition {
      condition     = !local.has_duplicate
      error_message = <<-EOT
      🚨 DUPLICATE ENVIRONMENT DETECTED!
      Environment Name: "${var.environment_config.display_name}"
      Existing Environment ID: ${coalesce(local.duplicate_environment_id, "unknown")}
      
      📊 DETECTION DETAILS:
      • State Management Status: ${local.is_managed_resource ? "MANAGED" : "UNMANAGED"}
      • Duplicate Check Active: ${local.should_check_duplicates ? "YES" : "NO"}
      • Matching Environments Found: ${length(local.existing_environment_matches)}
      
      💡 RESOLUTION OPTIONS:
      1. Import existing environment to manage with Terraform:
         terraform import powerplatform_environment.this ${coalesce(local.duplicate_environment_id, "ENVIRONMENT_ID_HERE")}
      
      2. Use a different display_name for a new environment.
      
      3. Temporarily disable duplicate protection during import:
         Set enable_duplicate_protection = false in your .tfvars file.
         After successful import, re-enable protection.
      
      📚 After import, you can re-enable duplicate protection for future deployments.
      📖 See onboarding guide in docs/guides/ for detailed steps.
      
      🔍 TROUBLESHOOTING:
      If this environment is already imported but still showing as duplicate:
      - Verify the resource exists in state: terraform state list
      - Check state file integrity: terraform state show powerplatform_environment.this
      - Consider refreshing state: terraform refresh
      EOT
    }
  }

  # Enhanced triggers for re-evaluation
  triggers = {
    display_name         = var.environment_config.display_name
    duplicate_protection = var.enable_duplicate_protection
    managed_resource     = local.is_managed_resource
  }
}

# Validation: Ensure environment name follows organizational standards
check "environment_name_validation" {
  assert {
    condition = (
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\s\\-_]*[a-zA-Z0-9]$", var.environment_config.display_name)) &&
      length(var.environment_config.display_name) >= 3 &&
      length(var.environment_config.display_name) <= 64
    )
    error_message = <<-EOT
      Environment display name validation failed: "${var.environment_config.display_name}"
      
      Requirements:
      - Must be 3-64 characters long
      - Must start and end with alphanumeric characters
      - Can contain letters, numbers, spaces, hyphens, and underscores
      - Cannot start or end with spaces or special characters
      
      Examples of valid names:
      - "Development Environment"
      - "Prod-Finance-01" 
      - "Test_Marketing_Sandbox"
    EOT
  }
}

# Enhanced state-awareness validation
check "state_awareness_validation" {
  assert {
    condition = var.enable_duplicate_protection ? (
      # If duplicate protection is enabled, validate our state detection logic
      local.is_managed_resource == try(powerplatform_environment.this.id != null, false)
    ) : true
    error_message = <<-EOT
      ⚠️ STATE AWARENESS VALIDATION FAILED
      
      The state-aware duplicate detection logic may not be working correctly.
      This could indicate a Terraform state synchronization issue.
      
      🔍 DIAGNOSTIC INFORMATION:
      • Managed Resource Detection: ${local.is_managed_resource}
      • Resource ID Available: ${try(powerplatform_environment.this.id != null, false)}
      • Duplicate Protection: ${var.enable_duplicate_protection}
      
      📝 RECOMMENDED ACTIONS:
      1. Run 'terraform refresh' to synchronize state
      2. Verify resource exists: 'terraform state list'
      3. Check resource details: 'terraform state show powerplatform_environment.this'
      
      If issues persist, temporarily disable duplicate protection with:
      enable_duplicate_protection = false
    EOT
  }
}

# Main Power Platform Environment Resource
resource "powerplatform_environment" "this" {
  depends_on = [null_resource.environment_duplicate_guardrail]

  # Core environment configuration
  display_name     = var.environment_config.display_name
  location         = var.environment_config.location
  environment_type = var.environment_config.environment_type

  # Dataverse configuration (optional - only when enabled)
  dynamic "dataverse" {
    for_each = var.dataverse_config != null ? [var.dataverse_config] : []
    content {
      language_code     = dataverse.value.language_code
      currency_code     = dataverse.value.currency_code
      security_group_id = dataverse.value.security_group_id
      domain            = dataverse.value.domain
      organization_name = dataverse.value.organization_name
    }
  }

  # Enhanced lifecycle management for critical environment resources
  lifecycle {
    prevent_destroy = true # Protect against accidental deletion
    ignore_changes = [
      # Allow manual changes in Power Platform admin center without drift
      # Common admin center changes that should not cause Terraform drift
      description, # Admins often update descriptions
      # Add other attributes here if manual changes should be ignored
    ]
  }
}