# Input Variables for Power Platform Enterprise Policy Link (res-enterprise-policy-link)
#
# This file defines all input parameters for the configuration following
# AVM variable standards with comprehensive validation and documentation.
#
# Variable Categories:
# - Policy Assignment: Core enterprise policy assignment parameters
# - Environment Configuration: Target environment settings and validation
# - Lifecycle Management: Resource lifecycle and governance controls
# - Operation Timeouts: Timeout configurations for policy operations
#
# Architecture: Child module pattern for AVM compliance and meta-argument support

# ============================================================================
# POLICY ASSIGNMENT VARIABLES
# ============================================================================

variable "environment_id" {
  type        = string
  description = <<DESCRIPTION
Target Power Platform environment ID for enterprise policy assignment.

This variable specifies which Power Platform environment will have the enterprise
policy applied. The environment must exist and be accessible for policy assignment.

Usage Context:
- Used to bind enterprise policies to specific Power Platform environments
- Must be a valid GUID representing an existing Power Platform environment
- Environment must support the specified policy type (NetworkInjection/Encryption)

Validation Rules:
- Must be a valid GUID format (8-4-4-4-12 hexadecimal pattern)
- Environment must be accessible with current authentication
- For NetworkInjection: Environment should have Dataverse enabled
- For Encryption: Environment must be configured as managed environment

Example Values:
- "12345678-1234-5678-9abc-123456789012" (development environment)
- "abcdef12-3456-789a-bcde-f123456789ab" (production environment)

Security Considerations:
- Environment IDs are not sensitive but should be validated for existence
- Ensure proper RBAC permissions for policy assignment to the target environment
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.environment_id))
    error_message = <<EOT
Environment ID must be a valid GUID format.

Current value: "${var.environment_id}"
Expected format: "12345678-1234-5678-9abc-123456789012"

To find valid environment IDs:
1. Use Power Platform Admin Center: https://admin.powerplatform.microsoft.com/
2. Use PowerShell: Get-AdminPowerAppEnvironment
3. Use Azure CLI: az powerplatform environment list
EOT
  }
}

variable "policy_type" {
  type        = string
  description = <<DESCRIPTION
Type of enterprise policy to assign to the environment.

This variable determines which type of enterprise policy will be applied to the
target environment. Different policy types provide different governance capabilities.

Supported Policy Types:
- NetworkInjection: Enables VNet integration and subnet delegation for the environment
- Encryption: Applies customer-managed key encryption using Azure Key Vault

Usage Context:
- NetworkInjection: Used for environments requiring private connectivity to Azure resources
- Encryption: Used for environments requiring enhanced data protection with CMK
- Policy type must match the capabilities of the target Azure policy resource

Prerequisites by Policy Type:
- NetworkInjection: Requires Azure VNet, subnet with delegation, and proper networking setup
- Encryption: Requires Azure Key Vault, managed environment configuration, and proper permissions

Example Values:
- "NetworkInjection" (for VNet integration scenarios)
- "Encryption" (for customer-managed key scenarios)

Validation Rules:
- Must be exactly "NetworkInjection" or "Encryption" (case-sensitive)
- Policy type must be supported by the Power Platform provider version
DESCRIPTION

  validation {
    condition     = contains(["NetworkInjection", "Encryption"], var.policy_type)
    error_message = <<EOT
Policy type must be either 'NetworkInjection' or 'Encryption'.

Current value: "${var.policy_type}"
Supported values:
- "NetworkInjection" - for VNet integration and subnet delegation
- "Encryption" - for customer-managed key encryption

Choose based on your governance requirements:
- Use NetworkInjection for private connectivity scenarios
- Use Encryption for enhanced data protection requirements
EOT
  }
}

variable "system_id" {
  type        = string
  description = <<DESCRIPTION
Enterprise policy system ID in Azure Resource Manager format.

This variable specifies the Azure resource identifier for the enterprise policy
that will be assigned to the target environment. The system ID must reference
an existing Azure enterprise policy resource.

Format Requirements:
- Must follow ARM resource ID pattern
- Format: /regions/<location>/providers/Microsoft.PowerPlatform/enterprisePolicies/<policy-id>
- Location must match the Power Platform environment's Azure region
- Policy ID must be a valid GUID representing an existing enterprise policy

Usage Context:
- Links Power Platform environment to Azure-based enterprise policy
- Enables governance control through Azure Policy and Azure Resource Manager
- Policy must be pre-created in Azure before assignment

Example Values:
- "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/12345678-1234-5678-9abc-123456789012"
- "/regions/europe/providers/Microsoft.PowerPlatform/enterprisePolicies/abcdef12-3456-789a-bcde-f123456789ab"

Validation Rules:
- Must match the exact ARM resource ID format
- Region must be valid Power Platform region identifier
- Policy ID must be a valid GUID format
- Referenced policy resource must exist in Azure

Security Considerations:
- System IDs are not sensitive but should reference valid, authorized policies
- Ensure proper Azure RBAC permissions for policy resource access
DESCRIPTION

  validation {
    condition     = can(regex("^/regions/[a-zA-Z0-9]+/providers/Microsoft\\.PowerPlatform/enterprisePolicies/[0-9a-fA-F-]+$", var.system_id))
    error_message = <<EOT
System ID must follow the Azure Resource Manager format for enterprise policies.

Current value: "${var.system_id}"
Expected format: "/regions/<location>/providers/Microsoft.PowerPlatform/enterprisePolicies/<policy-id>"

Format breakdown:
- /regions/ - Fixed prefix
- <location> - Power Platform region (e.g., 'unitedstates', 'europe')
- /providers/Microsoft.PowerPlatform/enterprisePolicies/ - Fixed resource provider path
- <policy-id> - GUID of the Azure enterprise policy resource

Example: "/regions/unitedstates/providers/Microsoft.PowerPlatform/enterprisePolicies/12345678-1234-5678-9abc-123456789012"

To find valid system IDs:
1. Check Azure Portal under Enterprise Policies
2. Use Azure PowerShell: Get-AzResource -ResourceType "Microsoft.PowerPlatform/enterprisePolicies"
3. Use Azure CLI: az resource list --resource-type "Microsoft.PowerPlatform/enterprisePolicies"
EOT
  }
}

# ============================================================================
# ENVIRONMENT CONFIGURATION VARIABLES
# ============================================================================

# ============================================================================
# OPERATION TIMEOUT VARIABLES
# ============================================================================

# No additional operation timeout variables needed for this module

# ============================================================================
# VALIDATION VARIABLES
# ============================================================================

# No validation variables needed - validation is handled through:
# 1. Variable validation blocks (input validation)
# 2. Resource lifecycle preconditions (runtime validation)
# 3. Power Platform provider built-in error handling (API validation)