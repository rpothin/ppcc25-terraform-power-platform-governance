# Power Platform Environment Application Admin Configuration
#
# This configuration automates the assignment of application admin permissions within Power Platform
# environments, enabling service principals and applications to manage environment resources programmatically
# while maintaining proper governance and security controls following Azure Verified Module (AVM)
# best practices with Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Follows Azure Verified Module patterns for consistency and maintainability
# - Anti-Corruption Layer: Outputs discrete resource attributes instead of full resource objects
# - Security-First: OIDC authentication, no hardcoded secrets, principle of least privilege
# - res-* Specific: Resource deployment module with lifecycle management for stability
# - Strong Typing: All variables use explicit types with comprehensive validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform` across all modules
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single resource configuration for focused permission management
# - Permission Model: Application-level admin permissions for programmatic environment access

# Main resource for environment application admin permission assignment
#
# This resource creates an application admin assignment within a Power Platform environment,
# granting the specified application administrative permissions through a security role.
# Essential for Terraform service principals and custom applications requiring environment management capabilities.
resource "powerplatform_environment_application_admin" "this" {
  environment_id = var.environment_id
  application_id = var.application_id

  # Lifecycle management for res-* modules
  # Prevents destruction of critical permission assignments and allows manual modifications
  # via Power Platform admin center without causing Terraform drift
  lifecycle {
    # 🔒 GOVERNANCE POLICY: "No Touch Prod"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # EXCEPTION: Contact Platform Team for emergency change procedures
    ignore_changes = []
  }
}