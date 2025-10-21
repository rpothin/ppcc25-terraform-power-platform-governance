# -----------------------------------------------------------------------------
# Power Platform Azure VNet Extension Pattern - Terraform tfvars Template
# -----------------------------------------------------------------------------
# This template is for extending Power Platform environments with Azure VNet integration using IaC.
# It follows security-first, AVM-compliant, and demonstration-quality principles with dynamic
# per-environment IP allocation supporting 2-16 environments with zero-touch scaling.
# See README in this folder for detailed guidance, architecture diagrams, and examples.
#
# Usage:
# 1. Copy this file and rename as needed (e.g., my-vnet-config.tfvars).
# 2. Fill in required values below. Leave commented examples for reference.
# 3. Ensure tfvars filename matches your ptn-environment-group deployment.
# 4. Run `terraform plan -var-file="path/to/your.tfvars"` to validate.
# -----------------------------------------------------------------------------

# REQUIRED: Tfvars filename (without extension) used by paired ptn-environment-group deployment
# This must EXACTLY match the tfvars file name used for ptn-environment-group
# Remote state key will be: "ptn-environment-group-{paired_tfvars_file}.tfstate"
paired_tfvars_file = "my-workspace"

# REQUIRED: Azure subscription ID for production environments (GUID format)
# Production environments will deploy VNet infrastructure to this subscription
# Must be different from non-production subscription for proper isolation
production_subscription_id = "12345678-1234-1234-1234-123456789012"

# REQUIRED: Azure subscription ID for non-production environments (Dev, Test, Staging)
# Non-production environments will deploy VNet infrastructure to this subscription
# Must be different from production subscription for proper isolation
non_production_subscription_id = "12345678-1234-1234-1234-123456789012"

# REQUIRED: Dual VNet network configuration with dynamic per-environment IP allocation
# Base address spaces (/12) automatically subdivide into per-environment VNets (/16)
network_configuration = {
  primary = {
    # Azure region for primary VNets (should align with Power Platform location)
    location = "Canada Central"

    # Base CIDR for primary region - supports up to 16 environments with /16 each
    # Each environment gets unique /16: env0=10.100.0.0/16, env1=10.101.0.0/16, etc.
    vnet_address_space_base = "10.100.0.0/12" # 10.100.0.0 - 10.111.255.255
  }

  failover = {
    # Azure region for failover VNets (different region for disaster recovery)
    location = "Canada East"

    # Base CIDR for failover region - must NOT overlap with primary
    # Each environment gets unique /16: env0=10.112.0.0/16, env1=10.113.0.0/16, etc.
    vnet_address_space_base = "10.112.0.0/12" # 10.112.0.0 - 10.123.255.255
  }

  # Standardized subnet allocation within each environment's /16 block
  subnet_allocation = {
    power_platform_subnet_size   = 24 # /24 = 256 IPs for Power Platform delegation
    private_endpoint_subnet_size = 24 # /24 = 256 IPs for Azure service connectivity
    power_platform_offset        = 1  # Power Platform subnet at .1.0/24 within /16
    private_endpoint_offset      = 2  # Private Endpoint subnet at .2.0/24 within /16
  }
}

# OPTIONAL: Private DNS zones for Azure service connectivity (max 10 zones)
# Add only the zones you need for your specific Azure services
# Common zones:
# - "privatelink.vaultcore.azure.net"      → Azure Key Vault
# - "privatelink.blob.core.windows.net"    → Azure Storage Blob
# - "privatelink.documents.azure.com"      → Azure Cosmos DB
# - "privatelink.database.windows.net"     → Azure SQL Database
# - "privatelink.servicebus.windows.net"   → Azure Service Bus
# private_dns_zones = []

# OPTIONAL: Enable zero-trust networking with NSG security rules (default: true)
# When enabled, creates NSGs with rules that allow intra-VNet and Power Platform traffic
# while blocking internet access following "never trust, always verify" principle
# enable_zero_trust_networking = true

# OPTIONAL: Enable VNet peering between primary and failover regions (default: true)
# Enables hub-spoke architecture with cross-region connectivity for private endpoints
# Simplifies architecture from 4 endpoints to 2, reduces costs and complexity
# enable_vnet_peering = true

# OPTIONAL: Resource tags for cost tracking and governance
# tags = {
#   Environment = "Demo"
#   Project     = "PPCC25"
#   Owner       = "Platform Team"
#   CostCenter  = "IT-001"
# }

# -----------------------------------------------------------------------------
# IP ALLOCATION EXAMPLES
# -----------------------------------------------------------------------------
#
# With base configuration above (10.100.0.0/12 primary, 10.112.0.0/12 failover):
#
# 2 Environments (Simple template - Dev + Prod):
#   - Environment 0 (Dev):  Primary 10.100.0.0/16, Failover 10.112.0.0/16
#   - Environment 1 (Prod): Primary 10.101.0.0/16, Failover 10.113.0.0/16
#
# 3 Environments (Basic template - Dev + Test + Prod):
#   - Environment 0 (Dev):  Primary 10.100.0.0/16, Failover 10.112.0.0/16
#   - Environment 1 (Test): Primary 10.101.0.0/16, Failover 10.113.0.0/16
#   - Environment 2 (Prod): Primary 10.102.0.0/16, Failover 10.114.0.0/16
#
# 4 Environments (Enterprise template - Dev + Staging + Test + Prod):
#   - Environment 0 (Dev):     Primary 10.100.0.0/16, Failover 10.112.0.0/16
#   - Environment 1 (Staging): Primary 10.101.0.0/16, Failover 10.113.0.0/16
#   - Environment 2 (Test):    Primary 10.102.0.0/16, Failover 10.114.0.0/16
#   - Environment 3 (Prod):    Primary 10.103.0.0/16, Failover 10.115.0.0/16
#
# Each environment's /16 contains:
#   - Power Platform subnet: .1.0/24 (256 IPs)
#   - Private Endpoint subnet: .2.0/24 (256 IPs)
#   - Reserved for future use: .3.0-255.0/24
#
# -----------------------------------------------------------------------------
# REGIONAL CONFIGURATION GUIDANCE
# -----------------------------------------------------------------------------
#
# Align Azure regions with Power Platform locations for optimal performance:
#
# Power Platform: canada → Azure: Canada Central + Canada East
#   Primary: "10.100.0.0/12", Failover: "10.112.0.0/12"
#
# Power Platform: unitedstates → Azure: East US + West US 2
#   Primary: "10.96.0.0/12", Failover: "10.112.0.0/12"
#
# Power Platform: europe → Azure: West Europe + North Europe
#   Primary: "10.104.0.0/12", Failover: "10.116.0.0/12"
#
# Power Platform: asia → Azure: Southeast Asia + East Asia
#   Primary: "10.108.0.0/12", Failover: "10.120.0.0/12"
#
# Always ensure primary and failover base address spaces do not overlap!
# -----------------------------------------------------------------------------
