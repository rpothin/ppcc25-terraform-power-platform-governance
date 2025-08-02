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
# - Lifecycle Management: Resource modules include `prevent_destroy` and `ignore_changes`
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single environment per configuration for clear governance boundaries
# - Duplicate Detection: Simplified protection without dependency cycles

# Query existing environments for duplicate detection (only when enabled)
data "powerplatform_environments" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Simplified duplicate detection logic (no dependency cycles)
locals {
  # Find environments with matching display names
  existing_environment_matches = var.enable_duplicate_protection ? [
    for env in try(data.powerplatform_environments.all[0].environments, []) : env
    if env.display_name == var.environment_config.display_name
  ] : []

  # Simple duplicate detection
  has_duplicate            = var.enable_duplicate_protection && length(local.existing_environment_matches) > 0
  duplicate_environment_id = local.has_duplicate ? local.existing_environment_matches[0].id : null
}

# Duplicate protection guardrail
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
      • Duplicate Protection: ENABLED
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
      If this environment should be imported:
      - Get the environment ID from Power Platform Admin Center
      - Run: terraform import powerplatform_environment.this <ENVIRONMENT_ID>
      - Verify import: terraform state show powerplatform_environment.this
      EOT
    }
  }

  # Triggers for re-evaluation
  triggers = {
    display_name         = var.environment_config.display_name
    duplicate_protection = var.enable_duplicate_protection
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

# Main Power Platform Environment Resource
resource "powerplatform_environment" "this" {
  depends_on = [null_resource.environment_duplicate_guardrail]

  # Core environment configuration
  display_name     = var.environment_config.display_name
  location         = var.environment_config.location
  environment_type = var.environment_config.environment_type

  # Owner ID only for Developer environments (Power Platform provider requirement)
  owner_id = var.environment_config.environment_type == "Developer" ? var.environment_config.owner_id : null

  # Dataverse configuration (required when owner_id is specified for Developer environments)
  dataverse = var.dataverse_config != null ? {
    language_code     = var.dataverse_config.language_code
    currency_code     = var.dataverse_config.currency_code
    security_group_id = var.dataverse_config.security_group_id
    domain            = var.dataverse_config.domain
    organization_name = var.dataverse_config.organization_name
    } : (
    # Power Platform provider requires dataverse when owner_id is specified (Developer environments)
    var.environment_config.environment_type == "Developer" && var.environment_config.owner_id != null ? {
      language_code     = "1033" # English (United States) - default for Developer environments
      currency_code     = "USD"  # US Dollar - default for Developer environments
      security_group_id = null
      domain            = null
      organization_name = null
    } : null
  )

  # Enhanced lifecycle management for critical environment resources
  lifecycle {
    ignore_changes = [
      # Allow manual changes in Power Platform admin center without drift
      # Common admin center changes that should not cause Terraform drift
      description, # Admins often update descriptions
      # Add other attributes here if manual changes should be ignored
    ]
  }
}