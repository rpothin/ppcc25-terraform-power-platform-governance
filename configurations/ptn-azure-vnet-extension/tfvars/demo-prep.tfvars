# Azure VNet Extension Regional Examples Configuration
#
# This file pairs with the ptn-environment-group/tfvars/demo-prep.tfvars
# to demonstrate VNet integration across different environments and regions.
# Must use the same tfvars file name as the paired environment group configuration.

# ==========================================================================
# MINIMAL CONFIGURATION - Required Variables Only
# ==========================================================================

# For users who want to start simple, uncomment this section and comment out
# the detailed configuration below. These are the only required variables:

# workspace_name = "DemoWorkspace"
# production_subscription_id = "YOUR-PRODUCTION-SUBSCRIPTION-ID-HERE"
# non_production_subscription_id = "YOUR-NON-PRODUCTION-SUBSCRIPTION-ID-HERE"
# network_configuration = {
#   primary = {
#     location = "East US"
#     vnet_address_space_base = "10.96.0.0/12"
#   }
#   failover = {
#     location = "West US 2"  
#     vnet_address_space_base = "10.112.0.0/12"
#   }
#   subnet_allocation = {
#     power_platform_subnet_size = 24
#     private_endpoint_subnet_size = 24
#     power_platform_offset = 1
#     private_endpoint_offset = 2
#   }
# }

# ==========================================================================
# DETAILED CONFIGURATION - With Documentation and Examples
# ==========================================================================

# ==========================================================================
# PAIRED CONFIGURATION - Must Match Environment Group tfvars File
# ==========================================================================

# WHY: This paired_tfvars_file must exactly match the tfvars file name used for ptn-environment-group deployment
# CONTEXT: Remote state reading depends on consistent tfvars file naming between paired patterns
# IMPACT: Pattern will read remote state from ptn-environment-group-{paired_tfvars_file}.tfstate
paired_tfvars_file = "demo-prep"

# ==========================================================================
# SUBSCRIPTION CONFIGURATION - Multi-Subscription Governance  
# ==========================================================================

# Production subscription for production environments
# Replace with your actual production subscription ID
# Example format: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
production_subscription_id = "7d237ead-2d0d-4dda-b0d7-2a3ecf235a1c"

# Non-production subscription for dev, test, staging environments  
# Replace with your actual non-production subscription ID
# Example format: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
non_production_subscription_id = "7d237ead-2d0d-4dda-b0d7-2a3ecf235a1c"

# ==========================================================================
# DUAL VNET NETWORK CONFIGURATION - Dynamic Per-Environment Allocation
# ==========================================================================

# WHY: Power Platform enterprise policies require per-environment VNets with unique IP ranges
# CONTEXT: Each environment gets dedicated VNets in both regions with non-overlapping IP allocation
# IMPACT: Supports flexible environment count (2-N environments) with automatic IP range assignment

network_configuration = {
  primary = {
    location = "Canada Central"
    # WHY: Large address space allows automatic per-environment subnet allocation
    # CONTEXT: /12 provides 1,048,576 IPs for multiple environment subnetting
    # IMPACT: Supports up to 16 environments with /16 blocks each (65K IPs per env)
    vnet_address_space_base = "10.100.0.0/12" # 10.100.0.0 - 10.111.255.255

    # WHY: Environment-specific IP allocation will be calculated dynamically
    # CONTEXT: Each environment gets unique /16 from the base range
    # IMPACT: dev=10.100.0.0/16, test=10.101.0.0/16, prod=10.102.0.0/16, etc.
  }
  failover = {
    location = "Canada East"
    # WHY: Non-overlapping address space for failover region
    # CONTEXT: /12 provides same capacity in different IP range
    # IMPACT: Supports same environment count with no IP conflicts
    vnet_address_space_base = "10.112.0.0/12" # 10.112.0.0 - 10.127.255.255
  }

  # WHY: Standardized subnet allocation within each environment's /16
  # CONTEXT: Each environment gets consistent subnet layout
  # IMPACT: Power Platform and private endpoints get dedicated subnets
  subnet_allocation = {
    power_platform_subnet_size   = 24 # /24 = 256 IPs per environment
    private_endpoint_subnet_size = 24 # /24 = 256 IPs per environment
    power_platform_offset        = 1  # .1.0/24 within each /16
    private_endpoint_offset      = 2  # .2.0/24 within each /16
  }
}

# ==========================================================================
# PRIVATE DNS ZONES - Azure Service Private Endpoint Connectivity
# ==========================================================================

# WHY: Enable private endpoint DNS resolution for Azure services during demos
# CONTEXT: Private endpoints require corresponding DNS zones for proper name resolution
# IMPACT: Allows testing private connectivity to Azure services without public internet
private_dns_zones = [
  "privatelink.vaultcore.azure.net",   # Azure Key Vault
  "privatelink.blob.core.windows.net", # Azure Storage Blob
  "privatelink.file.core.windows.net", # Azure Storage Files
  "privatelink.documents.azure.com",   # Azure Cosmos DB
  "privatelink.database.windows.net"   # Azure SQL Database
]

# ==========================================================================
# GOVERNANCE TAGGING - Azure Resource Tagging Strategy
# ==========================================================================

tags = {
  Environment = "Demo-Prep"
  Project     = "PPCC25"
  Pattern     = "ptn-azure-vnet-extension"
  Purpose     = "Power Platform VNet Integration Demo Preparation"
}

# ==========================================================================
# DYNAMIC IP ALLOCATION EXAMPLES - How Environments Get Unique Ranges
# ==========================================================================

# WHY: Demonstrate how the pattern calculates per-environment IP ranges
# CONTEXT: Based on environment index and base address space configuration
# IMPACT: Prevents IP conflicts and supports flexible environment scaling

# Example with 3 environments (dev, test, prod):
# Environment 0 (dev):   Primary: 10.100.0.0/16, Failover: 10.112.0.0/16
#   - Power Platform:     Primary: 10.100.1.0/24, Failover: 10.112.1.0/24  
#   - Private Endpoints:  Primary: 10.100.2.0/24, Failover: 10.112.2.0/24
# Environment 1 (test):  Primary: 10.101.0.0/16, Failover: 10.113.0.0/16
#   - Power Platform:     Primary: 10.101.1.0/24, Failover: 10.113.1.0/24
#   - Private Endpoints:  Primary: 10.101.2.0/24, Failover: 10.113.2.0/24
# Environment 2 (prod):  Primary: 10.102.0.0/16, Failover: 10.114.0.0/16
#   - Power Platform:     Primary: 10.102.1.0/24, Failover: 10.114.1.0/24
#   - Private Endpoints:  Primary: 10.102.2.0/24, Failover: 10.114.2.0/24

# Example with 4 environments (dev, test, uat, prod):
# Environment 3 (uat):   Primary: 10.103.0.0/16, Failover: 10.115.0.0/16

# Example with 2 environments (non-prod, prod):
# Environment 0 (non-prod): Primary: 10.100.0.0/16, Failover: 10.112.0.0/16
# Environment 1 (prod):     Primary: 10.101.0.0/16, Failover: 10.113.0.0/16

# Example 1: European Deployment with EU Data Residency
# workspace_name = "EuropeCustomers"  # Must match ptn-environment-group
# network_configuration = {
#   primary = {
#     location                        = "West Europe"
#     vnet_address_space             = "172.16.0.0/16"
#     power_platform_subnet_cidr     = "172.16.1.0/24"
#     private_endpoint_subnet_cidr   = "172.16.2.0/24"
#   }
#   failover = {
#     location                        = "North Europe"
#     vnet_address_space             = "172.17.0.0/16"   # Non-overlapping
#     power_platform_subnet_cidr     = "172.17.1.0/24"
#     private_endpoint_subnet_cidr   = "172.17.2.0/24"
#   }
# }
# tags = {
#   Environment = "Production"
#   Region      = "Europe"
#   Compliance  = "GDPR"
# }

# Example 2: Asia-Pacific Deployment with Regional Resilience
# workspace_name = "APACOperations"  # Must match ptn-environment-group
# network_configuration = {
#   primary = {
#     location                        = "Southeast Asia"
#     vnet_address_space             = "192.168.0.0/16"
#     power_platform_subnet_cidr     = "192.168.1.0/24"
#     private_endpoint_subnet_cidr   = "192.168.2.0/24"
#   }
#   failover = {
#     location                        = "East Asia"
#     vnet_address_space             = "192.169.0.0/16"  # Non-overlapping
#     power_platform_subnet_cidr     = "192.169.1.0/24"
#     private_endpoint_subnet_cidr   = "192.169.2.0/24"
#   }
# }
# tags = {
#   Environment = "Production"
#   Region      = "APAC"
#   Compliance  = "Regional-Data-Residency"
# }

# Example 3: US Multi-Region with East/West Coast Failover
# workspace_name = "USOperations"    # Must match ptn-environment-group
# network_configuration = {
#   primary = {
#     location                        = "East US 2"
#     vnet_address_space             = "10.50.0.0/16"
#     power_platform_subnet_cidr     = "10.50.1.0/24"
#     private_endpoint_subnet_cidr   = "10.50.2.0/24"
#   }
#   failover = {
#     location                        = "West US 2"
#     vnet_address_space             = "10.51.0.0/16"   # Non-overlapping
#     power_platform_subnet_cidr     = "10.51.1.0/24"
#     private_endpoint_subnet_cidr   = "10.51.2.0/24"
#   }
# }

# ==========================================================================
# DEPLOYMENT NOTES
# ==========================================================================

# Prerequisites:
# 1. ptn-environment-group must be deployed with matching workspace_name
# 2. Azure subscriptions must have appropriate permissions for VNet creation
# 3. Power Platform environments should be managed for enterprise policy support
# 4. Terraform backend must be configured (state config is inherited automatically)

# Deployment Commands:
# terraform init
# terraform plan -var-file="tfvars/demo-prep.tfvars"
# terraform apply -var-file="tfvars/demo-prep.tfvars"

# Validation:
# Use terraform-local-validation.sh script to validate configuration before deployment

# Dynamic Remote State Benefits:
# - No hardcoded state storage configuration needed
# - Backend configuration inherited from current Terraform execution context
# - Consistent state location across all pattern deployments