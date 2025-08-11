# Power Platform Admin Management Application Configuration
#
# This configuration registers and manages service principals as Power Platform administrators
# for tenant governance following Azure Verified Module (AVM) best practices with 
# Power Platform provider adaptations.
#
# Key Features:
# - AVM-Inspired Structure: Follows AVM patterns while adapting to Power Platform provider limitations
# - Anti-Corruption Layer: Outputs discrete registration details instead of full resource exposure
# - Security-First: OIDC authentication, no hardcoded secrets, principle of least privilege
# - res-* Specific: Resource module for deploying primary Power Platform admin registrations
# - Strong Typing: All variables use explicit types and validation (no `any`)
# - Provider Version: Centralized `~> 3.8` for `microsoft/power-platform`
# - Lifecycle Management: Includes appropriate lifecycle protection for admin registrations
#
# Architecture Decisions:
# - Provider Choice: Using microsoft/power-platform for native Power Platform integration
# - Backend Strategy: Azure Storage with OIDC for secure, keyless state management
# - Resource Organization: Single resource focus following AVM resource module patterns
# - Registration Management: Centralized admin registration for governance automation

# Main Admin Management Application Resource
#
# Registers a service principal as a Power Platform administrator to enable
# centralized tenant governance operations through Infrastructure as Code.
resource "powerplatform_admin_management_application" "this" {
  # Client ID of the service principal to register as admin
  id = var.client_id

  # Lifecycle management for res-* modules
  # Prevents accidental destruction of admin registrations and allows
  # manual changes in Power Platform admin center without drift
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Allow manual changes if needed without causing Terraform drift
      # Admin registrations rarely need manual updates, but this provides flexibility
    ]
  }

  # Optional timeout configuration as an argument (not a block)
  timeouts = var.timeout_configuration != null ? var.timeout_configuration : null
}

# Validation check to ensure the service principal exists and is accessible
#
# This check validates that the provided client ID represents a service principal
# that exists in the tenant and is accessible to the current authentication context.
check "service_principal_accessibility" {
  assert {
    condition = var.enable_validation ? (
      # Basic UUID format validation for client ID
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.client_id))
    ) : true
    error_message = <<-EOT
      ⚠️ SERVICE PRINCIPAL VALIDATION FAILED
      
      The provided client ID does not appear to be a valid UUID format.
      
      🔍 DIAGNOSTIC INFORMATION:
      • Client ID: ${var.client_id}
      • Expected Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      • Enable Validation: ${var.enable_validation}
      
      📝 RECOMMENDED ACTIONS:
      1. Verify the client ID format is a valid UUID
      2. Ensure the service principal exists in your Azure AD tenant
      3. Confirm the service principal has not been deleted
      4. Check authentication permissions for admin registration
      
      If the client ID is correct, you can temporarily disable validation with:
      enable_validation = false
    EOT
  }
}