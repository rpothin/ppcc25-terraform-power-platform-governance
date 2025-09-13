# Power Platform Enterprise Policy Assignment Configuration
#
# 🎯 PURPOSE: Links existing Azure enterprise policies to Power Platform environments
#
# ⚠️ IMPORTANT: This module does NOT create enterprise policies in Azure.
# Enterprise policies must be pre-created in Azure using azapi_resource or other Azure tools.
# This module only creates the assignment/binding between existing Azure policies and PP environments.
#
# WORKFLOW:
# 1. Create enterprise policy in Azure (using azapi_resource) ← NOT handled by this module
# 2. Use this module to assign/link the policy to Power Platform environment ← This module's role
# 3. Power Platform environment inherits policy controls (VNet, encryption, etc.)
#
# Key Features:
# - AVM-Inspired Structure: Following AVM patterns with Power Platform provider adaptations
# - Policy Assignment Only: Links existing Azure policies to Power Platform environments
# - Anti-Corruption Layer: Discrete outputs prevent exposure of sensitive resource details
# - Security-First: OIDC authentication, no hardcoded secrets, controlled access patterns
# - Resource Module: Deploys primary Power Platform enterprise policy assignment resource
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` consistency
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management  
# - Resource Organization: Single policy assignment focused on environment-policy binding
# - Governance Integration: Designed to work with Azure-created VNet integration and encryption policies
# - Policy Types: Supports NetworkInjection and Encryption enterprise policy assignments
#
# Prerequisites:
# - Azure enterprise policy must exist (created via azapi_resource or Azure Portal)
# - system_id must reference valid Azure enterprise policy resource ID
# - Power Platform environment must exist and be accessible
# - Proper RBAC permissions for both Azure policy and Power Platform environment
#
# Usage Examples:
# - VNet Integration: Assign existing Azure NetworkInjection policy to enable subnet delegation
# - Data Encryption: Assign existing Azure Encryption policy with Azure Key Vault integration
# - Policy Management: Centralized governance through Infrastructure as Code

# WHY: Transform policy configuration for different policy types
# This enables flexible policy assignment while maintaining type safety
locals {
  # Policy type validation and defaults
  policy_type = var.policy_type

  # Policy assignment metadata for tracking
  policy_metadata = {
    policy_type    = var.policy_type
    environment_id = var.environment_id
    system_id      = var.system_id
    assigned_at    = timestamp()
  }
}

# Primary Enterprise Policy Assignment Resource
resource "powerplatform_enterprise_policy" "this" {
  environment_id = var.environment_id
  policy_type    = var.policy_type
  system_id      = var.system_id

  # WHY: Governance lifecycle management following "No Touch Prod" principles
  # All policy changes must go through Infrastructure as Code
  lifecycle {
    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []

    # WHY: Prevent accidental policy removal in production environments
    # NOTE: Cannot use variables in prevent_destroy - set manually per environment
    prevent_destroy = false

    # WHY: Ensure smooth policy updates without service interruption
    create_before_destroy = true

    # WHY: Validate policy assignment prerequisites before creation
    precondition {
      condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
      error_message = "Environment ID must be a valid GUID format for Power Platform compatibility."
    }

    precondition {
      condition     = contains(["NetworkInjection", "Encryption"], var.policy_type)
      error_message = "Policy type must be either 'NetworkInjection' or 'Encryption' for enterprise policy assignment."
    }

    precondition {
      condition     = can(regex("^/regions/[a-zA-Z0-9]+/providers/Microsoft\\.PowerPlatform/enterprisePolicies/[0-9a-fA-F-]+$", var.system_id))
      error_message = "System ID must follow format: /regions/<location>/providers/Microsoft.PowerPlatform/enterprisePolicies/<policy-id>"
    }
  }
}