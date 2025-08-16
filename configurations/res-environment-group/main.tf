# Power Platform Environment Group Configuration
#
# This configuration creates and manages Power Platform Environment Groups for organizing
# environments with consistent governance policies following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Following AVM patterns with Power Platform provider adaptations
# - Anti-Corruption Layer: Discrete outputs prevent exposure of sensitive resource details
# - Security-First: OIDC authentication, no hardcoded secrets, controlled access patterns
# - Resource Module: Deploys primary Power Platform environment group resource
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` consistency
# - Lifecycle Management: Resource modules include `ignore_changes` for operational flexibility
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management  
# - Resource Organization: Single resource focused on environment group management
# - Governance Integration: Designed to work with environment routing and rule sets

# Primary environment group resource with lifecycle protection
# Environment groups organize environments into logical units for governance and management
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