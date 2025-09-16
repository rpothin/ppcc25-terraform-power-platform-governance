# Input Variables for Power Platform Azure VNet Extension Pattern Configuration
#
# WHY: Pattern modules require carefully validated input parameters to ensure
# safe orchestration across multiple Azure subscriptions and Power Platform environments
# 
# CONTEXT: This pattern integrates with ptn-environment-group to apply VNet injection
# policies, requiring precise configuration to avoid deployment conflicts
# 
# IMPACT: Variables here determine Azure resource placement, network segmentation,
# and enterprise policy application across production and non-production environments

variable "workspace_name" {
  type        = string
  description = <<DESCRIPTION
Workspace name to match with paired ptn-environment-group configuration.

This name must exactly match the workspace name used in the paired
ptn-environment-group deployment to ensure proper remote state reading.
It's used to construct the remote state key path.

Example:
workspace_name = "DemoWorkspace"

Remote state key will be: "ptn-environment-group/DemoWorkspace.tfstate"

Validation Rules:
- Must be 1-50 characters for consistency with environment group
- Cannot be empty or contain only whitespace
- Should match the workspace name from ptn-environment-group exactly
DESCRIPTION

  validation {
    condition     = length(var.workspace_name) >= 1 && length(var.workspace_name) <= 50
    error_message = "Workspace name must be 1-50 characters to match ptn-environment-group constraints. Current length: ${length(var.workspace_name)}."
  }

  validation {
    condition     = length(trimspace(var.workspace_name)) > 0
    error_message = "Workspace name cannot be empty or contain only whitespace. Must match ptn-environment-group workspace name exactly."
  }
}

variable "test_mode" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Enable test mode to use mock data instead of remote state.

When set to true, this pattern will use mock environment data instead of
reading from the actual remote state. This enables comprehensive testing
without requiring backend infrastructure dependencies.

Example:
test_mode = true  # For testing
test_mode = false # For production use (default)

Validation Rules:
- Boolean value only
- Defaults to false for production use
- When true, remote state data source is bypassed
DESCRIPTION
}

variable "production_subscription_id" {
  type        = string
  sensitive   = true
  description = <<DESCRIPTION
Azure subscription ID for production environments.

This subscription will be used to deploy VNet infrastructure for environments
identified as "Production" type from the remote state data. Supports multi-subscription
governance patterns where production and non-production resources are isolated.

Example:
production_subscription_id = "87654321-4321-4321-4321-210987654321"

Validation Rules:
- Must be a valid Azure subscription GUID format
- Must be different from non-production subscription for proper isolation
- Will be used for all environments with type == "Production"
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.production_subscription_id))
    error_message = "Production subscription ID must be a valid Azure subscription GUID (e.g., 87654321-4321-4321-4321-210987654321)."
  }
}

variable "non_production_subscription_id" {
  type        = string
  sensitive   = true
  description = <<DESCRIPTION
Azure subscription ID for non-production environments (Dev, Test, Staging).

This subscription will be used to deploy VNet infrastructure for environments
identified as non-production from the remote state data. Supports multi-subscription
governance patterns where production and non-production resources are isolated.

Example:
non_production_subscription_id = "12345678-1234-1234-1234-123456789012"

Validation Rules:
- Must be a valid Azure subscription GUID format
- Must be different from production subscription for proper isolation
- Will be used for all environments with type != "Production"
DESCRIPTION

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.non_production_subscription_id))
    error_message = "Non-production subscription ID must be a valid Azure subscription GUID (e.g., 12345678-1234-1234-1234-123456789012)."
  }
}

variable "network_configuration" {
  type = object({
    primary = object({
      location                = string
      vnet_address_space_base = string
    })
    failover = object({
      location                = string
      vnet_address_space_base = string
    })
    subnet_allocation = object({
      power_platform_subnet_size   = number
      private_endpoint_subnet_size = number
      power_platform_offset        = number
      private_endpoint_offset      = number
    })
  })
  description = <<DESCRIPTION
Dynamic dual VNet network configuration for Power Platform enterprise policies with per-environment scaling.

WHY: Power Platform network injection enterprise policies require dual VNet architecture
that scales dynamically with environment count while preventing IP conflicts.

CONTEXT: This configuration supports flexible environment deployment (2-N environments)
with automatic per-environment IP range allocation from base address spaces.

Properties:
- primary.location: Azure region for primary VNets
- primary.vnet_address_space_base: Base CIDR for primary region (e.g., 10.100.0.0/12)
- failover.location: Azure region for failover VNets
- failover.vnet_address_space_base: Base CIDR for failover region (e.g., 10.112.0.0/12)
- subnet_allocation: Standardized subnet sizing within each environment's /16

Example:
network_configuration = {
  primary = {
    location                = "Canada Central"
    vnet_address_space_base = "10.100.0.0/12"  # Supports 16 environments
  }
  failover = {
    location                = "Canada East" 
    vnet_address_space_base = "10.112.0.0/12"  # Non-overlapping with primary
  }
  subnet_allocation = {
    power_platform_subnet_size   = 24  # /24 = 256 IPs per environment
    private_endpoint_subnet_size = 24  # /24 = 256 IPs per environment
    power_platform_offset       = 1   # .1.0/24 within each /16
    private_endpoint_offset      = 2   # .2.0/24 within each /16
  }
}

Dynamic Allocation Examples:
- Environment 0: Primary 10.100.0.0/16, Failover 10.112.0.0/16
- Environment 1: Primary 10.101.0.0/16, Failover 10.113.0.0/16  
- Environment 2: Primary 10.102.0.0/16, Failover 10.114.0.0/16

Validation Rules:
- Base address spaces must be /12 to support up to 16 environments
- Primary and failover ranges must not overlap
- Subnet sizes must be 16-30 (valid Azure subnet sizes)
- Offset values must allow subnets within environment /16
DESCRIPTION

  validation {
    condition     = can(cidrhost(var.network_configuration.primary.vnet_address_space_base, 0))
    error_message = "Primary base address space must be valid CIDR notation (e.g., '10.100.0.0/12'). Current: '${var.network_configuration.primary.vnet_address_space_base}'."
  }

  validation {
    condition     = can(cidrhost(var.network_configuration.failover.vnet_address_space_base, 0))
    error_message = "Failover base address space must be valid CIDR notation (e.g., '10.112.0.0/12'). Current: '${var.network_configuration.failover.vnet_address_space_base}'."
  }

  validation {
    condition = (
      tonumber(split("/", var.network_configuration.primary.vnet_address_space_base)[1]) <= 12 &&
      tonumber(split("/", var.network_configuration.failover.vnet_address_space_base)[1]) <= 12
    )
    error_message = "Base address spaces should be /12 or larger to support multiple environments. Primary: '${var.network_configuration.primary.vnet_address_space_base}', Failover: '${var.network_configuration.failover.vnet_address_space_base}'."
  }

  validation {
    condition = (
      var.network_configuration.subnet_allocation.power_platform_subnet_size >= 16 &&
      var.network_configuration.subnet_allocation.power_platform_subnet_size <= 30 &&
      var.network_configuration.subnet_allocation.private_endpoint_subnet_size >= 16 &&
      var.network_configuration.subnet_allocation.private_endpoint_subnet_size <= 30
    )
    error_message = "Subnet sizes must be between 16-30 (Azure valid range). Power Platform: ${var.network_configuration.subnet_allocation.power_platform_subnet_size}, Private Endpoints: ${var.network_configuration.subnet_allocation.private_endpoint_subnet_size}."
  }

  validation {
    condition = (
      var.network_configuration.subnet_allocation.power_platform_offset >= 1 &&
      var.network_configuration.subnet_allocation.private_endpoint_offset >= 1 &&
      var.network_configuration.subnet_allocation.power_platform_offset != var.network_configuration.subnet_allocation.private_endpoint_offset
    )
    error_message = "Subnet offsets must be >= 1 and different from each other. Power Platform: ${var.network_configuration.subnet_allocation.power_platform_offset}, Private Endpoints: ${var.network_configuration.subnet_allocation.private_endpoint_offset}."
  }

  # Note: Complex validation (environment count limits, IP overlap detection) handled in locals.tf
  # This follows terraform-iac guidelines for keeping validation blocks simple with actionable errors
}

# Note: location variable removed - now specified within network_configuration object
# This allows primary and failover VNets to be deployed in different Azure regions

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Tags to be applied to all Azure resources created by this pattern.

These tags will be applied to resource groups, VNets, subnets, and other
Azure resources. Useful for cost tracking, governance, and resource management.

Example:
tags = {
  Environment = "Demo"
  Project     = "PPCC25"
  Owner       = "Platform Team"
  CostCenter  = "IT-001"
}

Default: {} (no additional tags beyond required governance tags)

Validation Rules:
- Tag keys and values cannot be empty
- Follows Azure tagging best practices
- Will be merged with pattern-specific governance tags
DESCRIPTION

  validation {
    condition = alltrue([
      for k, v in var.tags : length(k) > 0 && length(v) > 0
    ])
    error_message = "All tag keys and values must be non-empty strings. Remove any empty tag keys or values."
  }
}