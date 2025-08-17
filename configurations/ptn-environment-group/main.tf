# Power Platform Environment Group Pattern Configuration
#
# This pattern creates a complete environment group setup with multiple environments
# for demonstrating Power Platform governance through Infrastructure as Code.
# 
# Pattern Components:
# - Environment Group: Central container for organizing environments (via res-environment-group)
# - Multiple Environments: Demonstration of environment lifecycle management (via res-environment)
# - Governance Integration: Environments are automatically assigned to the group
#
# Key Features:
# - AVM Module Orchestration: Uses res-* modules instead of direct resource creation
# - Dependency Management: Ensures environment group exists before environment assignment
# - AVM-Compliant Structure: Following true AVM patterns with proper module composition
# - Anti-Corruption Layer: Leverages res-* module outputs for interface stability
# - Security-First: OIDC authentication, no hardcoded secrets, controlled access patterns
# - Pattern Module: Orchestrates multiple resource modules for governance demonstrations
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` consistency
#
# Architecture Decisions:
# - Module Orchestration: Uses res-environment-group and res-environment modules
# - Dependency Chain: Environment group module → Environment modules (proper module dependencies)
# - Variable Transformation: Maps pattern variables to res-* module interfaces
# - Governance Integration: Designed to work with environment routing and DLP policies

# ============================================================================
# ENVIRONMENT GROUP MODULE ORCHESTRATION
# ============================================================================

# Create the environment group using the res-environment-group module
# This provides the central governance container for environment organization
module "environment_group" {
  source = "../res-environment-group"

  # Direct mapping from pattern variables to module interface
  display_name = var.environment_group_config.display_name
  description  = var.environment_group_config.description
}

# ============================================================================
# ENVIRONMENT MODULE ORCHESTRATION
# ============================================================================

# Local computations for variable transformation
locals {
  # Language code mapping from string to LCID
  language_code_mapping = {
    "en" = 1033 # English (United States)
    "fr" = 1036 # French (France)
    "de" = 1031 # German (Germany)
    "es" = 1034 # Spanish (Spain)
    "it" = 1040 # Italian (Italy)
    "pt" = 1046 # Portuguese (Brazil)
    "ja" = 1041 # Japanese (Japan)
    "ko" = 1042 # Korean (Korea)
    "zh" = 2052 # Chinese (China)
  }

  # Transform pattern variables to res-environment module interface
  transformed_environments = {
    for idx, env in var.environments : idx => {
      # Environment configuration object
      environment = {
        display_name         = env.display_name
        location             = env.location
        environment_type     = env.environment_type
        environment_group_id = module.environment_group.environment_group_id
        description          = "Environment created by ptn-environment-group pattern"
      }

      # Dataverse configuration object
      dataverse = {
        language_code     = lookup(local.language_code_mapping, env.dataverse_language, 1033)
        currency_code     = env.dataverse_currency
        security_group_id = var.security_group_id
        domain            = env.domain
      }
    }
  }
}

# Create environments using the res-environment module
module "environments" {
  source   = "../res-environment"
  for_each = local.transformed_environments

  # Pass transformed variables to res-environment module
  environment                 = each.value.environment
  dataverse                   = each.value.dataverse
  enable_duplicate_protection = var.enable_duplicate_protection

  # Explicit dependency on environment group module
  depends_on = [module.environment_group]
}

# ============================================================================
# LOCAL COMPUTATIONS FOR PATTERN SUMMARY
# ============================================================================

locals {
  # Pattern metadata for tracking and validation
  pattern_metadata = {
    pattern_type         = "ptn-environment-group"
    resource_count       = 1 + length(var.environments) # Group + environments
    environment_group_id = module.environment_group.environment_group_id
    created_environments = length(var.environments)
  }

  # Environment summary for governance reporting
  environment_summary = {
    for idx, env in var.environments : idx => {
      display_name     = env.display_name
      environment_type = env.environment_type
      location         = env.location
      environment_id   = module.environments[idx].environment_id
      group_assignment = "automatic" # Assigned via pattern orchestration
    }
  }

  # Deployment validation
  deployment_validation = {
    all_environments_created = length(module.environments) == length(var.environments)
    group_assignment_valid   = module.environment_group.environment_group_id != null
    pattern_complete         = local.pattern_metadata.resource_count > 1
  }
}