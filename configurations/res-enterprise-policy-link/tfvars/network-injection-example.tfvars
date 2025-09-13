# Network Injection Enterprise Policy Example
#
# This example demonstrates how to assign a NetworkInjection enterprise policy
# to a Power Platform environment for VNet integration capabilities.
#
# Prerequisites:
# - Azure VNet with proper configuration
# - Subnet with Microsoft.PowerPlatform/environments delegation
# - Enterprise policy created in Azure
# - Target Power Platform environment exists
# - Proper RBAC permissions for policy assignment
#
# Usage:
#   terraform plan -var-file="tfvars/network-injection-example.tfvars"
#   terraform apply -var-file="tfvars/network-injection-example.tfvars"

# =============================================================================
# REQUIRED VARIABLES - Network Injection Policy Assignment
# =============================================================================

# Target Power Platform environment for VNet integration
# Replace with your actual environment GUID
environment_id = "12345678-1234-5678-9abc-123456789012"

# Policy type for VNet integration and subnet delegation
policy_type = "NetworkInjection"

# Azure enterprise policy resource identifier
# Format: /regions/<location>/providers/Microsoft.PowerPlatform/enterprisePolicies/<policy-id>
# Replace with your actual NetworkInjection policy system ID
system_id = "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/vnet-policy-12345678-1234-5678-9abc-123456789012"

# =============================================================================
# OPTIONAL CONFIGURATION - Environment Validation
# =============================================================================

# Enable environment validation before policy assignment
# Recommended: true for production, false for automated deployments
validate_environment = true