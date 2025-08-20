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
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management  
# - Resource Organization: Single resource focused on environment group management
# - Governance Integration: Designed to work with environment routing and rule sets

# Primary environment group resource with lifecycle protection
# Environment groups organize environments into logical units for governance and management
resource "powerplatform_environment_group" "this" {
  display_name = var.display_name
  description  = var.description

  # Lifecycle management for resource modules
  # Allows manual admin center changes without Terraform drift detection
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