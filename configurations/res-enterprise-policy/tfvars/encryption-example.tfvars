# Encryption Enterprise Policy Configuration Example  
# This example configures an enterprise policy for customer-managed key encryption with Power Platform

# WHY: Encryption policies enable customer-managed keys (CMK) for Power Platform data encryption
# This configuration ensures sensitive Power Platform data is encrypted using keys managed
# by the organization rather than Microsoft-managed keys, providing enhanced security control

policy_configuration = {
  # Policy identification and location
  name              = "ep-powerplatform-cmk-encryption"
  location          = "europe" # Must match Power Platform tenant region
  policy_type       = "Encryption"
  resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-powerplatform-governance"

  # Encryption configuration using Azure Key Vault
  encryption_config = {
    key_vault = {
      # Azure Key Vault containing the customer-managed key
      id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-powerplatform-encryption"

      key = {
        name    = "powerplatform-master-key" # Key must exist in the specified Key Vault
        version = "latest"                   # Use "latest" for automatic key rotation, or specify version for pinning
      }
    }

    state = "Enabled" # "Enabled" to activate encryption, "Disabled" to disable
  }

  # Note: network_injection_config is not used for Encryption policies
}

# Common tags for governance, compliance, and cost management
common_tags = {
  project         = "PPCC25-Governance"
  environment     = "production"
  cost_center     = "IT-Security"
  owner           = "security-team"
  managed_by      = "Terraform"
  compliance      = "Required"
  backup_required = "false" # Enterprise policies are configuration, not data

  # Security and compliance tags
  data_classification = "confidential"
  encryption_required = "true"
  key_management      = "customer-managed"

  # Power Platform specific tags
  pp_region       = "europe"
  policy_type     = "Encryption"
  governance_tier = "enterprise"
}

# Prerequisites for this configuration:
# 1. Azure Key Vault must exist with the specified name and location
# 2. Key Vault must contain the encryption key ("powerplatform-master-key")
# 3. Enterprise policy's managed identity needs Key Vault permissions:
#    - Key Vault Crypto Officer role for key operations
#    - Key Vault Reader role for vault access
# 4. Key Vault must have appropriate access policies or RBAC configured

# Example usage in parent module:
# module "enterprise_policy_encryption" {
#   source = "./configurations/res-enterprise-policy"
#   
#   policy_configuration = var.policy_configuration
#   common_tags         = var.common_tags
# }
#
# # Configure Key Vault access for enterprise policy managed identity
# resource "azurerm_role_assignment" "policy_key_vault_crypto_officer" {
#   scope                = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-powerplatform-encryption"
#   role_definition_name = "Key Vault Crypto Officer"
#   principal_id         = module.enterprise_policy_encryption.managed_identity_principal_id
# }
#
# # Link to Power Platform environments
# resource "powerplatform_enterprise_policy" "encryption" {
#   location             = var.policy_configuration.location
#   enterprise_policy_id = module.enterprise_policy_encryption.enterprise_policy_system_id
# }