# Power Platform Environment Group Rule Set Configuration
#
# This configuration creates and manages Power Platform Environment Group Rule Sets
# for applying consistent governance policies across environments within a group
# following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Following AVM patterns with Power Platform provider adaptations
# - Anti-Corruption Layer: Discrete outputs prevent exposure of sensitive resource details
# - Security-First: OIDC authentication, no hardcoded secrets, controlled access patterns
# - Resource Module: Deploys primary Power Platform environment group rule set resource
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` consistency
# - Lifecycle Management: Resource modules include `ignore_changes` for operational flexibility
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management  
# - Resource Organization: Single resource focused on environment group rule management
# - Governance Integration: Designed to work with environment groups and environment routing

# Primary environment group rule set resource with lifecycle protection
# Environment group rule sets apply governance policies consistently across all environments in a group
resource "powerplatform_environment_group_rule_set" "this" {
  environment_group_id = var.environment_group_id
  rules                = var.rules

  # Lifecycle management for resource modules
  # Allows manual admin center changes without Terraform drift detection
  lifecycle {
    ignore_changes = [
      # Allow administrators to modify rules through admin center
      # This prevents Terraform from overriding manual rule adjustments
      # Common in enterprise scenarios where rule requirements evolve
      rules
    ]
  }
}