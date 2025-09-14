# Enterprise Policy Variables Configuration
#
# This file defines strongly-typed input variables for enterprise policy deployment
# following AVM standards with comprehensive validation and HEREDOC descriptions.
#
# Variable Design Principles:
# - Strong Typing: Explicit object types with property-level validation
# - Comprehensive Validation: Actionable error messages with guidance
# - Security-First: Validation for Azure resource naming and compliance
# - Type-Specific Configuration: Conditional validation based on policy type
# - Production-Ready: Enterprise-grade validation rules and constraints
#
# Policy Types Supported:
# - NetworkInjection: Azure VNet integration for Power Platform environments
# - Encryption: Customer-managed key encryption using Azure Key Vault
#
# Validation Features:
# - Policy name format and length validation
# - Power Platform region validation
# - Type-specific configuration requirements
# - Azure tagging compliance validation

variable "policy_configuration" {
  description = <<DESCRIPTION
Enterprise policy configuration for Power Platform governance.

This consolidated object defines all aspects of enterprise policy deployment
including policy type, location, and type-specific settings.

Policy Types:
- NetworkInjection: Configures VNet integration for Power Platform environments
- Encryption: Configures customer-managed keys for data encryption

Example - Network Injection:
policy_configuration = {
  name          = "ep-vnet-integration-policy"  
  location      = "europe"
  policy_type   = "NetworkInjection"
  resource_group_id = "/subscriptions/.../resourceGroups/rg-governance"
  
  network_injection_config = {
    virtual_networks = [{
      id = "/subscriptions/.../virtualNetworks/vnet-powerplatform"
      subnet = { name = "snet-powerplatform" }
    }]
  }
}

Example - Encryption:
policy_configuration = {
  name          = "ep-encryption-policy"
  location      = "europe"  
  policy_type   = "Encryption"
  resource_group_id = "/subscriptions/.../resourceGroups/rg-governance"
  
  encryption_config = {
    key_vault = {
      id = "/subscriptions/.../vaults/kv-powerplatform"
      key = {
        name = "powerplatform-key"
        version = "latest"
      }
    }
    state = "Enabled"
  }
}
DESCRIPTION

  type = object({
    name              = string
    location          = string
    policy_type       = string
    resource_group_id = string

    # Network injection configuration (required when policy_type = "NetworkInjection")
    network_injection_config = optional(object({
      virtual_networks = list(object({
        id = string
        subnet = object({
          name = string
        })
      }))
    }))

    # Encryption configuration (required when policy_type = "Encryption")  
    encryption_config = optional(object({
      key_vault = object({
        id = string
        key = object({
          name    = string
          version = string
        })
      })
      state = string
    }))
  })

  validation {
    condition     = contains(["NetworkInjection", "Encryption"], var.policy_configuration.policy_type)
    error_message = "Policy type must be either 'NetworkInjection' or 'Encryption'. Choose 'NetworkInjection' for VNet integration or 'Encryption' for customer-managed keys."
  }

  validation {
    condition     = var.policy_configuration.policy_type == "NetworkInjection" ? var.policy_configuration.network_injection_config != null : true
    error_message = "Network injection configuration is required when policy_type is 'NetworkInjection'. Include network_injection_config with virtual_networks array."
  }

  validation {
    condition     = var.policy_configuration.policy_type == "Encryption" ? var.policy_configuration.encryption_config != null : true
    error_message = "Encryption configuration is required when policy_type is 'Encryption'. Include encryption_config with key_vault settings."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.policy_configuration.name))
    error_message = "Policy name must be alphanumeric with hyphens, starting and ending with alphanumeric characters. Example: 'ep-vnet-policy'."
  }

  validation {
    condition     = length(var.policy_configuration.name) >= 3 && length(var.policy_configuration.name) <= 64
    error_message = "Policy name must be between 3 and 64 characters long for Azure resource naming compliance."
  }

  validation {
    condition     = contains(["europe", "unitedstates", "asia", "australia", "india", "japan", "canada", "southamerica", "uk", "france", "germany", "switzerland", "korea", "norway", "uae", "southafrica"], var.policy_configuration.location)
    error_message = "Location must be a valid Power Platform region. Valid regions: europe, unitedstates, asia, australia, india, japan, canada, southamerica, uk, france, germany, switzerland, korea, norway, uae, southafrica."
  }
}

variable "common_tags" {
  description = <<DESCRIPTION
Common tags to apply to the enterprise policy resource for governance and cost management.

These tags are applied at the Azure resource level and help with:
- Cost allocation and tracking across projects
- Resource organization and governance
- Compliance and audit requirements

Example:
common_tags = {
  project     = "PPCC25-Governance"
  environment = "production"
  cost_center = "IT-Infrastructure"
  owner       = "powerplatform-team"
  managed_by  = "Terraform"
}

Tag Requirements:
- Keys and values must be alphanumeric with allowed special characters
- Maximum 50 tag pairs per resource (Azure limitation)
- Key length: 1-512 characters, Value length: 0-256 characters
DESCRIPTION

  type = map(string)
  default = {
    project    = "PPCC25-Governance"
    managed_by = "Terraform"
  }

  validation {
    condition = alltrue([
      for k, v in var.common_tags : can(regex("^[a-zA-Z0-9_.-]*$", k)) && can(regex("^[a-zA-Z0-9_. -]*$", v))
    ])
    error_message = "Tag keys and values must contain only alphanumeric characters, periods, hyphens, underscores, and spaces. Special characters like @, #, $ are not allowed."
  }

  validation {
    condition = alltrue([
      for k, v in var.common_tags : length(k) >= 1 && length(k) <= 512
    ])
    error_message = "Tag keys must be between 1 and 512 characters long per Azure requirements."
  }

  validation {
    condition = alltrue([
      for k, v in var.common_tags : length(v) <= 256
    ])
    error_message = "Tag values must be 256 characters or less per Azure requirements."
  }

  validation {
    condition     = length(var.common_tags) <= 50
    error_message = "Maximum of 50 tags allowed per Azure resource. Consider consolidating tags or using fewer key-value pairs."
  }
}