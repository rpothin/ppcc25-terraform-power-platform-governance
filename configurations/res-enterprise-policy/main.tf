# Enterprise Policy Resource Configuration
#
# This configuration deploys Microsoft.PowerPlatform/enterprisePolicies using the azapi provider
# following Azure Verified Module (AVM) best practices with Power Platform governance focus.
#
# Key Features:
# - Dual Policy Support: NetworkInjection (VNet integration) and Encryption (customer-managed keys)
# - AVM Child Module: Compatible with meta-arguments (for_each, count, depends_on)
# - System Identity: Automatic managed identity for Azure resource access
# - Lifecycle Protection: Production-ready governance controls
# - Anti-Corruption Outputs: Clean integration interfaces
#
# For production environments:
# - Set prevent_destroy = true in lifecycle blocks
# - Ensure proper RBAC for managed identity (Key Vault, VNet access)
# - Validate enterprise policies before linking to Power Platform environments
# - Monitor policy health status and provisioning state
#
# ⚠️  IMPORTANT NOTES:
# - Uses azapi provider (not azurerm) for Microsoft.PowerPlatform resources
# - Enterprise policy system_id is required for Power Platform environment linking
# - Network injection requires VNet with Microsoft.PowerPlatform/environments delegation
# - Encryption policies require Key Vault with appropriate permissions

# WHY: Use azapi provider for Microsoft.PowerPlatform resources
# The native azurerm provider doesn't support Power Platform enterprise policies
# azapi provides direct access to Azure REST APIs for newer/preview resources
resource "azapi_resource" "enterprise_policy" {
  type      = "Microsoft.PowerPlatform/enterprisePolicies@2020-10-30-preview"
  name      = var.policy_configuration.name
  location  = var.policy_configuration.location
  parent_id = var.policy_configuration.resource_group_id

  body = local.policy_body_configuration

  # WHY: Enterprise policies require system-assigned managed identity
  # This identity is used for accessing Azure resources (Key Vault, VNet)
  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags

  # WHY: Enterprise policies are governance-critical resources
  # Lifecycle management ensures stability while allowing controlled changes
  lifecycle {
    # 🔒 GOVERNANCE POLICY: "Enterprise Policy Protection"
    # 
    # ENFORCEMENT: All configuration changes MUST go through Infrastructure as Code
    # DETECTION: Terraform detects and reports ANY manual changes as drift
    # COMPLIANCE: AVM TFNFR8 compliant lifecycle block positioning
    # PRODUCTION: Set prevent_destroy = true for production environments
    prevent_destroy = false

    # GOVERNANCE: Ignore system-managed properties that change automatically
    ignore_changes = [
      # System health status changes automatically based on policy validation
      body.properties.healthStatus,
      # System ID is generated and managed by Power Platform
      body.properties.systemId,
      # Creation and modification timestamps are system-managed
      body.properties.createdTime,
      body.properties.lastModifiedTime,
    ]
  }

  # WHY: Ensure proper timing for resource creation and dependency management
  timeouts {
    create = "30m" # Enterprise policy creation can take time for validation
    read   = "5m"  # Read operations are typically fast
    update = "30m" # Updates may require revalidation of configurations
    delete = "20m" # Deletion includes cleanup of linked resources
  }
}