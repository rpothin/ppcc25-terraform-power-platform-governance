# Power Platform Environment Group Pattern Configuration
#
# This pattern creates a complete environment group setup with multiple environments
# for demonstrating Power Platform governance through Infrastructure as Code.
# 
# Pattern Components:
# - Environment Group: Central container for organizing environments  
# - Multiple Environments: Demonstration of environment lifecycle management
# - Governance Integration: Environments are automatically assigned to the group
#
# Key Features:
# - Multi-Resource Orchestration: Coordinates environment group and environment creation
# - Dependency Management: Ensures environment group exists before environment assignment
# - AVM-Inspired Structure: Following AVM patterns with Power Platform provider adaptations
# - Anti-Corruption Layer: Discrete outputs prevent exposure of sensitive resource details
# - Security-First: OIDC authentication, no hardcoded secrets, controlled access patterns
# - Pattern Module: Deploys multiple coordinated Power Platform resources
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` consistency
#
# Architecture Decisions:
# - Direct Resource Creation: Avoids module nesting issues with for_each
# - Dependency Chain: Environment group → Environments (automatic group assignment)
# - Resource Organization: Logical separation between group creation and environment provisioning
# - Governance Integration: Designed to work with environment routing and DLP policies

# ============================================================================
# ENVIRONMENT GROUP CREATION
# ============================================================================

# Create the environment group resource directly
# This provides the central governance container for environment organization
resource "powerplatform_environment_group" "this" {
  display_name = var.environment_group_config.display_name
  description  = var.environment_group_config.description

  # Lifecycle management for resource modules
  # Allows manual admin center changes without Terraform drift detection
  lifecycle {
    ignore_changes = [
      # Allow administrators to modify display_name through admin center
      # This prevents Terraform from overriding manual naming adjustments
      # Common in enterprise scenarios where naming conventions evolve
      display_name,

      # Allow administrators to update descriptions through admin center
      # Supports operational documentation updates without Terraform changes
      # Maintains flexibility for dynamic organizational requirements
      description
    ]
  }
}

# ============================================================================
# ENVIRONMENT CREATION AND GROUP ASSIGNMENT
# ============================================================================

# Query existing environments for duplicate detection
data "powerplatform_environments" "all" {
  count = var.enable_duplicate_protection ? 1 : 0
}

# Local computations for environment creation
locals {
  # Environment duplicate detection
  existing_environment_matches = var.enable_duplicate_protection ? [
    for env in var.environments : [
      for existing in data.powerplatform_environments.all[0].environments : existing
      if lower(trimspace(existing.display_name)) == lower(trimspace(env.display_name))
    ]
  ] : []

  # Validation for duplicate environment names
  has_duplicates = var.enable_duplicate_protection ? length(flatten(local.existing_environment_matches)) > 0 : false

  # Domain calculations for each environment
  environment_domains = {
    for idx, env in var.environments : idx => env.domain != null ? env.domain : (
      substr(
        replace(
          replace(
            lower(env.display_name),
            "/[^a-z0-9]+/", "-" # Replace any non-alphanumeric sequence with single hyphen
          ),
          "/^-+|-+$/", "" # Remove leading and trailing hyphens
        ),
        0,
        63 # Truncate to 63 characters maximum
      )
    )
  }
}

# Validation resource to prevent duplicate environment creation
resource "null_resource" "environment_duplicate_guardrail" {
  count = var.enable_duplicate_protection ? 1 : 0

  # Trigger validation if duplicates are detected
  triggers = {
    duplicate_check = !local.has_duplicates
  }

  # If duplicates exist, this will cause the plan to fail
  lifecycle {
    precondition {
      condition     = !local.has_duplicates
      error_message = "Duplicate environment names detected in tenant. Enable unique naming or disable duplicate protection."
    }
  }
}

# Create multiple environments and automatically assign them to the environment group
resource "powerplatform_environment" "environments" {
  # Create one environment for each configuration
  for_each = { for idx, env in var.environments : idx => env }

  # Basic environment configuration
  display_name     = each.value.display_name
  location         = each.value.location
  environment_type = each.value.environment_type

  # Dataverse configuration is required for environment group assignment
  # Provider constraint: environment_group_id requires dataverse to be specified
  dataverse = {
    language_code        = each.value.dataverse_language
    currency_code        = each.value.dataverse_currency
    domain               = local.environment_domains[each.key]
    environment_group_id = powerplatform_environment_group.this.id
  }

  # Lifecycle management for resource modules
  lifecycle {
    ignore_changes = [
      # Allow manual changes to display_name through admin center
      display_name,
      # Allow manual changes to dataverse domain
      dataverse[0].domain
    ]
  }

  # Ensure environment group exists before creating environments
  depends_on = [
    powerplatform_environment_group.this,
    null_resource.environment_duplicate_guardrail
  ]
}

# ============================================================================
# LOCAL COMPUTATIONS FOR PATTERN SUMMARY
# ============================================================================

locals {
  # Pattern metadata for tracking and validation
  pattern_metadata = {
    pattern_type         = "ptn-environment-group"
    resource_count       = 1 + length(var.environments) # Group + environments
    environment_group_id = powerplatform_environment_group.this.id
    created_environments = length(var.environments)
  }

  # Environment summary for governance reporting
  environment_summary = {
    for idx, env in var.environments : idx => {
      display_name     = env.display_name
      environment_type = env.environment_type
      location         = env.location
      environment_id   = powerplatform_environment.environments[idx].id
      group_assignment = "automatic" # Assigned via pattern orchestration
    }
  }

  # Deployment validation
  deployment_validation = {
    all_environments_created = length(powerplatform_environment.environments) == length(var.environments)
    group_assignment_valid   = powerplatform_environment_group.this.id != null
    pattern_complete         = local.pattern_metadata.resource_count > 1
  }
}