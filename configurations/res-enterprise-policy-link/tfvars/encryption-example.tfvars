# Encryption Enterprise Policy Example
#
# This example demonstrates how to assign an Encryption enterprise policy
# to a Power Platform environment for customer-managed key encryption.
#
# Prerequisites:
# - Azure Key Vault with proper configuration
# - Customer-managed keys configured in Key Vault
# - Enterprise policy created in Azure
# - Target Power Platform environment exists and is managed
# - Proper RBAC permissions for policy assignment and Key Vault access
#
# Usage:
#   terraform plan -var-file="tfvars/encryption-example.tfvars"
#   terraform apply -var-file="tfvars/encryption-example.tfvars"

# =============================================================================
# REQUIRED VARIABLES - Encryption Policy Assignment
# =============================================================================

# Target Power Platform environment for encryption policy
# Must be a managed environment to support encryption policies
# Replace with your actual environment GUID
environment_id = "abcdef12-3456-789a-bcde-f123456789ab"

# Policy type for customer-managed key encryption
policy_type = "Encryption"

# Azure enterprise policy resource identifier for encryption
# Format: /regions/<location>/providers/Microsoft.PowerPlatform/enterprisePolicies/<policy-id>
# Replace with your actual Encryption policy system ID
system_id = "/regions/europe/providers/Microsoft.PowerPlatform/enterprisePolicies/encryption-policy-abcdef12-3456-789a-bcde-f123456789ab"

# =============================================================================
# OPTIONAL CONFIGURATION - Environment Validation
# =============================================================================

# Enable environment validation before policy assignment
# Critical for encryption policies - ensures managed environment
validate_environment = true